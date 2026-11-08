import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import '../../widgets/stats_widgets.dart';

class TodayDetailScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const TodayDetailScreen({super.key, this.studentId, this.studentName});

  @override
  State<TodayDetailScreen> createState() => _TodayDetailScreenState();
}

class _TodayDetailScreenState extends State<TodayDetailScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SpectoService.instance.getTodayStats(studentId: widget.studentId);
      if (mounted) setState(() => _stats = data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.studentName != null
        ? 'Сегодня — ${widget.studentName}'
        : 'Сегодня';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Нет данных'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = _stats!;
    final date         = s['date'] ?? '';
    final weekday      = s['weekday_name'] ?? '';
    final gradesCount  = s['grades_count'] ?? 0;
    final averageScore = s['average_score'] ?? 0.0;
    final dayBank      = s['day_bank'] ?? 0.0;
    final weekBank     = s['week_bank'] ?? 0.0;
    final bonusCount   = s['bonus_count'] ?? 0;
    final penaltyCount = s['penalty_count'] ?? 0;
    final grades       = (s['grades'] as List?) ?? [];

    return RefreshIndicator(
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
            // ── Дата ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppPadding.card),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '$date — $weekday',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  StatRow(label: 'Оценок получено', value: '$gradesCount'),
                  StatRow(label: 'Средняя оценка', value: '$averageScore'),
                  StatRow(
                    label: 'Банк сегодня',
                    value: '$dayBank сомони',
                    valueColor: AppColors.emerald,
                  ),
                  StatRow(
                    label: 'Банк недели',
                    value: '$weekBank сомони',
                    valueColor: AppColors.emerald,
                  ),

                  const SizedBox(height: 8),
                  BonusPenaltyRow(
                    bonusCount: bonusCount,
                    penaltyCount: penaltyCount,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Оценки по предметам ─────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppPadding.card),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Предметы по которым получены оценки',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (grades.isEmpty)
                    const Text(
                      'Оценок за сегодня пока нет',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ...grades.map<Widget>((g) {
                      final name  = g['subject'] ?? '';
                      final score = g['score'] ?? 0;
                      final color = _scoreColor(score);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.bento),
                              ),
                              child: Text(
                                '$score',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 8) return AppColors.emerald;
    if (score >= 5) return AppColors.amber;
    return AppColors.danger;
  }
}

