import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../observer/observer_home_screen.dart';
import '../student/student_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtl   = TextEditingController();
  final _lastNameCtl    = TextEditingController();
  final _gradeCtl       = TextEditingController();
  final _usernameCtl    = TextEditingController();
  final _passCtl        = TextEditingController();
  final _passConfirmCtl = TextEditingController();

  String _role        = 'STUDENT'; // 'STUDENT' | 'OBSERVER'
  bool   _loading     = false;
  bool   _obscurePass = true;
  bool   _obscureConf = true;
  String? _errorMsg;

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _gradeCtl.dispose();
    _usernameCtl.dispose();
    _passCtl.dispose();
    _passConfirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final user = await AuthService.instance.register(
        username:        _usernameCtl.text.trim(),
        firstName:       _firstNameCtl.text.trim(),
        lastName:        _lastNameCtl.text.trim(),
        role:            _role,
        schoolGrade:     _role == 'STUDENT' ? _gradeCtl.text.trim() : '',
        password:        _passCtl.text,
        passwordConfirm: _passConfirmCtl.text,
      );
      if (mounted) _navigate(user);
    } on DioException catch (e) {
      setState(() { _errorMsg = _extractError(e); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        // Validation errors: first field error
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String) return v;
        }
      }
    } catch (_) {}
    return 'Ошибка подключения.';
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
      appBar: AppBar(
        title: const Text('Зарегистрировать аккаунт'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.screenH,
            vertical: AppPadding.screenV,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Role toggle ─────────────────
                _RoleToggle(
                  value: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
                const SizedBox(height: 22),

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

                // ── Name fields ─────────────────
                _field(_firstNameCtl, 'Имя',      Icons.badge_rounded,
                    next: true,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Введите имя' : null),
                const SizedBox(height: 12),
                _field(_lastNameCtl, 'Фамилия',   Icons.badge_outlined,
                    next: true,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Введите фамилию' : null),
                const SizedBox(height: 12),

                // ── Grade (STUDENT only) ─────────
                if (_role == 'STUDENT') ...[
                  _field(_gradeCtl, 'Класс (например: 10А)', Icons.class_rounded,
                      next: true,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Укажите класс' : null),
                  const SizedBox(height: 12),
                ],

                // ── Username ────────────────────
                _field(_usernameCtl, 'Логин',     Icons.alternate_email_rounded,
                    next: true,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Введите логин' : null),
                const SizedBox(height: 12),

                // ── Password ────────────────────
                _passField(_passCtl, 'Пароль', _obscurePass,
                    () => setState(() => _obscurePass = !_obscurePass),
                    validator: (v) =>
                        v == null || v.length < 8 ? 'Минимум 8 символов' : null),
                const SizedBox(height: 12),

                // ── Confirm password ─────────────
                _passField(_passConfirmCtl, 'Подтвердить пароль', _obscureConf,
                    () => setState(() => _obscureConf = !_obscureConf),
                    validator: (v) => v != _passCtl.text
                        ? 'Пароли не совпадают'
                        : null,
                    done: true),

                const SizedBox(height: 28),

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
                      : const Text('Подтвердить'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctl,
    String label,
    IconData icon, {
    bool next = false,
    bool done = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
      ),
      textInputAction:
          done ? TextInputAction.done : TextInputAction.next,
      validator: validator,
    );
  }

  Widget _passField(
    TextEditingController ctl,
    String label,
    bool obscure,
    VoidCallback toggle, {
    String? Function(String?)? validator,
    bool done = false,
  }) {
    return TextFormField(
      controller: ctl,
      obscureText: obscure,
      textInputAction:
          done ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppColors.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: toggle,
        ),
      ),
      validator: validator,
      onFieldSubmitted: done ? (_) => _submit() : null,
    );
  }
}

// ─────────────────────────────────────────────
// Role Toggle widget
// ─────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RoleToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bento,
        borderRadius: BorderRadius.circular(AppRadius.bento),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _RoleOption(
            label: 'Ученик',
            icon: Icons.school_rounded,
            selected: value == 'STUDENT',
            onTap: () => onChanged('STUDENT'),
          ),
          _RoleOption(
            label: 'Наблюдатель',
            icon: Icons.visibility_rounded,
            selected: value == 'OBSERVER',
            onTap: () => onChanged('OBSERVER'),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
