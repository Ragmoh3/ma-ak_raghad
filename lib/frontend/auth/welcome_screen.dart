import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import '../widgets/maak_logo.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'choose_role_screen.dart';
import 'auth_gate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Column(children: [
      Expanded(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const MaakLogo(iconSize: 72),
          const SizedBox(height: 32),
          const Text("Welcome to Ma'ak", textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 12),
          const Text("You're not alone. Connect with someone who understands your journey.",
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Log in')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChooseRoleScreen())), child: const Text('Create an account')),
          if (SupabaseService.currentUser != null)
            TextButton(onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthGate())), child: const Text('Continue to my account')),
        ]),
      ))),
      const MaakBottomHills(),
    ])),
  );
}
