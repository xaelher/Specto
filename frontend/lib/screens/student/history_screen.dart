import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import '../../widgets/stats_widgets.dart';
import 'day_history_screen.dart';
import 'previous_weeks_screen.dart';
import 'subject_history_screen.dart';

class HistoryScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const HistoryScreen({super.key, this.studentId, this.studentName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic>? _overview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SpectoService.instance.getHistoryOverview(
        studentId: widget.studentId,
      );
      if (mounted) {
        setState(() {
          _overview = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.studentName != null
        ? 'История — ${widget.studentName}'
        : 'История';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.screenH,
                  vertical: AppPadding.screenV,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 3 кнопки-карточки ────────────────────────
                    Row(
                      children: [
                        _HistoryNavCard(
                          icon: Icons.calendar_view_week_rounded,
                          title: 'Предыдущие\nнедели',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PreviousWeeksScreen(
                                  studentId: widget.studentId,
                                  studentName: widget.studentName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _HistoryNavCard(
                          icon: Icons.calendar_today_rounded,
                          title: 'День',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DayHistoryScreen(
                                  studentId: widget.studentId,
                                  studentName: widget.studentName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _HistoryNavCard(
                          icon: Icons.book_rounded,
                          title: 'Предмет',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectHistoryScreen(
                                  studentId: widget.studentId,
                                  studentName: widget.studentName,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Общая статистика ─────────────────────────
                    if (_overview != null) ...[
                      const Text(
                        'Общая статистика',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppPadding.card),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          boxShadow: AppShadows.card,
                        ),
                        child: Column(
                          children: [
                            StatRow(
                              label: 'Дней прошло',
                              value:
                                  '${_overview!['total_days_passed'] ?? 0} дней прошло (${_overview!['study_days_passed'] ?? 0} учебных)',
                            ),
                            StatRow(
                              label: 'Оценок получено (за все время)',
                              value: '${_overview!['total_grades_count'] ?? 0}',
                            ),
                            StatRow(
                              label: 'Средняя оценка (за все время)',
                              value: '${_overview!['total_average_score'] ?? 0.0}',
                            ),
                            StatRow(
                              label: 'Общий банк (за все время)',
                              value: '${_overview!['total_bank'] ?? 0.0} сомони',
                              valueColor: AppColors.emerald,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _HistoryNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HistoryNavCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

