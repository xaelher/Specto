import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../observer/observer_home_screen.dart';
import '../student/student_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _loginCtl = TextEditingController();
  final _passCtl  = TextEditingController();

  bool _loading       = false;
  bool _obscurePass   = true;
  String? _errorMsg;

  @override
  void dispose() {
    _loginCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final user = await AuthService.instance.login(
        username: _loginCtl.text.trim(),
        password: _passCtl.text,
      );
      if (mounted) _navigate(user);
    } on DioException catch (e) {
      final detail = _extractError(e);
      setState(() { _errorMsg = detail; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) return data['detail']?.toString() ?? 'Ошибка входа';
    } catch (_) {}
    return 'Ошибка подключения. Проверь интернет.';
  }

  Future<void> _showServerSettingsDialog() async {
    final currentUrl = await ApiClient.instance.getBaseUrl();
    final initialInput = currentUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/api', '');

    final ctl = TextEditingController(text: initialInput);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Адрес сервера', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Укажите IP:порт или интернет-домен (ngrok):',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                decoration: const InputDecoration(
                  hintText: 'my-specto.ngrok-free.app или 127.0.0.1:8000',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ctl.text = '127.0.0.1:8000';
                },
                icon: const Icon(Icons.phone_android_rounded, size: 16),
                label: const Text('Этот телефон (127.0.0.1:8000)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = await ApiClient.instance.setBaseUrl(ctl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Сервер установлен: $newUrl')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(90, 40),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _navigate(UserModel user) {
    final screen = user.isStudent
        ? const StudentHomeScreen()
        : const ObserverHomeScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.screenH,
            vertical: 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Logo + Settings button ──────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'S',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Specto',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                      onPressed: _showServerSettingsDialog,
                      tooltip: 'Адрес сервера',
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Title ───────────────────────
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Войдите в свой аккаунт',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Error banner ─────────────────
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppRadius.bento),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Login field ─────────────────
                TextFormField(
                  controller: _loginCtl,
                  decoration: const InputDecoration(
                    labelText: 'Логин',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Введите логин' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // ── Password field ──────────────
                TextFormField(
                  controller: _passCtl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Введите пароль' : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 28),

                // ── Login button ────────────────
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Log in'),
                ),

                const SizedBox(height: 14),

                // ── Register link ───────────────
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('Зарегистрировать аккаунт'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
