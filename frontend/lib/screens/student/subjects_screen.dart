import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';
import 'add_subjects_screen.dart';

class SubjectsScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;

  const SubjectsScreen({super.key, this.studentId, this.studentName});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<dynamic> _subjects = [];
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
      final data = await SpectoService.instance.getSubjects(studentId: widget.studentId);
      if (mounted) setState(() { _subjects = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить класс?'),
        content: Text('Вы уверены, что хотите удалить «$name»?\nИстория оценок сохранится.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SpectoService.instance.deleteSubject(id);
        _load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка удаления')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.studentName != null
        ? 'Классы — ${widget.studentName}'
        : 'Список классов';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // ── Кнопка добавить (только владелец) ──
                  if (_isOwner)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppPadding.screenH, 12, AppPadding.screenH, 4,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final added = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const AddSubjectsScreen(),
                            ),
                          );
                          if (added == true) _load();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Добавить классы'),
                      ),
                    ),

                  // ── Список предметов ──────────────
                  Expanded(
                    child: _subjects.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Предметов пока нет',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.screenH,
                              vertical: 12,
                            ),
                            itemCount: _subjects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final s    = _subjects[i];
                              final id   = s['id'] as int;
                              final name = s['name'] as String;

                              return GestureDetector(
                                onLongPress: _isOwner
                                    ? () => _confirmDelete(id, name)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      AppPadding.card),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.card),
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.book_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (_isOwner)
                                        const Icon(
                                          Icons.more_horiz_rounded,
                                          color: AppColors.textSecondary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

