import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import '../../widgets/stats_widgets.dart';

class PreviousWeeksScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const PreviousWeeksScreen({super.key, this.studentId, this.studentName});

  @override
  State<PreviousWeeksScreen> createState() => _PreviousWeeksScreenState();
}

class _PreviousWeeksScreenState extends State<PreviousWeeksScreen> {
  int _offset = -1;
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
        offset: _offset,
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

  void _prevWeek() {
    setState(() => _offset--);
    _load();
  }

  void _nextWeek() {
    if (_offset < -1) {
      setState(() => _offset++);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Предыдущие недели')),
      body: Column(
        children: [
          // ── Листалка ──────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevWeek,
                  icon: const Icon(Icons.chevron_left_rounded, size: 30),
                  color: AppColors.primary,
                ),
                Text(
                  _weekStats?['week_range'] ?? 'Загрузка...',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: _offset < -1 ? _nextWeek : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 30),
                  color: _offset < -1 ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _weekStats == null
                    ? const Center(child: Text('Нет данных'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.screenH,
                            vertical: AppPadding.screenV,
                          ),
                          child: Container(
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
                                const SizedBox(height: 12),
                                BonusPenaltyRow(
                                  bonusCount: _weekStats!['bonus_count'] ?? 0,
                                  penaltyCount: _weekStats!['penalty_count'] ?? 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
