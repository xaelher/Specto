import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════════
// TodayStatsCard — Bento-карточка «Сегодня»
// ═════════════════════════════════════════════════════════════════

class TodayStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback? onTap;

  const TodayStatsCard({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    final date         = stats['date'] ?? '';
    final weekday      = stats['weekday_name'] ?? '';
    final gradesCount  = stats['grades_count'] ?? 0;
    final averageScore = stats['average_score'] ?? 0.0;
    final dayBank      = stats['day_bank'] ?? 0.0;
    final weekBank     = stats['week_bank'] ?? 0.0;
    final bonusCount   = stats['bonus_count'] ?? 0;
    final penaltyCount = stats['penalty_count'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.all(AppPadding.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Шапка: дата + день недели ────────
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  weekday,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Сетка 2x2 ───────────────────────
            Row(
              children: [
                BentoTile(label: 'Оценок получено', value: '$gradesCount'),
                const SizedBox(width: 10),
                BentoTile(label: 'Средняя оценка', value: '$averageScore'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                BentoTile(
                  label: 'Банк сегодня',
                  value: '$dayBank сомони',
                  valueColor: AppColors.emerald,
                ),
                const SizedBox(width: 10),
                BentoTile(
                  label: 'Банк недели',
                  value: '$weekBank сомони',
                  valueColor: AppColors.emerald,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Бейджи ──────────────────────────
            BonusPenaltyRow(bonusCount: bonusCount, penaltyCount: penaltyCount),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Переиспользуемые виджеты
// ═════════════════════════════════════════════════════════════════

/// Плитка Bento-сетки.
class BentoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const BentoTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bento,
          borderRadius: BorderRadius.circular(AppRadius.bento),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ряд капсул «Бонус x N / Штраф x N».
class BonusPenaltyRow extends StatelessWidget {
  final int bonusCount;
  final int penaltyCount;

  const BonusPenaltyRow({
    super.key,
    required this.bonusCount,
    required this.penaltyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'Бонус x $bonusCount', color: AppColors.emerald, bg: AppColors.emeraldBg),
        const SizedBox(width: 8),
        _Chip(label: 'Штраф x $penaltyCount', color: AppColors.danger, bg: AppColors.dangerBg),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Chip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// Карточка-статистика одной строкой (лейбл → значение).
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

