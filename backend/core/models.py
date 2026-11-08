from django.contrib.auth.models import AbstractUser, UserManager
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import models
from django.utils import timezone


class CustomUserManager(UserManager):
    """
    Кастомный менеджер пользователей Specto.
    При создании суперпользователя автоматически назначает роль SUPERADMIN.
    """

    def create_superuser(self, username, email=None, password=None, **extra_fields):
        extra_fields['role'] = User.Role.SUPERADMIN
        extra_fields['is_staff'] = True
        extra_fields['is_superuser'] = True
        return super().create_superuser(username, email, password, **extra_fields)


class User(AbstractUser):
    """
    Расширенная модель пользователя Specto.
    role = STUDENT    — ученик, который ведёт дневник оценок.
    role = OBSERVER   — родитель/учитель, который наблюдает за учеником.
    role = ADMIN      — администратор с ограниченными правами.
    role = SUPERADMIN — единственный главный супер-администратор.
    """

    class Role(models.TextChoices):
        STUDENT    = 'STUDENT',    'Ученик'
        OBSERVER   = 'OBSERVER',   'Наблюдатель'
        ADMIN      = 'ADMIN',      'Админ'
        SUPERADMIN = 'SUPERADMIN', 'Супер-админ'

    # AbstractUser уже содержит first_name и last_name, переопределяем
    # чтобы сделать обязательными (blank=False по умолчанию — достаточно).
    first_name = models.CharField('Имя',     max_length=150)
    last_name  = models.CharField('Фамилия', max_length=150)

    role = models.CharField(
        'Роль',
        max_length=15,
        choices=Role.choices,
        default=Role.STUDENT,
    )

    school_grade = models.CharField(
        'Класс/Параллель',
        max_length=50,
        blank=True,
        help_text='Заполняется только для учеников, например: "10A"',
    )

    created_at = models.DateTimeField('Дата регистрации', auto_now_add=True)

    objects = CustomUserManager()

    class Meta:
        verbose_name        = 'Пользователь'
        verbose_name_plural = 'Пользователи'

    def __str__(self):
        return f'{self.get_full_name()} ({self.role})'

    def save(self, *args, **kwargs):
        if self.role == self.Role.SUPERADMIN:
            existing = User.objects.filter(role=self.Role.SUPERADMIN)
            if self.pk:
                existing = existing.exclude(pk=self.pk)
            if existing.exists():
                raise ValidationError('В системе может быть только один Супер-админ.')
            self.is_superuser = True
            self.is_staff = True
        elif self.role == self.Role.ADMIN:
            self.is_staff = True
            self.is_superuser = False
        elif self.role in [self.Role.STUDENT, self.Role.OBSERVER]:
            self.is_staff = False
            self.is_superuser = False

        super().save(*args, **kwargs)


class Subject(models.Model):
    """
    Учебный предмет, привязанный к конкретному ученику.
    Используем мягкое удаление (is_deleted=True) вместо реального DELETE,
    чтобы история оценок не терялась.
    """

    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='subjects',
        limit_choices_to={'role': User.Role.STUDENT},
        verbose_name='Ученик',
    )
    name = models.CharField('Название предмета', max_length=255)
    is_deleted = models.BooleanField(
        'Удалён',
        default=False,
        help_text='Мягкое удаление — история оценок сохраняется',
    )
    created_at = models.DateTimeField('Создан', auto_now_add=True)

    class Meta:
        verbose_name        = 'Предмет'
        verbose_name_plural = 'Предметы'
        ordering            = ['name']

    def __str__(self):
        return f'{self.name} — {self.student.get_full_name()}'


class Grade(models.Model):
    """
    Оценка ученика по конкретному предмету.
    score: целое число от 1 до 10.
    """

    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='grades',
        limit_choices_to={'role': User.Role.STUDENT},
        verbose_name='Ученик',
    )
    subject = models.ForeignKey(
        Subject,
        on_delete=models.CASCADE,
        related_name='grades',
        verbose_name='Предмет',
    )
    score = models.PositiveSmallIntegerField(
        'Оценка',
        validators=[
            MinValueValidator(1,  message='Оценка не может быть меньше 1'),
            MaxValueValidator(10, message='Оценка не может быть больше 10'),
        ],
    )
    date = models.DateField(
        'Дата',
        default=timezone.localdate,
        db_index = True
    )
    created_at = models.DateTimeField('Создана', auto_now_add=True)

    class Meta:
        verbose_name        = 'Оценка'
        verbose_name_plural = 'Оценки'
        ordering            = ['-date', '-created_at']

    def __str__(self):
        return f'{self.score} по «{self.subject.name}» ({self.date})'


class ObserverLink(models.Model):
    """
    Связь между наблюдателем и учеником.
    Наблюдатель инициирует запрос — статус PENDING.
    Ученик принимает — статус ACCEPTED.
    Уникальная пара (observer, student) исключает дублирование.
    """

    class Status(models.TextChoices):
        PENDING  = 'PENDING',  'Ожидает подтверждения'
        ACCEPTED = 'ACCEPTED', 'Принят'

    observer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='observing',
        limit_choices_to={'role': User.Role.OBSERVER},
        verbose_name='Наблюдатель',
    )
    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='observers',
        limit_choices_to={'role': User.Role.STUDENT},
        verbose_name='Ученик',
    )
    status = models.CharField(
        'Статус',
        max_length=8,
        choices=Status.choices,
        default=Status.PENDING,
    )
    created_at = models.DateTimeField('Создан', auto_now_add=True)

    class Meta:
        verbose_name        = 'Связь наблюдатель–ученик'
        verbose_name_plural = 'Связи наблюдатель–ученик'
        unique_together     = ('observer', 'student')   # нельзя добавить одну пару дважды

    def __str__(self):
        return (
            f'{self.observer.get_full_name()} наблюдает за '
            f'{self.student.get_full_name()} [{self.status}]'
        )
