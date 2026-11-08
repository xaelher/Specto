from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import ObserverLink

User = get_user_model()


# ─────────────────────────────────────────────
# Brief serializers (used as nested fields)
# ─────────────────────────────────────────────

class StudentBriefSerializer(serializers.ModelSerializer):
    class Meta:
        model  = User
        fields = ('id', 'username', 'first_name', 'last_name', 'school_grade')


class ObserverBriefSerializer(serializers.ModelSerializer):
    class Meta:
        model  = User
        fields = ('id', 'username', 'first_name', 'last_name')


# ─────────────────────────────────────────────
# ObserverLink
# ─────────────────────────────────────────────

class ObserverLinkSerializer(serializers.ModelSerializer):
    observer = ObserverBriefSerializer(read_only=True)
    student  = StudentBriefSerializer(read_only=True)

    class Meta:
        model  = ObserverLink
        fields = ('id', 'observer', 'student', 'status', 'created_at')


# ─────────────────────────────────────────────
# Profile
# ─────────────────────────────────────────────

class UserProfileSerializer(serializers.ModelSerializer):
    """Просмотр и обновление своего профиля."""

    role       = serializers.CharField(read_only=True)
    created_at = serializers.DateTimeField(read_only=True)

    class Meta:
        model  = User
        fields = ('id', 'username', 'first_name', 'last_name', 'role',
                  'school_grade', 'created_at')

    def validate_username(self, value):
        request = self.context.get('request')
        qs = User.objects.filter(username=value)
        if request and request.user.is_authenticated:
            qs = qs.exclude(pk=request.user.pk)
        if qs.exists():
            raise serializers.ValidationError('Пользователь с таким именем уже существует.')
        return value

    def validate(self, attrs):
        # Наблюдателям school_grade не нужен — очищаем
        role = (self.instance.role if self.instance else None)
        if role == User.Role.OBSERVER:
            attrs['school_grade'] = ''
        return attrs


# ─────────────────────────────────────────────
# Registration
# ─────────────────────────────────────────────

class RegisterSerializer(serializers.Serializer):
    username         = serializers.CharField(max_length=150)
    first_name       = serializers.CharField(max_length=150)
    last_name        = serializers.CharField(max_length=150)
    role             = serializers.ChoiceField(
        choices=[User.Role.STUDENT, User.Role.OBSERVER],
        error_messages={
            'invalid_choice': 'При регистрации можно выбрать только роль Ученика или Наблюдателя.'
        },
    )
    school_grade     = serializers.CharField(
        max_length=50,
        required=False,
        allow_blank=True,
        allow_null=True,
        default='',
    )
    password         = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)

    def validate_role(self, value):
        if value not in [User.Role.STUDENT, User.Role.OBSERVER]:
            raise serializers.ValidationError(
                'При регистрации можно выбрать только роль Ученика или Наблюдателя.'
            )
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('Пользователь с таким именем уже существует.')
        return value

    def validate(self, attrs):
        if attrs.get('school_grade') is None:
            attrs['school_grade'] = ''
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Пароли не совпадают.'})
        if attrs['role'] == User.Role.STUDENT and not attrs.get('school_grade'):
            raise serializers.ValidationError(
                {'school_grade': 'Для ученика необходимо указать класс.'}
            )
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


# ─────────────────────────────────────────────
# Change password
# ─────────────────────────────────────────────

class ChangePasswordSerializer(serializers.Serializer):
    old_password         = serializers.CharField(write_only=True)
    new_password         = serializers.CharField(write_only=True, min_length=8)
    new_password_confirm = serializers.CharField(write_only=True)

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Текущий пароль указан неверно.')
        return value

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError(
                {'new_password_confirm': 'Новые пароли не совпадают.'}
            )
        return attrs

    def save(self, **kwargs):
        user = self.context['request'].user
        user.set_password(self.validated_data['new_password'])
        user.save()
        return user


# ─────────────────────────────────────────────
# Subjects & Grades
# ─────────────────────────────────────────────

from .models import Grade, Subject  # noqa: E402 (local import at bottom to avoid circular)


class SubjectSerializer(serializers.ModelSerializer):
    """Предмет ученика."""

    class Meta:
        model  = Subject
        fields = ('id', 'name', 'created_at')


class BulkSubjectCreateSerializer(serializers.Serializer):
    """
    Добавление одного или нескольких предметов.
    Принимает либо `name` (строка), либо `names` (массив строк).
    """
    name  = serializers.CharField(max_length=255, required=False)
    names = serializers.ListField(
        child=serializers.CharField(max_length=255),
        required=False,
    )

    def validate(self, attrs):
        name  = attrs.get('name', '').strip()
        names = [n.strip() for n in attrs.get('names', []) if n.strip()]

        if name:
            names.append(name)

        if not names:
            raise serializers.ValidationError(
                'Укажите поле name (строка) или names (список строк).'
            )
        attrs['_names'] = names
        return attrs


class GradeCreateSerializer(serializers.Serializer):
    """Добавление оценки за сегодня."""
    subject_id = serializers.IntegerField()
    score      = serializers.IntegerField(min_value=1, max_value=10)

    def validate_subject_id(self, value):
        student = self.context['student']
        try:
            subj = Subject.objects.get(pk=value, student=student, is_deleted=False)
        except Subject.DoesNotExist:
            raise serializers.ValidationError(
                'Предмет не найден или принадлежит другому ученику.'
            )
        self._subject = subj
        return value

    def create(self, validated_data):
        from django.utils import timezone
        return Grade.objects.create(
            student=self.context['student'],
            subject=self._subject,
            score=validated_data['score'],
            date=timezone.localdate(),
        )
