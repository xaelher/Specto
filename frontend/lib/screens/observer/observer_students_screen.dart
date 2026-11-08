import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import 'add_student_request_screen.dart';
import 'observer_student_hub_screen.dart';

class ObserverStudentsScreen extends StatefulWidget {
  const ObserverStudentsScreen({super.key});

  @override
  State<ObserverStudentsScreen> createState() => _ObserverStudentsScreenState();
}

class _ObserverStudentsScreenState extends State<ObserverStudentsScreen> {
  List<dynamic> _accepted = [];
  List<dynamic> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SpectoService.instance.getObserverStudents();
      if (mounted) {
        setState(() {
          _accepted = data['accepted'] as List? ?? [];
          _pending = data['pending'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Список учеников')),
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
                    // ── Кнопка «Добавить ученика» ──────────
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddStudentRequestScreen(),
                          ),
                        );
                        _load();
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Добавить ученика'),
                    ),
                    const SizedBox(height: 24),

                    // ── Принятые ученики ────────────────────
                    const Text(
                      'Мои ученики',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_accepted.isEmpty)
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
                            'У вас пока нет прикреплённых учеников',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._accepted.map((link) {
                        final student = link['student'] as Map<String, dynamic>;
                        final id = student['id'] as int;
                        final firstName = student['first_name'] ?? '';
                        final lastName = student['last_name'] ?? '';
                        final fullName = '$firstName $lastName'.trim();
                        final username = student['username'] ?? '';
                        final grade = student['school_grade'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ObserverStudentHubScreen(
                                    studentId: id,
                                    studentName: fullName.isNotEmpty
                                        ? fullName
                                        : username,
                                    schoolGrade: grade.toString(),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppPadding.card),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                                boxShadow: AppShadows.card,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName.isNotEmpty
                                              ? fullName
                                              : username,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          grade.toString().isNotEmpty
                                              ? 'Класс: $grade • @$username'
                                              : '@$username',
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
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // ── Ожидающие ответа ────────────────────
                    if (_pending.isNotEmpty) ...[
                      const Text(
                        'Ожидают подтверждения',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._pending.map((link) {
                        final student = link['student'] as Map<String, dynamic>;
                        final firstName = student['first_name'] ?? '';
                        final lastName = student['last_name'] ?? '';
                        final fullName = '$firstName $lastName'.trim();
                        final username = student['username'] ?? '';
                        final grade = student['school_grade'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(AppPadding.card),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.amberBg,
                                child: Icon(
                                  Icons.hourglass_top_rounded,
                                  color: AppColors.amber,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName.isNotEmpty ? fullName : username,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      grade.toString().isNotEmpty
                                          ? 'Класс: $grade • @$username'
                                          : '@$username',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amberBg,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.chip,
                                  ),
                                ),
                                child: const Text(
                                  'Ожидается ответ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

