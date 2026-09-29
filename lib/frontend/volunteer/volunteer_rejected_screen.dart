import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'volunteer_reapplication_screen.dart';

/// Shown to Volunteers when their application has been rejected by the Admin.
/// The screen displays the rejection reason and allows the Volunteer
/// to submit a new application.
class VolunteerRejectedScreen extends StatelessWidget {
  final String rejectionReason;

  const VolunteerRejectedScreen({
    super.key,
    required this.rejectionReason,
  });

  // Logs the Volunteer out and clears the navigation stack
  // so they cannot return to previous protected screens.
  Future<void> _logout(BuildContext context) async {
    await SupabaseService.signOut();

    if (!context.mounted) return;

    // Return the user to the login screen after signing out.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // Opens the reapplication screen for the rejected Volunteer.
  // The existing account is kept, so no new account is created.
  void _reapply(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VolunteerReapplicationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Visual indicator that the application was not approved.
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.selectedCardFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 44,
                  color: AppColors.primaryNavy,
                ),
              ),

              const SizedBox(height: 28),

              // Main application status message.
              const Text(
                'Application Not Approved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Your volunteer application was not approved at this time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Displays the reason provided by the Admin
              // when rejecting the Volunteer application.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.fieldBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      rejectionReason.isNotEmpty
                          ? rejectionReason
                          : 'No reason was provided.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Opens a separate reapplication form.
              // The Volunteer can update the previous application
              // information and submit it again for Admin review.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _reapply(context),
                  child: const Text('Submit New Application'),
                ),
              ),

              const SizedBox(height: 12),

              // The Volunteer can also leave the account
              // without submitting another application.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _logout(context),
                  child: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
