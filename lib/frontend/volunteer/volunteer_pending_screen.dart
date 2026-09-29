import 'dart:async';

import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'volunteer_shell.dart';
import 'volunteer_rejected_screen.dart';

/// Shown to Volunteers while their application is waiting for Admin approval.
/// The screen automatically checks the application status and redirects
/// the Volunteer when the Admin approves or rejects the application.
class VolunteerPendingScreen extends StatefulWidget {
  const VolunteerPendingScreen({super.key});

  @override
  State<VolunteerPendingScreen> createState() =>
      _VolunteerPendingScreenState();
}

class _VolunteerPendingScreenState
    extends State<VolunteerPendingScreen> {
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    // Check the application status immediately when the screen opens.
    _checkApplicationStatus();

    // Check the application status every 5 seconds while the Volunteer
    // is waiting for the Admin's decision.
    _statusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkApplicationStatus(),
    );
  }

  /// Gets the latest Volunteer application information from Supabase.
  ///
  /// If approved, the Volunteer is allowed to enter Volunteer features.
  /// If rejected, the Volunteer is shown the rejection reason and
  /// can submit a new application.
  Future<void> _checkApplicationStatus() async {
    try {
      // Get both the application status and rejection reason.
      final application =
          await SupabaseService.getMyVolunteerApplication();

      if (!mounted) return;

      final status = application?['status'] as String?;
      final rejectionReason =
          application?['rejection_reason'] as String? ?? '';

      if (status == 'approved') {
        // Stop checking because the application has been approved.
        _statusTimer?.cancel();

        // Approved Volunteers can now access Volunteer features.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const VolunteerShell(),
          ),
          (route) => false,
        );
      } else if (status == 'rejected') {
        // Stop checking because the Admin has made a final decision.
        _statusTimer?.cancel();

        // Show the rejection reason and allow the Volunteer
        // to submit a new application.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => VolunteerRejectedScreen(
              rejectionReason: rejectionReason,
            ),
          ),
          (route) => false,
        );
      }

      // If the status is pending_review, stay on this screen
      // and continue checking every 5 seconds.
    } catch (e) {
      // If the status check temporarily fails, keep the Volunteer
      // on the pending screen and try again on the next check.
    }
  }

  /// Logs the Volunteer out while their application is still pending.
  Future<void> _logout() async {
    // Stop checking the application status after logout.
    _statusTimer?.cancel();

    await SupabaseService.signOut();

    if (!mounted) return;

    // Return to the login screen and clear previous screens.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    // Cancel the timer when the screen is removed so it does not
    // continue checking the application status in the background.
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual indicator that the application is still being reviewed.
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.selectedCardFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 42,
                  color: AppColors.primaryNavy,
                ),
              ),

              const SizedBox(height: 28),

              // Main application status message.
              const Text(
                'Application Under Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              // Explains why Volunteer features are currently unavailable.
              const Text(
                'Thank you for applying to become a volunteer. '
                'Your application is currently under review. '
                'You will be able to access volunteer features once your application is approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Allows the Volunteer to log out while waiting
              // for the Admin's decision.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
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
