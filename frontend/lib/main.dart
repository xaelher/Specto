import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/observer/observer_home_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  runApp(const SpectoApp());
}

class SpectoApp extends StatelessWidget {
  const SpectoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Specto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _SplashRouter(),
    );
  }
}

/// Checks auth state and routes accordingly.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;

    if (!loggedIn) {
      _go(const LoginScreen());
      return;
    }

    final UserModel? user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;

    if (user == null) {
      _go(const LoginScreen());
      return;
    }

    _go(user.isStudent ? const StudentHomeScreen() : const ObserverHomeScreen());
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Specto',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
