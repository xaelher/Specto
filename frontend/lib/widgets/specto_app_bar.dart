import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/observer/observer_home_screen.dart';
import '../screens/observer/observer_students_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/student/history_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/student/student_observers_screen.dart';
import '../screens/student/subjects_screen.dart';
import '../screens/student/this_week_screen.dart';
import '../services/auth_service.dart';

class SpectoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel user;
  final String? customTitle; // Для отображения имени ученика в кабинете наблюдателя

  const SpectoAppBar({
    super.key,
    required this.user,
    this.customTitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Возврат на главную страницу своей роли со сбросом стека
  void _goHome(BuildContext context) {
    final home = user.isStudent
        ? const StudentHomeScreen()
        : const ObserverHomeScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => home),
      (_) => false,
    );
  }

  Future<void> _showMenu(BuildContext buttonContext, BuildContext rootContext) async {
    final RenderBox button = buttonContext.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()! as RenderBox;
    final offset = button.localToGlobal(Offset.zero, ancestor: overlay);
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx + button.size.width - 210,
      offset.dy + button.size.height + 6,
      offset.dx + button.size.width,
      0,
    );

    final studentItems = [
      _MenuItem('subjects',  Icons.class_rounded,      'Список классов',  _onSubjects),
      _MenuItem('week',      Icons.view_week_rounded,  'Эта неделя',      _onWeek),
      _MenuItem('history',   Icons.history_rounded,    'История',         _onHistory),
      _MenuItem('profile',   Icons.person_rounded,     'Профиль',         _onProfile),
      _MenuItem('observers', Icons.visibility_rounded, 'Наблюдатель',     _onObservers),
      _MenuItem('logout',    Icons.logout_rounded,     'Выйти',           _onLogout, danger: true),
    ];

    final observerItems = [
      _MenuItem('students',  Icons.people_rounded,     'Список учеников', _onStudents),
      _MenuItem('profile',   Icons.person_rounded,     'Профиль',         _onProfile),
      _MenuItem('logout',    Icons.logout_rounded,     'Выйти',           _onLogout, danger: true),
    ];

    final items = user.isStudent ? studentItems : observerItems;

    final selectedKey = await showMenu<String>(
      context: buttonContext,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: AppColors.surface,
      items: items.map((m) {
        return PopupMenuItem<String>(
          value: m.key,
          child: Row(
            children: [
              Icon(
                m.icon,
                size: 18,
                color: m.danger ? AppColors.danger : AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Text(
                m.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: m.danger ? AppColors.danger : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selectedKey != null && rootContext.mounted) {
      final selectedItem = items.firstWhere((item) => item.key == selectedKey);
      selectedItem.onTap(rootContext);
    }
  }

  // ── Menu actions ─────────────────────────────

  void _onSubjects(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const SubjectsScreen()),
    );
  }

  void _onWeek(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const ThisWeekScreen()),
    );
  }

  void _onHistory(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void _onObservers(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const StudentObserversScreen()),
    );
  }

  void _onStudents(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const ObserverStudentsScreen()),
    );
  }

  void _onProfile(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _onLogout(BuildContext ctx) async {
    await AuthService.instance.logout();
    if (ctx.mounted) {
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 120,
      centerTitle: true,
      leading: _LogoButton(onTap: () => _goHome(context)),
      title: Text(
        customTitle ?? user.fullName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showMenu(ctx, context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Specto',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String key;
  final IconData icon;
  final String label;
  final void Function(BuildContext) onTap;
  final bool danger;

  _MenuItem(this.key, this.icon, this.label, this.onTap, {this.danger = false});
}
