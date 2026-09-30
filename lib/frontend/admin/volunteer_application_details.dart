import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../backend/services/supabase_service.dart';

/// Full detail view of one Volunteer application.
///
/// The Admin can:
/// - review the applicant's information
/// - open the uploaded verification document
/// - approve a pending application
/// - reject a pending application with a required reason
///
/// Approve/Reject buttons only appear while the application
/// is still pending.
class VolunteerApplicationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> application;

  const VolunteerApplicationDetailsScreen({
    super.key,
    required this.application,
  });

  @override
  State<VolunteerApplicationDetailsScreen> createState() =>
      _VolunteerApplicationDetailsScreenState();
}

class _VolunteerApplicationDetailsScreenState
    extends State<VolunteerApplicationDetailsScreen> {
  // Prevents multiple Admin actions while a decision
  // is currently being saved to Supabase.
  bool _loading = false;

  /// Current application status stored in Supabase.
  String get _status =>
      widget.application['status']?.toString() ??
      'pending_review';

  /// Decisions should only be available for applications
  /// that have not already been reviewed.
  bool get _isPending => _status == 'pending_review';

  /// Shows an error message at the bottom of the screen.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Opens the verification document uploaded by the Volunteer.
  ///
  /// This allows the Admin to actually inspect the document
  /// instead of only seeing its URL as plain text.
  Future<void> _openVerificationDocument(
    String documentUrl,
  ) async {
    final uri = Uri.tryParse(documentUrl);

    // Protect against an empty or malformed URL.
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      if (!mounted) return;

      _showError(
        'The verification document link is invalid.',
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    // Tell the Admin if the device could not open the file/link.
    if (!opened && mounted) {
      _showError(
        'Could not open the verification document.',
      );
    }
  }

  /// Approves the selected Volunteer application.
  Future<void> _approveApplication() async {
    final userId =
        widget.application['user_id']?.toString();

    // This should normally never happen, but silently doing
    // nothing would make the Approve button appear broken.
    if (userId == null || userId.isEmpty) {
      _showError(
        'Could not identify this Volunteer application.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await SupabaseService.approveVolunteerApplication(
        userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Volunteer application approved.',
          ),
        ),
      );

      // Return to the applications list.
      // The list reloads when this screen closes.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not approve application: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

 /// Opens the rejection dialog.
///
/// A rejection reason is required because the Volunteer
/// needs to know why the application was rejected and what
/// should be corrected before resubmission.
Future<void> _showRejectDialog() async {
  final reason = await showDialog<String>(
    context: context,

    // The Admin must explicitly Cancel or Reject.
    barrierDismissible: false,

    builder: (dialogContext) {
      String rejectionReason = '';

      return AlertDialog(
        title: const Text('Reject Application'),

        content: TextField(
          maxLines: 4,

          // Store the entered text directly instead of using
          // a TextEditingController inside the temporary dialog.
          onChanged: (value) {
            rejectionReason = value;
          },

          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText:
                'Enter the reason for rejecting this application',
            alignLabelWithHint: true,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),

          FilledButton(
            onPressed: () {
              final reason = rejectionReason.trim();

              // A rejection reason is required.
              if (reason.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a rejection reason.',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop(reason);
            },
            child: const Text('Reject'),
          ),
        ],
      );
    },
  );

  // Cancel means no decision was made.
  if (reason == null || reason.isEmpty) return;

  await _rejectApplication(reason);
}

  /// Rejects the selected Volunteer application and stores
  /// the Admin's reason in Supabase.
  Future<void> _rejectApplication(
    String reason,
  ) async {
    final userId =
        widget.application['user_id']?.toString();

    if (userId == null || userId.isEmpty) {
      _showError(
        'Could not identify this Volunteer application.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await SupabaseService.rejectVolunteerApplication(
        userId: userId,
        reason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Volunteer application rejected.',
          ),
        ),
      );

      // Return to the list so it can reload the
      // application's new status.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not reject application: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Converts database values into labels shown to the Admin.
  String _formatStatus(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending_review':
        return 'Pending';
      default:
        // Do not incorrectly call an unexpected database
        // value "Pending".
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;

    // The name comes from the related `profiles` record
    // included by getVolunteerApplications().
    final profile =
        application['profiles']
            as Map<String, dynamic>?;

    final name =
        profile?['full_name']?.toString() ??
        'Unknown Volunteer';

    final condition =
        application['condition_experience']
                ?.toString() ??
            'Not specified';

    final language =
        application['preferred_language']
                ?.toString() ??
            'Not specified';

    final experience =
        application['experience_description']
                ?.toString() ??
            'Not provided';

    final documentUrl =
        application['verification_document_url']
            ?.toString();

    final rejectionReason =
        application['rejection_reason']
            ?.toString();

    final hasDocument =
        documentUrl != null &&
        documentUrl.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Application Details',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              _DetailItem(
                title: 'Name',
                value: name,
              ),
              _DetailItem(
                title: 'Condition Experience',
                value: condition,
              ),
              _DetailItem(
                title: 'Preferred Language',
                value: language,
              ),
              _DetailItem(
                title: 'Experience Description',
                value: experience,
              ),

              // The verification document is actionable.
              // Admin can open it instead of manually copying
              // a long URL from the screen.
              const Text(
                'Verification Document',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),

              if (hasDocument)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openVerificationDocument(
                      documentUrl,
                    ),
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: const Text(
                      'Open Document',
                    ),
                  ),
                )
              else
                const Text(
                  'No document uploaded',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 20),

              _DetailItem(
                title: 'Application Status',
                value: _formatStatus(_status),
              ),

              // Show the saved reason when viewing a previously
              // rejected application.
              if (_status == 'rejected' &&
                  rejectionReason != null &&
                  rejectionReason.isNotEmpty)
                _DetailItem(
                  title: 'Rejection Reason',
                  value: rejectionReason,
                ),

              const SizedBox(height: 24),

              // Decisions can only be made while pending.
              if (_isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : _showRejectDialog,
                        child: const Text(
                          'Reject',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading
                            ? null
                            : _approveApplication,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Approve',
                              ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable layout for displaying one application field.
///
/// Each field uses the same label-above-value layout so the
/// application remains easy to scan.
class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
