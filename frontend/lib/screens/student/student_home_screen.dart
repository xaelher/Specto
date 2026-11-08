import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/specto_service.dart';
import '../../widgets/specto_app_bar.dart';
import '../../widgets/stats_widgets.dart';
import 'add_grade_screen.dart';
import 'today_detail_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const StudentHomeScreen({super.key, this.studentId, this.studentName});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  UserModel? _user;
  Map<String, dynamic>? _todayStats;
  bool _loading = true;

  bool get _isOwner => widget.studentId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _user ??= await AuthService.instance.getCurrentUser();
      final stats = await SpectoService.instance.getTodayStats(studentId: widget.studentId);
      if (mounted) {
        setState(() {
          _todayStats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null && _loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = widget.studentName ?? _user?.fullName ?? 'Ученик';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isOwner && _user != null
          ? SpectoAppBar(user: _user!)
          : AppBar(
              title: Text(displayName),
            ),
      body: RefreshIndicator(
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
              if (_isOwner) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const AddGradeScreen(),
                      ),
                    );
                    if (res == true) {
                      _load();
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Добавить оценку'),
                ),
                const SizedBox(height: 16),
              ],
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_todayStats != null)
                TodayStatsCard(
                  stats: _todayStats!,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TodayDetailScreen(
                          studentId: widget.studentId,
                          studentName: widget.studentName,
                        ),
                      ),
                    ).then((_) => _load());
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppPadding.card),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: AppShadows.card,
                  ),
                  child: const Center(
                    child: Text(
                      'Не удалось загрузить статистику',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
