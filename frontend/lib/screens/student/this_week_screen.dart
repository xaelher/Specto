import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import '../../widgets/stats_widgets.dart';

class ThisWeekScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const ThisWeekScreen({super.key, this.studentId, this.studentName});

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  Map<String, dynamic>? _weekStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await SpectoService.instance.getWeekStats(
        offset: 0,
        studentId: widget.studentId,
      );
      if (mounted) {
        setState(() {
          _weekStats = stats;
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
        ? 'Эта неделя — ${widget.studentName}'
        : 'Эта неделя';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weekStats == null
              ? const Center(child: Text('Не удалось загрузить данные'))
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
                                  const Icon(Icons.calendar_view_week_rounded,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _weekStats!['week_range'] ?? 'Текущая неделя',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              StatRow(
                                label: 'Оценок получено (За неделю)',
                                value: '${_weekStats!['grades_count'] ?? 0}',
                              ),
                              StatRow(
                                label: 'Средняя оценка (За неделю)',
                                value: '${_weekStats!['average_score'] ?? 0.0}',
                              ),
                              StatRow(
                                label: 'Банк (За неделю)',
                                value: '${_weekStats!['week_bank'] ?? 0.0} сомони',
                                valueColor: AppColors.emerald,
                              ),
                              StatRow(
                                label: 'Дней прошло',
                                value: '${_weekStats!['days_passed'] ?? 0}',
                              ),
                              const SizedBox(height: 12),
                              BonusPenaltyRow(
                                bonusCount: _weekStats!['bonus_count'] ?? 0,
                                penaltyCount: _weekStats!['penalty_count'] ?? 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

