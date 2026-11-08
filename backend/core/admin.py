from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.core.exceptions import PermissionDenied

from .models import Grade, ObserverLink, Subject, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Панель управления пользователями с удобным сбросом пароля и данными Specto."""

    list_display = (
        'id',
        'username',
        'first_name',
        'last_name',
        'role',
        'school_grade',
        'is_staff',
        'created_at',
    )
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active')
    search_fields = ('username', 'first_name', 'last_name', 'school_grade')
    ordering = ('-created_at',)
    readonly_fields = ('created_at',)

    fieldsets = BaseUserAdmin.fieldsets + (
        ('Данные Specto', {'fields': ('role', 'school_grade', 'created_at')}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        (
            'Данные Specto',
            {'fields': ('first_name', 'last_name', 'role', 'school_grade')},
        ),
    )

    def has_change_permission(self, request, obj=None):
        if obj is not None and getattr(obj, 'role', None) == User.Role.SUPERADMIN:
            return getattr(request.user, 'role', None) == User.Role.SUPERADMIN
        return super().has_change_permission(request, obj)

    def has_delete_permission(self, request, obj=None):
        if obj is not None and getattr(obj, 'role', None) == User.Role.SUPERADMIN:
            return False
        return super().has_delete_permission(request, obj)

    def get_fieldsets(self, request, obj=None):
        fieldsets = super().get_fieldsets(request, obj)
        if getattr(request.user, 'role', None) != User.Role.SUPERADMIN:
            new_fieldsets = []
            for name, field_options in fieldsets:
                fields = list(field_options.get('fields', ()))
                # Обычный ADMIN не видит is_superuser, groups, user_permissions
                fields = [
                    f
                    for f in fields
                    if f not in ('is_superuser', 'groups', 'user_permissions')
                ]
                new_fieldsets.append(
                    (name, {**field_options, 'fields': tuple(fields)})
                )
            return tuple(new_fieldsets)
        return fieldsets

    def formfield_for_choice_field(self, db_field, request, **kwargs):
        if db_field.name == 'role':
            if getattr(request.user, 'role', None) != User.Role.SUPERADMIN:
                kwargs['choices'] = [
                    (User.Role.STUDENT, 'Ученик'),
                    (User.Role.OBSERVER, 'Наблюдатель'),
                ]
        return super().formfield_for_choice_field(db_field, request, **kwargs)

    def save_model(self, request, obj, form, change):
        if getattr(request.user, 'role', None) != User.Role.SUPERADMIN:
            if obj.role in [User.Role.ADMIN, User.Role.SUPERADMIN]:
                raise PermissionDenied(
                    'Вы не можете назначить роль администратора.'
                )
        super().save_model(request, obj, form, change)


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'student', 'is_deleted', 'created_at')
    list_filter = ('is_deleted',)
    search_fields = (
        'name',
        'student__username',
        'student__first_name',
        'student__last_name',
    )
    ordering = ('name',)
    raw_id_fields = ('student',)


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    list_display = ('id', 'student', 'subject', 'score', 'date', 'created_at')
    list_filter = ('score', 'date')
    search_fields = (
        'student__username',
        'student__first_name',
        'subject__name',
    )
    ordering = ('-date', '-created_at')
    raw_id_fields = ('student', 'subject')
    date_hierarchy = 'date'


@admin.register(ObserverLink)
class ObserverLinkAdmin(admin.ModelAdmin):
    list_display = ('id', 'observer', 'student', 'status', 'created_at')
    list_filter = ('status',)
    search_fields = (
        'observer__username',
        'observer__first_name',
        'student__username',
        'student__first_name',
    )
    ordering = ('-created_at',)
    raw_id_fields = ('observer', 'student')
