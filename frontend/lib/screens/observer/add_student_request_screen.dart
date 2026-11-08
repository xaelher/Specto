import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';

class AddStudentRequestScreen extends StatefulWidget {
  const AddStudentRequestScreen({super.key});

  @override
  State<AddStudentRequestScreen> createState() =>
      _AddStudentRequestScreenState();
}

class _AddStudentRequestScreenState extends State<AddStudentRequestScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  List<dynamic> _students = [];
  final Set<int> _sentIds = {};
  final Set<int> _loadingIds = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _loading = true);
    try {
      final list = await SpectoService.instance.searchStudents(query.trim());
      if (mounted) {
        setState(() {
          _students = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest(int studentId) async {
    setState(() => _loadingIds.add(studentId));
    try {
      await SpectoService.instance.sendObserverRequest(studentId);
      if (mounted) {
        setState(() {
          _sentIds.add(studentId);
          _loadingIds.remove(studentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запрос успешно отправлен')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _loadingIds.remove(studentId));
        String msg = 'Ошибка отправки запроса';
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          msg = data['detail'].toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loadingIds.remove(studentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Добавить ученика')),
      body: Column(
        children: [
          // ── Поле поиска ────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppPadding.screenH),
            child: TextField(
              controller: _searchCtl,
              onChanged: (val) => _performSearch(val),
              decoration: InputDecoration(
                hintText: 'Поиск по имени, фамилии или логину...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchCtl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtl.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Список учеников ─────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(
                        child: Text(
                          'Ученики не найдены',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppPadding.screenH,
                          0,
                          AppPadding.screenH,
                          AppPadding.screenV,
                        ),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _students[index] as Map<String, dynamic>;
                          final id = item['id'] as int;
                          final firstName = item['first_name'] ?? '';
                          final lastName = item['last_name'] ?? '';
                          final fullName = '$firstName $lastName'.trim();
                          final username = item['username'] ?? '';
                          final grade = item['school_grade'] ?? '';
                          final isSent = _sentIds.contains(id);
                          final isLoading = _loadingIds.contains(id);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
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
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
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
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldBg,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.chip,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: AppColors.emerald,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Отправлено',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.emerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => _sendRequest(id),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(90, 36),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Добавить',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

