import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';

class StudentObserversScreen extends StatefulWidget {
  const StudentObserversScreen({super.key});

  @override
  State<StudentObserversScreen> createState() => _StudentObserversScreenState();
}

class _StudentObserversScreenState extends State<StudentObserversScreen> {
  List<dynamic> _pending = [];
  List<dynamic> _accepted = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SpectoService.instance.getStudentObservers();
      if (mounted) {
        setState(() {
          _pending = res['pending'] as List? ?? [];
          _accepted = res['accepted'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(int linkId, String action) async {
    try {
      await SpectoService.instance.respondObserverRequest(linkId, action);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при обработке запроса')),
        );
      }
    }
  }

  Future<void> _remove(int linkId, String observerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить наблюдателя?'),
        content: Text('Вы действительно хотите удалить $observerName из наблюдателей?'),
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
        await SpectoService.instance.removeObserver(linkId);
        _load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при удалении')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Наблюдатели')),
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
                    // ── Входящие запросы ─────────────────────────
                    if (_pending.isNotEmpty) ...[
                      const Text(
                        'Входящие запросы',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._pending.map((link) {
                        final id = link['id'] as int;
                        final obs = link['observer'] as Map<String, dynamic>?;
                        final name =
                            '${obs?['first_name'] ?? ''} ${obs?['last_name'] ?? ''}'.trim();
                        final username = obs?['username'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppColors.amberBg,
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.isNotEmpty ? name : username,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '@$username',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respond(id, 'accept'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.emerald,
                                        minimumSize: const Size(0, 42),
                                      ),
                                      child: const Text('Принять'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _respond(id, 'reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(color: AppColors.danger),
                                        minimumSize: const Size(0, 42),
                                      ),
                                      child: const Text('Отклонить'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // ── Активные наблюдатели ─────────────────────
                    const Text(
                      'Активные наблюдатели',
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
                            'У вас пока нет активных наблюдателей',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._accepted.map((link) {
                        final id = link['id'] as int;
                        final obs = link['observer'] as Map<String, dynamic>?;
                        final name =
                            '${obs?['first_name'] ?? ''} ${obs?['last_name'] ?? ''}'.trim();
                        final username = obs?['username'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(AppPadding.card),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.visibility_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isNotEmpty ? name : username,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '@$username',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.danger),
                                onPressed: () =>
                                    _remove(id, name.isNotEmpty ? name : username),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
