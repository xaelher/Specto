import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/specto_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _gradeCtl = TextEditingController();
  final _usernameCtl = TextEditingController();

  UserModel? _user;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _gradeCtl.dispose();
    _usernameCtl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        if (user != null) {
          _firstNameCtl.text = user.firstName;
          _lastNameCtl.text = user.lastName;
          _gradeCtl.text = user.schoolGrade;
          _usernameCtl.text = user.username;
        }
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updatedData = await SpectoService.instance.updateProfile(
        firstName: _firstNameCtl.text.trim(),
        lastName: _lastNameCtl.text.trim(),
        schoolGrade: _user?.isStudent == true ? _gradeCtl.text.trim() : null,
        username: _usernameCtl.text.trim(),
      );

      final updatedUser = UserModel.fromJson(updatedData);
      // Также обновляем локальный кеш
      final currentUser = await AuthService.instance.getCurrentUser();
      if (currentUser != null) {
        // пересохраним профиль
        await AuthService.instance.login(
          username: updatedUser.username,
          password: '', // это вызовет сохранение, но у нас есть _saveUser в AuthService
        ).catchError((_) => updatedUser); // fallback
      }

      setState(() {
        _user = updatedUser;
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
      }
    } on DioException catch (e) {
      setState(() => _saving = false);
      String msg = 'Ошибка сохранения';
      final data = e.response?.data;
      if (data is Map) {
        if (data['detail'] != null) {
          msg = data['detail'].toString();
        } else {
          for (final val in data.values) {
            if (val is List && val.isNotEmpty) msg = val.first.toString();
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  void _showChangePasswordDialog() {
    final oldPassCtl = TextEditingController();
    final newPassCtl = TextEditingController();
    final confirmPassCtl = TextEditingController();
    final passFormKey = GlobalKey<FormState>();
    bool passLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              title: const Text('Сменить пароль'),
              content: Form(
                key: passFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPassCtl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Старый пароль'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Введите старый пароль' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPassCtl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Новый пароль'),
                        validator: (v) =>
                            v == null || v.length < 8 ? 'Минимум 8 символов' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPassCtl,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Подтвердить пароль'),
                        validator: (v) => v != newPassCtl.text
                            ? 'Пароли не совпадают'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: passLoading
                      ? null
                      : () async {
                          if (!passFormKey.currentState!.validate()) return;
                          setDialogState(() => passLoading = true);
                          try {
                            await SpectoService.instance.changePassword(
                              oldPassCtl.text,
                              newPassCtl.text,
                              confirmPassCtl.text,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Пароль успешно изменён')),
                              );
                            }
                          } on DioException catch (e) {
                            setDialogState(() => passLoading = false);
                            String msg = 'Ошибка изменения пароля';
                            final data = e.response?.data;
                            if (data is Map) {
                              if (data['detail'] != null) {
                                msg = data['detail'].toString();
                              } else {
                                for (final val in data.values) {
                                  if (val is List && val.isNotEmpty) {
                                    msg = val.first.toString();
                                  }
                                }
                              }
                            }
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 42),
                  ),
                  child: passLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roleText = _user?.isStudent == true ? 'Ученик' : 'Наблюдатель';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ваш профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.screenH,
          vertical: AppPadding.screenV,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Роль (только для чтения) ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Icon(
                      _user?.isStudent == true
                          ? Icons.school_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Роль',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          roleText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Редактируемые поля ────────────────────────
              TextFormField(
                controller: _firstNameCtl,
                decoration: const InputDecoration(labelText: 'Имя'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtl,
                decoration: const InputDecoration(labelText: 'Фамилия'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Введите фамилию' : null,
              ),
              const SizedBox(height: 12),
              if (_user?.isStudent == true) ...[
                TextFormField(
                  controller: _gradeCtl,
                  decoration: const InputDecoration(labelText: 'Класс'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Введите класс' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _usernameCtl,
                decoration: const InputDecoration(labelText: 'Логин'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Введите логин' : null,
              ),
              const SizedBox(height: 24),

              // ── Кнопка сохранить ──────────────────────────
              ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Сохранить изменения'),
              ),
              const SizedBox(height: 14),

              // ── Кнопка сменить пароль ─────────────────────
              OutlinedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Сменить пароль'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

