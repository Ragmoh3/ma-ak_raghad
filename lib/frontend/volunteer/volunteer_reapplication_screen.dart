import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/maak_logo.dart';
import '../auth/help_seeker_registration_screen.dart'
    show kChronicConditions, kLanguages;
import 'volunteer_pending_screen.dart';

/// Allows a rejected Volunteer to update their application information
/// and submit a new application without creating a new account.
class VolunteerReapplicationScreen extends StatefulWidget {
  const VolunteerReapplicationScreen({super.key});

  @override
  State<VolunteerReapplicationScreen> createState() =>
      _VolunteerReapplicationScreenState();
}

class _VolunteerReapplicationScreenState
    extends State<VolunteerReapplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable application information.
  final _fullNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _otherConditionController = TextEditingController();

  String? _condition;
  String? _language;

  PlatformFile? _pickedFile;

  bool _loading = false;
  bool _loadingExistingData = true;

  bool get _isOtherCondition => _condition == 'Other';

  @override
  void initState() {
    super.initState();

    // Load the Volunteer's previous application information
    // so they can edit it instead of entering everything again.
    _loadExistingApplication();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _experienceController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }

  /// Loads the information from the Volunteer's previous application.
  Future<void> _loadExistingApplication() async {
    try {
      final data = await SupabaseService.loadProfileForEdit(
        role: 'volunteer',
      );

      if (!mounted) return;

      final savedFullName = data['full_name'] as String?;
      final savedCondition = data['condition'] as String?;
      final savedLanguage = data['preferred_language'] as String?;
      final savedExperience = data['experience'] as String?;

      setState(() {
        // Restore the Volunteer's current full name.
        _fullNameController.text = savedFullName ?? '';

        // If the saved condition exists in the predefined list,
        // select it normally.
        if (savedCondition != null &&
            kChronicConditions.contains(savedCondition)) {
          _condition = savedCondition;
        } else if (savedCondition != null &&
            savedCondition.trim().isNotEmpty) {
          // If the Volunteer previously entered a custom condition,
          // select "Other" and display the saved value.
          _condition = 'Other';
          _otherConditionController.text = savedCondition;
        }

        // Restore the previously selected language.
        if (savedLanguage != null &&
            kLanguages.contains(savedLanguage)) {
          _language = savedLanguage;
        }

        // Restore the previous experience description.
        _experienceController.text = savedExperience ?? '';

        _loadingExistingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingExistingData = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load the previous application: ${e.toString()}',
          ),
        ),
      );
    }
  }

  /// Lets the Volunteer select a new verification document.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  /// Resubmits the rejected Volunteer application.
  ///
  /// This does NOT create a new account.
  /// It updates the existing profile and volunteer application,
  /// then returns the application status to pending_review.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? documentUrl;

      // Upload a new verification document only if the Volunteer
      // selected a new file during reapplication.
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        documentUrl =
            await SupabaseService.uploadVerificationDocument(
          fileBytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
        );
      }

      // Update the Volunteer's name in the main profiles table.
      await SupabaseService.updateFullName(
        _fullNameController.text.trim(),
      );

      // Resubmit the EXISTING Volunteer application.
      //
      // This:
      // 1. Updates the application information.
      // 2. Changes status from rejected to pending_review.
      // 3. Clears the previous rejection reason.
      // 4. Keeps the previous verification document if no new
      //    document was uploaded.
      await SupabaseService.resubmitVolunteerApplication(
        conditionExperience: _isOtherCondition
            ? _otherConditionController.text.trim()
            : _condition!,
        preferredLanguage: _language!,
        experienceDescription:
            _experienceController.text.trim(),
        verificationDocumentUrl: documentUrl,
      );

      if (!mounted) return;

      // After successful resubmission, return the Volunteer
      // to the pending screen to wait for the Admin's new decision.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const VolunteerPendingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit the application: ${e.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while retrieving the previous
    // application information from Supabase.
    if (_loadingExistingData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MaakLogo(iconSize: 32),

                const SizedBox(height: 20),

                const Text(
                  'Submit New Application',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Update your information and submit your volunteer application again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                  ),
                ),

                const SizedBox(height: 24),

                // Full name is loaded from the existing profile
                // and can be corrected before resubmission.
                const _FieldLabel('Full name'),

                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Chronic condition experience.
                const _FieldLabel(
                  'Chronic condition experience',
                ),

                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: const InputDecoration(
                    hintText: 'Select condition',
                  ),
                  items: kChronicConditions
                      .map(
                        (condition) => DropdownMenuItem(
                          value: condition,
                          child: Text(condition),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _condition = value;

                      // Clear the custom condition if the Volunteer
                      // changes from "Other" to a predefined condition.
                      if (value != 'Other') {
                        _otherConditionController.clear();
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Required' : null,
                ),

                if (_isOtherCondition) ...[
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _otherConditionController,
                    decoration: const InputDecoration(
                      hintText: 'Please specify the condition',
                    ),
                    validator: (value) {
                      if (_isOtherCondition &&
                          (value == null ||
                              value.trim().isEmpty)) {
                        return 'Please specify the condition';
                      }

                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Preferred language.
                const _FieldLabel('Preferred language'),

                DropdownButtonFormField<String>(
                  initialValue: _language,
                  decoration: const InputDecoration(
                    hintText: 'Select language',
                  ),
                  items: kLanguages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _language = value);
                  },
                  validator: (value) =>
                      value == null ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                // The previous experience description is loaded
                // automatically and can be changed before resubmission.
                const _FieldLabel('Experience description'),

                TextFormField(
                  controller: _experienceController,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Tell us about your lived experience and how you can support others...',
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                ),

                const SizedBox(height: 16),

                // Uploading a new document is optional.
                // If no new file is selected, the previous verification
                // document remains stored in Supabase.
                const _FieldLabel(
                  'New verification document (optional)',
                ),

                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.fieldBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.upload_outlined,
                          color: AppColors.primaryNavy,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _pickedFile?.name ?? 'Upload new file',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),

                        const SizedBox(height: 2),

                        const Text(
                          'PDF, JPG or PNG',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Send the updated application back to the Admin
                // for another review.
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Resubmit Application'),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small reusable label used above the form fields.
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
