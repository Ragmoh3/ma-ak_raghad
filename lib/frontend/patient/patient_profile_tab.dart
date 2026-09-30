import 'package:flutter/material.dart';
import '../widgets/current_user_name.dart';
import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../shared/edit_profile_screen.dart';
import '../widgets/logged_out_dialog.dart';
import '../auth/login_screen.dart';
import '../shared/settings_screen.dart';
class PatientProfileTab extends StatelessWidget {
  const PatientProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    await SupabaseService.signOut();
    if (!context.mounted) return;
    showLoggedOutDialog(
      context,
      onBackToLogin: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.selectedCardFill,
            child: Icon(Icons.person, size: 36, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 10),
          const Center(
            child: CurrentUserName(
              style: TextStyle(color: AppColors.textDark,
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(email,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primaryNavy),
            title: const Text('Edit profile', style: TextStyle(color: AppColors.textDark)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(role: 'help_seeker'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timeline_outlined, color: AppColors.primaryNavy),
            title: const Text('My journey', style: TextStyle(color: AppColors.textDark)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.primaryNavy),
            title: const Text('Notifications', style: TextStyle(color: AppColors.textDark)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryNavy),
            title: const Text('Privacy & security', style: TextStyle(color: AppColors.textDark)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.primaryNavy),
            title: const Text('Help & support', style: TextStyle(color: AppColors.textDark)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
