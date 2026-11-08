import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import 'subjects_screen.dart';

class AddGradeScreen extends StatefulWidget {
  const AddGradeScreen({super.key});

  @override
  State<AddGradeScreen> createState() => _AddGradeScreenState();
}

class _AddGradeScreenState extends State<AddGradeScreen> {
  List<dynamic> _subjects = [];
  int?  _selectedSubjectId;
  int?  _selectedScore;
  bool  _loadingSubjects = true;
  bool  _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final data = await SpectoService.instance.getSubjects();
      if (mounted) setState(() { _subjects = data; _loadingSubjects = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedSubjectId == null || _selectedScore == null) return;
    setState(() => _submitting = true);
    try {
      await SpectoService.instance.addGrade(_selectedSubjectId!, _selectedScore!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оценка добавлена!')),
        );
        Navigator.of(context).pop(true); // signal refresh
      }
    } on DioException catch (e) {
      final msg = _extractError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String) return v;
        }
      }
    } catch (_) {}
    return 'Ошибка добавления оценки';
  }

  Color _scoreColor(int score) {
    if (score >= 8) return AppColors.emerald;
    if (score >= 5) return AppColors.amber;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Добавить оценку')),
      body: _loadingSubjects
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.screenH,
                vertical: AppPadding.screenV,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── No subjects hint ──────────────
                  if (_subjects.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppPadding.card),
                      decoration: BoxDecoration(
                        color: AppColors.amberBg,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.amber, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'У вас пока нет предметов.\nДобавьте предметы, чтобы выставлять оценки.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SubjectsScreen(),
                                ),
                              );
                              _loadSubjects();
                            },
                            child: const Text('Перейти в «Список классов»'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // ── Subject picker ─────────────
                    const Text(
                      'Выберите предмет',
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
                        color: AppColors.bento,
                        borderRadius: BorderRadius.circular(AppRadius.bento),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedSubjectId,
                          hint: const Text('Предмет'),
                          items: _subjects.map<DropdownMenuItem<int>>((s) {
                            return DropdownMenuItem<int>(
                              value: s['id'] as int,
                              child: Text(s['name'] as String),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSubjectId = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Score grid 2×5 ─────────────
                    const Text(
                      'Выберите оценку',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildScoreGrid(),

                    const SizedBox(height: 32),

                    // ── Submit ─────────────────────
                    ElevatedButton(
                      onPressed: (_selectedSubjectId != null &&
                              _selectedScore != null &&
                              !_submitting)
                          ? _submit
                          : null,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Подтвердить'),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildScoreGrid() {
    return Column(
      children: [
        // row 1 → 1–5
        Row(
          children: List.generate(5, (i) => _scoreButton(i + 1)),
        ),
        const SizedBox(height: 10),
        // row 2 → 6–10
        Row(
          children: List.generate(5, (i) => _scoreButton(i + 6)),
        ),
      ],
    );
  }

  Widget _scoreButton(int score) {
    final isSelected = _selectedScore == score;
    final color = _scoreColor(score);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => setState(() => _selectedScore = score),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.bento,
              borderRadius: BorderRadius.circular(AppRadius.bento),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.transparent),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

