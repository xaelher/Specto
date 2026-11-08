import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import '../../widgets/stats_widgets.dart';

class DayHistoryScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const DayHistoryScreen({super.key, this.studentId, this.studentName});

  @override
  State<DayHistoryScreen> createState() => _DayHistoryScreenState();
}

class _DayHistoryScreenState extends State<DayHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _dayStats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickDate();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadDate(picked);
    } else if (_dayStats == null) {
      _loadDate(_selectedDate);
    }
  }

  Future<void> _loadDate(DateTime date) async {
    setState(() => _loading = true);
    final iso = DateFormat('yyyy-MM-dd').format(date);
    try {
      final stats = await SpectoService.instance.getDayStats(
        iso,
        studentId: widget.studentId,
      );
      if (mounted) {
        setState(() {
          _dayStats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 8) return AppColors.emerald;
    if (score >= 5) return AppColors.amber;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final grades = (_dayStats?['grades'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('История дня'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dayStats == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('Выбрать дату'),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.screenH,
                    vertical: AppPadding.screenV,
                  ),
                  child: Column(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_dayStats!['date']} — ${_dayStats!['weekday_name']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _pickDate,
                                  child: const Text('Изменить'),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            StatRow(
                              label: 'Средняя оценка (за день)',
                              value: '${_dayStats!['average_score'] ?? 0.0}',
                            ),
                            StatRow(
                              label: 'Банк',
                              value: '${_dayStats!['day_bank'] ?? 0.0} сомони',
                              valueColor: AppColors.emerald,
                            ),
                            const SizedBox(height: 12),
                            BonusPenaltyRow(
                              bonusCount: _dayStats!['bonus_count'] ?? 0,
                              penaltyCount: _dayStats!['penalty_count'] ?? 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                'Нет оценок за этот день',
                                style: TextStyle(color: AppColors.textSecondary),
                              )
                            else
                              ...grades.map<Widget>((g) {
                                final name = g['subject'] ?? '';
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
                    ],
                  ),
                ),
    );
  }
}
