from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    # ── Auth ────────────────────────────────────────────────────
    path('auth/register/', views.RegisterView.as_view(), name='auth-register'),
    path('auth/login/',    views.LoginView.as_view(),    name='auth-login'),
    path('auth/refresh/',  TokenRefreshView.as_view(),   name='auth-refresh'),

    # ── Profile ──────────────────────────────────────────────────
    path('profile/',                 views.ProfileView.as_view(),        name='profile'),
    path('profile/change-password/', views.ChangePasswordView.as_view(), name='change-password'),

    # ── Observer ─────────────────────────────────────────────────
    path('observer/students/',                 views.ObserverStudentsListView.as_view(), name='observer-students'),
    path('observer/students/search/',          views.SearchStudentsView.as_view(),       name='observer-search'),
    path('observer/request/<int:student_id>/', views.SendObserverRequestView.as_view(),  name='observer-request'),

    # ── Student ──────────────────────────────────────────────────
    path('student/observers/',                       views.StudentObserversListView.as_view(),   name='student-observers'),
    path('student/observers/<int:link_id>/respond/', views.RespondObserverRequestView.as_view(), name='student-respond'),
    path('student/observers/<int:link_id>/',         views.RemoveObserverView.as_view(),         name='student-remove-observer'),

    # ── Subjects ─────────────────────────────────────────────────
    path('subjects/',                    views.SubjectListView.as_view(),   name='subject-list'),
    path('subjects/create/',             views.SubjectCreateView.as_view(), name='subject-create'),
    path('subjects/<int:subject_id>/',   views.SubjectDeleteView.as_view(), name='subject-delete'),

    # ── Grades ───────────────────────────────────────────────────
    path('grades/create/', views.GradeCreateView.as_view(), name='grade-create'),

    # ── Stats ────────────────────────────────────────────────────
    path('stats/today/',                      views.StatsTodayView.as_view(),   name='stats-today'),
    path('stats/week/',                       views.StatsWeekView.as_view(),    name='stats-week'),
    path('stats/history/',                    views.StatsHistoryView.as_view(), name='stats-history'),
    path('stats/day/',                        views.StatsDayView.as_view(),     name='stats-day'),
    path('stats/subject/<int:subject_id>/',   views.StatsSubjectView.as_view(), name='stats-subject'),
]
