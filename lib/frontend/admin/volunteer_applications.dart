import 'package:flutter/material.dart';

import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'volunteer_application_details.dart';

/// Shows all Volunteer applications for the Admin.
///
/// Each list item displays the applicant's name, chronic-condition
/// experience, and current application status. The Admin can open
/// an application to review its full details and approve or reject it.
class VolunteerApplicationsScreen extends StatefulWidget {
  const VolunteerApplicationsScreen({super.key});

  @override
  State<VolunteerApplicationsScreen> createState() =>
      _VolunteerApplicationsScreenState();
}

class _VolunteerApplicationsScreenState
    extends State<VolunteerApplicationsScreen> {
  // A Future that resolves to the list of applications.
  //
  // It is recreated whenever fresh data is needed:
  // - when the screen first opens
  // - when the Admin pulls to refresh
  // - when the Admin returns after approving/rejecting an application
  late Future<List<Map<String, dynamic>>> _applications;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  /// Requests the latest Volunteer applications from Supabase.
  void _loadApplications() {
    _applications =
        SupabaseService.getVolunteerApplications();
  }

  /// Reloads the applications when the Admin pulls down
  /// on the list to refresh it.
  Future<void> _refreshApplications() async {
    setState(() => _loadApplications());
    await _applications;
  }

  /// Converts the database status values into text that is
  /// easier for the Admin to read.
  String _formatStatus(String? status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending_review':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Applications'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applications,
        builder: (context, snapshot) {
          // Show a loading indicator while Supabase is
          // retrieving the applications.
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show the actual error if loading fails.
          // This is useful during development because it tells us
          // whether the problem came from Supabase, RLS, or the query.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load volunteer applications.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final applications = snapshot.data ?? [];

          // The query worked, but no Volunteer has submitted
          // an application yet.
          if (applications.isEmpty) {
            return const Center(
              child: Text(
                'No volunteer applications yet.',
                style: TextStyle(
                  color: AppColors.textMuted,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshApplications,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: applications.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final application = applications[index];

                final status = _formatStatus(
                  application['status']?.toString(),
                );

                final condition =
                    application['condition_experience']
                            ?.toString() ??
                        'Not specified';

                // The application comes from `volunteer_profiles`,
                // but the applicant's name comes from the related
                // `profiles` row returned by our Supabase query.
                final profile =
                    application['profiles']
                        as Map<String, dynamic>?;

                final name =
                    profile?['full_name']?.toString() ??
                        'Unknown Volunteer';

                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),

                    // Previously the condition was used as the title.
                    // The applicant's actual name is more useful here.
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Keep the condition visible underneath the name,
                    // together with the current application status.
                    subtitle: Padding(
                      padding:
                          const EdgeInsets.only(top: 6),
                      child: Text(
                        '$condition\nStatus: $status',
                      ),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right),
                    onTap: () async {
                      // Wait until the Admin closes the details screen.
                      // They may have approved or rejected the application.
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              VolunteerApplicationDetailsScreen(
                            application: application,
                          ),
                        ),
                      );

                      // Reload after returning so any new approval or
                      // rejection status appears immediately.
                      if (mounted) {
                        setState(
                          () => _loadApplications(),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
