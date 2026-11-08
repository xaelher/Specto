import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import '../../widgets/stats_widgets.dart';

class SubjectHistoryScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const SubjectHistoryScreen({super.key, this.studentId, this.studentName});

  @override
  State<SubjectHistoryScreen> createState() => _SubjectHistoryScreenState();
}

class _SubjectHistoryScreenState extends State<SubjectHistoryScreen> {
  List<dynamic> _subjects = [];
  int? _selectedSubjectId;
  Map<String, dynamic>? _subjectStats;
  bool _loadingSubjects = true;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final list = await SpectoService.instance.getSubjects(studentId: widget.studentId);
      if (mounted) {
        setState(() {
          _subjects = list;
          _loadingSubjects = false;
        });
        if (list.isNotEmpty) {
          _onSelectSubject(list.first['id'] as int);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  Future<void> _onSelectSubject(int id) async {
    setState(() {
      _selectedSubjectId = id;
      _loadingStats = true;
    });

    try {
      final stats = await SpectoService.instance.getSubjectStats(
        id,
        studentId: widget.studentId,
      );
      if (mounted) {
        setState(() {
          _subjectStats = stats;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('История по предмету')),
      body: _loadingSubjects
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const Center(
                  child: Text(
                    'Список предметов пуст',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.screenH,
                    vertical: AppPadding.screenV,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выбрать предмет',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.bento),
                          boxShadow: AppShadows.card,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedSubjectId,
                            items: _subjects.map<DropdownMenuItem<int>>((s) {
                              return DropdownMenuItem<int>(
                                value: s['id'] as int,
                                child: Text(s['name'] as String),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) _onSelectSubject(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_loadingStats)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_subjectStats != null)
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
                              Text(
                                _subjectStats!['subject_name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Divider(height: 20),
                              StatRow(
                                label: 'Оценок получено (за этот предмет)',
                                value: '${_subjectStats!['grades_count'] ?? 0}',
                              ),
                              StatRow(
                                label: 'Средняя оценка (за этот предмет)',
                                value: '${_subjectStats!['average_score'] ?? 0.0}',
                              ),
                              StatRow(
                                label: 'Самая частая оценка (за этот предмет)',
                                value: _subjectStats!['most_frequent_score'] != null
                                    ? '${_subjectStats!['most_frequent_score']}'
                                    : '—',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

