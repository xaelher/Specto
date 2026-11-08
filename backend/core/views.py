from django.contrib.auth import authenticate, get_user_model
from django.db.models import Q
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import ObserverLink
from .serializers import (
    ChangePasswordSerializer,
    ObserverLinkSerializer,
    RegisterSerializer,
    StudentBriefSerializer,
    UserProfileSerializer,
)

User = get_user_model()


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

def _tokens_for_user(user):
    """Возвращает пару access/refresh токенов для пользователя."""
    refresh = RefreshToken.for_user(user)
    return {
        'access':  str(refresh.access_token),
        'refresh': str(refresh),
    }


def _user_data(user):
    return UserProfileSerializer(user).data


# ─────────────────────────────────────────────
# Auth
# ─────────────────────────────────────────────

class RegisterView(APIView):
    """POST /api/auth/register/ — регистрация нового пользователя."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            {'user': _user_data(user), **_tokens_for_user(user)},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """POST /api/auth/login/ — аутентификация."""
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username', '').strip()
        password = request.data.get('password', '')

        user = authenticate(request, username=username, password=password)
        if user is None:
            return Response(
                {'detail': 'Неверное имя пользователя или пароль.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        return Response({'user': _user_data(user), **_tokens_for_user(user)})


# ─────────────────────────────────────────────
# Profile
# ─────────────────────────────────────────────

class ProfileView(APIView):
    """GET / PATCH /api/profile/ — просмотр и редактирование своего профиля."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserProfileSerializer(request.user).data)

    def patch(self, request):
        serializer = UserProfileSerializer(
            request.user,
            data=request.data,
            partial=True,
            context={'request': request},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class ChangePasswordView(APIView):
    """POST /api/profile/change-password/ — смена пароля."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'detail': 'Пароль успешно изменён.'})


# ─────────────────────────────────────────────
# Observer endpoints
# ─────────────────────────────────────────────

class IsObserver:
    """Mixin: проверяет, что текущий пользователь — наблюдатель."""

    def _check_observer(self, request):
        if request.user.role != User.Role.OBSERVER:
            return Response(
                {'detail': 'Доступ только для наблюдателей.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return None


class SearchStudentsView(IsObserver, APIView):
    """GET /api/observer/students/search/?q= — поиск учеников."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        err = self._check_observer(request)
        if err:
            return err

        q = request.query_params.get('q', '').strip()

        # Ученики, с которыми уже есть связь
        linked_ids = ObserverLink.objects.filter(
            observer=request.user
        ).values_list('student_id', flat=True)

        qs = User.objects.filter(role=User.Role.STUDENT).exclude(pk__in=linked_ids)
        if q:
            qs = qs.filter(
                Q(first_name__icontains=q)
                | Q(last_name__icontains=q)
                | Q(username__icontains=q)
            )
        return Response(StudentBriefSerializer(qs, many=True).data)


class ObserverStudentsListView(IsObserver, APIView):
    """GET /api/observer/students/ — список учеников этого наблюдателя."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        err = self._check_observer(request)
        if err:
            return err

        links = ObserverLink.objects.filter(
            observer=request.user
        ).select_related('student', 'observer')

        accepted = ObserverLinkSerializer(
            links.filter(status=ObserverLink.Status.ACCEPTED), many=True
        ).data
        pending = ObserverLinkSerializer(
            links.filter(status=ObserverLink.Status.PENDING), many=True
        ).data
        return Response({'accepted': accepted, 'pending': pending})


class SendObserverRequestView(IsObserver, APIView):
    """POST /api/observer/request/<student_id>/ — отправить запрос ученику."""
    permission_classes = [IsAuthenticated]

    def post(self, request, student_id):
        err = self._check_observer(request)
        if err:
            return err

        try:
            student = User.objects.get(pk=student_id, role=User.Role.STUDENT)
        except User.DoesNotExist:
            return Response(
                {'detail': 'Ученик не найден.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        link, created = ObserverLink.objects.get_or_create(
            observer=request.user,
            student=student,
        )
        if not created:
            return Response(
                {'detail': 'Запрос уже существует.'},
                status=status.HTTP_409_CONFLICT,
            )
        return Response(
            ObserverLinkSerializer(link).data,
            status=status.HTTP_201_CREATED,
        )


# ─────────────────────────────────────────────
# Student endpoints
# ─────────────────────────────────────────────

class IsStudent:
    """Mixin: проверяет, что текущий пользователь — ученик."""

    def _check_student(self, request):
        if request.user.role != User.Role.STUDENT:
            return Response(
                {'detail': 'Доступ только для учеников.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return None


class StudentObserversListView(IsStudent, APIView):
    """GET /api/student/observers/ — список наблюдателей этого ученика."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        err = self._check_student(request)
        if err:
            return err

        links = ObserverLink.objects.filter(
            student=request.user
        ).select_related('observer', 'student')

        accepted = ObserverLinkSerializer(
            links.filter(status=ObserverLink.Status.ACCEPTED), many=True
        ).data
        pending = ObserverLinkSerializer(
            links.filter(status=ObserverLink.Status.PENDING), many=True
        ).data
        return Response({'accepted': accepted, 'pending': pending})


class RespondObserverRequestView(IsStudent, APIView):
    """POST /api/student/observers/<link_id>/respond/ — принять или отклонить запрос."""
    permission_classes = [IsAuthenticated]

    def post(self, request, link_id):
        err = self._check_student(request)
        if err:
            return err

        try:
            link = ObserverLink.objects.get(
                pk=link_id,
                student=request.user,
                status=ObserverLink.Status.PENDING,
            )
        except ObserverLink.DoesNotExist:
            return Response(
                {'detail': 'Запрос не найден или уже обработан.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        action = request.data.get('action')
        if action == 'accept':
            link.status = ObserverLink.Status.ACCEPTED
            link.save()
            return Response(ObserverLinkSerializer(link).data)
        elif action == 'reject':
            link.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        else:
            return Response(
                {'detail': 'Укажите action: "accept" или "reject".'},
                status=status.HTTP_400_BAD_REQUEST,
            )


class RemoveObserverView(IsStudent, APIView):
    """DELETE /api/student/observers/<link_id>/ — удалить наблюдателя."""
    permission_classes = [IsAuthenticated]

    def delete(self, request, link_id):
        err = self._check_student(request)
        if err:
            return err

        try:
            link = ObserverLink.objects.get(pk=link_id, student=request.user)
        except ObserverLink.DoesNotExist:
            return Response(
                {'detail': 'Связь не найдена.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        link.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ═════════════════════════════════════════════════════════════════
# Этап 3: Предметы, Оценки, Аналитика
# ═════════════════════════════════════════════════════════════════

import datetime

from django.core.exceptions import PermissionDenied

from .models import Grade, Subject
from .serializers import (
    BulkSubjectCreateSerializer,
    GradeCreateSerializer,
    SubjectSerializer,
)
from .services import (
    calculate_day_stats,
    calculate_history_overview,
    calculate_subject_stats,
    calculate_week_stats,
    get_target_student,
)


def _resolve_student(request):
    """
    Вспомогательная функция: разрешает целевого ученика из параметра ?student_id=.
    Оборачивает PermissionDenied → 403 Response.
    """
    student_id = request.query_params.get('student_id')
    if student_id is not None:
        try:
            student_id = int(student_id)
        except (ValueError, TypeError):
            return None, Response(
                {'detail': 'Некорректный student_id.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
    try:
        student = get_target_student(request, student_id)
    except PermissionDenied as exc:
        return None, Response({'detail': str(exc)}, status=status.HTTP_403_FORBIDDEN)
    return student, None


# ─────────────────────────────────────────────
# Subjects
# ─────────────────────────────────────────────

class SubjectListView(APIView):
    """GET /api/subjects/ — список активных предметов."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        student, err = _resolve_student(request)
        if err:
            return err
        subjects = Subject.objects.filter(student=student, is_deleted=False)
        return Response(SubjectSerializer(subjects, many=True).data)


class SubjectCreateView(IsStudent, APIView):
    """POST /api/subjects/create/ — добавить один или несколько предметов (только ученик)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        err = self._check_student(request)
        if err:
            return err

        serializer = BulkSubjectCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        names = serializer.validated_data['_names']

        created = []
        for name in names:
            subj = Subject.objects.create(student=request.user, name=name)
            created.append(SubjectSerializer(subj).data)

        return Response(created, status=status.HTTP_201_CREATED)


class SubjectDeleteView(IsStudent, APIView):
    """DELETE /api/subjects/<subject_id>/ — мягкое удаление предмета (только ученик)."""
    permission_classes = [IsAuthenticated]

    def delete(self, request, subject_id):
        err = self._check_student(request)
        if err:
            return err

        try:
            subject = Subject.objects.get(pk=subject_id, student=request.user)
        except Subject.DoesNotExist:
            return Response({'detail': 'Предмет не найден.'}, status=status.HTTP_404_NOT_FOUND)

        if subject.is_deleted:
            return Response({'detail': 'Предмет уже удалён.'}, status=status.HTTP_409_CONFLICT)

        subject.is_deleted = True
        subject.save(update_fields=['is_deleted'])
        return Response(status=status.HTTP_204_NO_CONTENT)


# ─────────────────────────────────────────────
# Grades
# ─────────────────────────────────────────────

class GradeCreateView(IsStudent, APIView):
    """POST /api/grades/create/ — добавить оценку за сегодня (только ученик)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        err = self._check_student(request)
        if err:
            return err

        serializer = GradeCreateSerializer(
            data=request.data, context={'student': request.user}
        )
        serializer.is_valid(raise_exception=True)
        grade = serializer.save()

        return Response(
            {
                'id':         grade.id,
                'subject_id': grade.subject_id,
                'subject':    grade.subject.name,
                'score':      grade.score,
                'date':       grade.date.isoformat(),
            },
            status=status.HTTP_201_CREATED,
        )


# ─────────────────────────────────────────────
# Stats
# ─────────────────────────────────────────────

class StatsTodayView(APIView):
    """GET /api/stats/today/ — статистика за сегодня + bank за неделю."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        student, err = _resolve_student(request)
        if err:
            return err

        today      = datetime.date.today()
        day_stats  = calculate_day_stats(student, today)
        week_stats = calculate_week_stats(student, week_offset=0)

        return Response({
            **day_stats,
            'week_bank': week_stats['week_bank'],
        })


class StatsWeekView(APIView):
    """GET /api/stats/week/?offset=0 — статистика за неделю."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        student, err = _resolve_student(request)
        if err:
            return err

        try:
            offset = int(request.query_params.get('offset', 0))
        except (ValueError, TypeError):
            return Response({'detail': 'offset должен быть целым числом.'}, status=status.HTTP_400_BAD_REQUEST)

        return Response(calculate_week_stats(student, week_offset=offset))


class StatsHistoryView(APIView):
    """GET /api/stats/history/ — общая история."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        student, err = _resolve_student(request)
        if err:
            return err
        return Response(calculate_history_overview(student))


class StatsDayView(APIView):
    """GET /api/stats/day/?date=YYYY-MM-DD — статистика за конкретный день."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        student, err = _resolve_student(request)
        if err:
            return err

        raw_date = request.query_params.get('date')
        if not raw_date:
            return Response({'detail': 'Укажите параметр date=YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            target_date = datetime.date.fromisoformat(raw_date)
        except ValueError:
            return Response({'detail': 'Неверный формат даты. Используйте YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)

        return Response(calculate_day_stats(student, target_date))


class StatsSubjectView(APIView):
    """GET /api/stats/subject/<subject_id>/ — статистика по предмету."""
    permission_classes = [IsAuthenticated]

    def get(self, request, subject_id):
        student, err = _resolve_student(request)
        if err:
            return err

        try:
            subject = Subject.objects.get(pk=subject_id, student=student)
        except Subject.DoesNotExist:
            return Response({'detail': 'Предмет не найден.'}, status=status.HTTP_404_NOT_FOUND)

        stats = calculate_subject_stats(student, subject)
        return Response({
            'subject': SubjectSerializer(subject).data,
            **stats,
        })
