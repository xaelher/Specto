"""
core/services.py — бизнес-логика расчётов Specto.

Все денежные суммы вычисляются через Decimal для финансовой точности.
"""
from datetime import date, timedelta
from decimal import ROUND_HALF_UP, Decimal

from django.core.exceptions import PermissionDenied
from django.utils import timezone

from .models import Grade, ObserverLink

# ─────────────────────────────────────────────
# Константы
# ─────────────────────────────────────────────

GRADE_PRICE = Decimal('0.10')   # сомони за 1 балл оценки (Оценка * 0.10)

WEEKDAY_RU = {
    0: 'Понедельник',
    1: 'Вторник',
    2: 'Среда',
    3: 'Четверг',
    4: 'Пятница',
    5: 'Суббота',
    6: 'Воскресенье',
}


def _fmt(d: date) -> str:
    """DD:MM:YYYY"""
    return d.strftime('%d:%m:%Y')


def _student_reg_date(student) -> date:
    """Возвращает локальную дату регистрации ученика."""
    if hasattr(student.created_at, 'date'):
        return timezone.localtime(student.created_at).date()
    return student.created_at


# ─────────────────────────────────────────────
# Получение ученика (с проверкой прав)
# ─────────────────────────────────────────────

def get_target_student(request, student_id=None):
    """
    Возвращает объект ученика в зависимости от роли вызывающего:
    - STUDENT → сам пользователь.
    - OBSERVER → ученик по student_id, только если связь ACCEPTED.
    Raises PermissionDenied при нарушении прав.
    """
    user = request.user
    target_id = student_id or request.query_params.get('student_id')

    if user.role == user.Role.STUDENT:
        return user

    if user.role == user.Role.OBSERVER:
        if not target_id:
            raise PermissionDenied('Укажите student_id.')
        try:
            link = ObserverLink.objects.select_related('student').get(
                observer=user,
                student_id=target_id,
                status=ObserverLink.Status.ACCEPTED,
            )
        except ObserverLink.DoesNotExist:
            raise PermissionDenied('Нет доступа к данному ученику.')
        return link.student

    raise PermissionDenied('Недостаточно прав.')


# ─────────────────────────────────────────────
# Статистика за день
# ─────────────────────────────────────────────

def calculate_day_stats(student, target_date: date) -> dict:
    """
    Полная статистика за один день для заданного ученика.
    """
    is_sunday = (target_date.weekday() == 6)

    # Оценки за день с предметом
    grades_qs = (
        Grade.objects
        .filter(student=student, date=target_date)
        .select_related('subject')
        .order_by('subject__name', 'created_at')
    )
    grades_list = list(grades_qs)
    grades_count = len(grades_list)
    total_score = sum(g.score for g in grades_list)

    # Средняя оценка
    if grades_count:
        avg = Decimal(total_score) / Decimal(grades_count)
        average_score = float(avg.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP))
    else:
        average_score = 0.0

    # Базовый банк: Сумма(Оценка * 0.10)
    base_bank = Decimal(total_score) * GRADE_PRICE

    # Бонус / штраф
    bonus_count   = 0
    penalty_count = 0

    if is_sunday:
        # Воскресенье: штрафа нет, бонус только при >= 4 оценках
        if grades_count >= 4:
            day_bank    = base_bank * Decimal('1.5')
            bonus_count = 1
        else:
            day_bank = base_bank
    else:
        # Учебный день (Пн–Сб)
        if grades_count < 2:
            day_bank      = base_bank * Decimal('0.5')
            penalty_count = 1
        elif grades_count >= 4:
            day_bank    = base_bank * Decimal('1.5')
            bonus_count = 1
        else:
            day_bank = base_bank

    day_bank = float(day_bank.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP))

    # Список оценок для ответа
    grades_data = [
        {
            'grade_id':    g.id,
            'subject_id':  g.subject_id,
            'subject':     g.subject.name,
            'score':       g.score,
            'created_at':  g.created_at.isoformat(),
        }
        for g in grades_list
    ]

    return {
        'date':          _fmt(target_date),
        'iso_date':      target_date.isoformat(),
        'weekday_name':  WEEKDAY_RU[target_date.weekday()],
        'grades_count':  grades_count,
        'average_score': average_score,
        'day_bank':      day_bank,
        'bonus_count':   bonus_count,
        'penalty_count': penalty_count,
        'grades':        grades_data,
    }


