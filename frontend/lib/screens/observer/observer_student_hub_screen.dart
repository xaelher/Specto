import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/specto_app_bar.dart';
import '../student/history_screen.dart';
import '../student/subjects_screen.dart';
import '../student/this_week_screen.dart';
import '../student/today_detail_screen.dart';

class ObserverStudentHubScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String? schoolGrade;

  const ObserverStudentHubScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.schoolGrade,
  });

  @override
  State<ObserverStudentHubScreen> createState() =>
      _ObserverStudentHubScreenState();
}

class _ObserverStudentHubScreenState extends State<ObserverStudentHubScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.instance.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentUser != null
          ? SpectoAppBar(
              user: _currentUser!,
              customTitle: widget.studentName,
            )
          : AppBar(
              title: Text(widget.studentName),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.screenH,
          vertical: AppPadding.screenV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Инфо-карточка ученика ──────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppPadding.card),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.schoolGrade != null &&
                                  widget.schoolGrade!.isNotEmpty
                              ? 'Класс: ${widget.schoolGrade}'
                              : 'Ученик',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Заголовок разделов ─────────────────
            const Text(
              'Дневник и аналитика',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // ── 4 кнопки-карточки ───────────────────
            _HubMenuCard(
              icon: Icons.today_rounded,
              title: 'Сегодня',
              subtitle: 'Оценки, статистика и банк за день',
              color: AppColors.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TodayDetailScreen(
                      studentId: widget.studentId,
                      studentName: widget.studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _HubMenuCard(
              icon: Icons.calendar_view_week_rounded,
              title: 'Неделя',
              subtitle: 'Статистика за текущую неделю',
              color: AppColors.emerald,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ThisWeekScreen(
                      studentId: widget.studentId,
                      studentName: widget.studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _HubMenuCard(
              icon: Icons.class_rounded,
              title: 'Список классов',
              subtitle: 'Учебные предметы ученика',
              color: AppColors.amber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubjectsScreen(
                      studentId: widget.studentId,
                      studentName: widget.studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _HubMenuCard(
              icon: Icons.history_rounded,
              title: 'История',
              subtitle: 'Предыдущие недели, дни и предметы',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(
                      studentId: widget.studentId,
                      studentName: widget.studentName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HubMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HubMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppPadding.card),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

