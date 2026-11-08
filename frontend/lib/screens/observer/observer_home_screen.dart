import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/specto_service.dart';
import '../../widgets/specto_app_bar.dart';
import 'add_student_request_screen.dart';
import 'observer_student_hub_screen.dart';

class ObserverHomeScreen extends StatefulWidget {
  const ObserverHomeScreen({super.key});

  @override
  State<ObserverHomeScreen> createState() => _ObserverHomeScreenState();
}

class _ObserverHomeScreenState extends State<ObserverHomeScreen> {
  UserModel? _user;
  List<dynamic> _acceptedStudents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _user ??= await AuthService.instance.getCurrentUser();
      final data = await SpectoService.instance.getObserverStudents();
      if (mounted) {
        setState(() {
          _acceptedStudents = data['accepted'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null && _loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _user != null ? SpectoAppBar(user: _user!) : null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.screenH,
            vertical: AppPadding.screenV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Карточка «Ученики» ─────────────────
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
                        const Text(
                          'Ученики',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AddStudentRequestScreen(),
                              ),
                            );
                            _loadData();
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Добавить'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_acceptedStudents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 48,
                                color:
                                    AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'У вас пока нет прикреплённых учеников',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Нажмите «Добавить», чтобы отправить запрос ученику.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _acceptedStudents.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final link =
                              _acceptedStudents[index] as Map<String, dynamic>;
                          final student =
                              link['student'] as Map<String, dynamic>;
                          final id = student['id'] as int;
                          final firstName = student['first_name'] ?? '';
                          final lastName = student['last_name'] ?? '';
                          final fullName = '$firstName $lastName'.trim();
                          final username = student['username'] ?? '';
                          final grade = student['school_grade'] ?? '';

                          return InkWell(
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
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
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
                          );
                        },
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