# ─────────────────────────────────────────────
# Статистика за неделю
# ─────────────────────────────────────────────

def calculate_week_stats(student, week_offset: int = 0) -> dict:
    """
    Статистика за неделю (Пн–Вс).
    week_offset=0  → текущая неделя
    week_offset=-1 → прошлая неделя
    """
    today         = timezone.localdate()
    start_of_week = today - timedelta(days=today.weekday())  # понедельник текущей недели
    monday = start_of_week + timedelta(weeks=week_offset)
    sunday = monday + timedelta(days=6)

    reg_date = _student_reg_date(student)

    week_bank     = Decimal('0')
    bonus_count   = 0
    penalty_count = 0
    total_grades  = 0
    score_sum     = 0
    days_passed   = 0
    days_data     = []

    for offset in range(7):
        day = monday + timedelta(days=offset)
        if day > today:
            continue
        days_passed += 1

        if day < reg_date:
            continue

        stats = calculate_day_stats(student, day)
        week_bank     += Decimal(str(stats['day_bank']))
        bonus_count   += stats['bonus_count']
        penalty_count += stats['penalty_count']
        total_grades  += stats['grades_count']
        score_sum     += sum(g['score'] for g in stats['grades'])
        days_data.append(stats)

    week_bank = float(week_bank.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP))

    week_average = 0.0
    if total_grades:
        week_average = round(score_sum / total_grades, 2)

    week_range = f'{_fmt(monday)}-{_fmt(sunday)}'

    return {
        'week_range':    week_range,
        'week_offset':   week_offset,
        'days_passed':   days_passed,
        'grades_count':  total_grades,
        'average_score': week_average,
        'week_bank':     week_bank,
        'bonus_count':   bonus_count,
        'penalty_count': penalty_count,
        'days':          days_data,
    }


# ─────────────────────────────────────────────
# Общая история
# ─────────────────────────────────────────────

def calculate_history_overview(student) -> dict:
    """
    Общая статистика с даты регистрации по сегодня.
    """
    today    = timezone.localdate()
    reg_date = _student_reg_date(student)

    if reg_date > today:
        reg_date = today

    total_days_passed = (today - reg_date).days + 1
    study_days_passed = sum(
        1
        for i in range(total_days_passed)
        if (reg_date + timedelta(days=i)).weekday() != 6   # не воскресенье
    )

    all_grades = Grade.objects.filter(student=student, date__gte=reg_date, date__lte=today)
    scores = list(all_grades.values_list('score', flat=True))
    total_grades_count = len(scores)

    if total_grades_count:
        total_average_score = round(sum(scores) / total_grades_count, 2)
    else:
        total_average_score = 0.0

    # Суммарный банк — итерируем по дням
    total_bank = Decimal('0')
    for i in range(total_days_passed):
        day = reg_date + timedelta(days=i)
        stats = calculate_day_stats(student, day)
        total_bank += Decimal(str(stats['day_bank']))

    total_bank = float(total_bank.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP))

    return {
        'reg_date':            reg_date.isoformat(),
        'total_days_passed':   total_days_passed,
        'study_days_passed':   study_days_passed,
        'total_grades_count':  total_grades_count,
        'total_average_score': total_average_score,
        'total_bank':          total_bank,
    }


# ─────────────────────────────────────────────
# Статистика по предмету
# ─────────────────────────────────────────────

def calculate_subject_stats(student, subject) -> dict:
    """
    Статистика по конкретному предмету ученика.
    """
    scores = list(Grade.objects.filter(student=student, subject=subject).values_list('score', flat=True))
    grades_count = len(scores)

    if grades_count == 0:
        return {
            'subject_id':          subject.id,
            'subject_name':        subject.name,
            'grades_count':        0,
            'average_score':       0.0,
            'most_frequent_score': None,
        }

    average_score = round(sum(scores) / grades_count, 2)

    # Мода (самая частая оценка)
    freq = {}
    for s in scores:
        freq[s] = freq.get(s, 0) + 1
    most_frequent_score = max(freq, key=freq.get)

    return {
        'subject_id':          subject.id,
        'subject_name':        subject.name,
        'grades_count':        grades_count,
        'average_score':       average_score,
        'most_frequent_score': most_frequent_score,
    }