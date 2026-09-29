import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import 'choose_role_screen.dart';
import '../patient/patient_shell.dart';
import '../volunteer/volunteer_shell.dart';
import '../volunteer/volunteer_pending_screen.dart';
import '../volunteer/volunteer_rejected_screen.dart';
import '../admin/admin_dashboard.dart';

/// Shown at app start when a session already exists
/// (the user closed the app without logging out).
///
/// The AuthGate checks the user's role and routes them to the
/// correct screen without requiring them to log in again.
///
/// Volunteers require an additional application-status check
/// before they can access Volunteer features.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// Determines the correct screen based on the user's role.
  ///
  /// For Volunteers, the application status is also checked:
  /// - approved       -> VolunteerShell
  /// - pending_review -> VolunteerPendingScreen
  /// - rejected       -> VolunteerRejectedScreen
  Future<Widget> _getDestination() async {
    // Get the role saved in the profiles table.
    final role = await SupabaseService.getMyRole();

    if (role == 'help_seeker') {
      // Support Seekers can access their main area directly.
      return const PatientShell();
    }

    if (role == 'volunteer') {
      // Get the Volunteer application information.
      // This includes both the application status and,
      // when applicable, the Admin's rejection reason.
      final application =
          await SupabaseService.getMyVolunteerApplication();

      final status = application?['status'] as String?;
      final rejectionReason =
          application?['rejection_reason'] as String? ?? '';

      if (status == 'approved') {
        // Approved Volunteers can access all Volunteer features.
        return const VolunteerShell();
      }

      if (status == 'rejected') {
        // Rejected Volunteers are shown the rejection screen
        // together with the reason provided by the Admin.
        return VolunteerRejectedScreen(
          rejectionReason: rejectionReason,
        );
      }

      // Pending applications remain on the waiting screen.
      // This also acts as a safe fallback if the application
      // status could not be found.
      return const VolunteerPendingScreen();
    }

    if (role == 'admin') {
      // Admin accounts are routed directly to the Admin dashboard.
      return const AdminDashboardScreen();
    }

    // If the account does not have a saved role,
    // allow the user to choose one.
    return const ChooseRoleScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getDestination(),
      builder: (context, snapshot) {
        // Show a loading indicator while the role and application
        // information are being retrieved from Supabase.
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Display the correct screen after checking the account.
        return snapshot.data ?? const ChooseRoleScreen();
      },
    );
  }
}
