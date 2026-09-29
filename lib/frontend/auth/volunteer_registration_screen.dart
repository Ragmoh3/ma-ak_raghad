import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/maak_logo.dart';
import '../volunteer/volunteer_pending_screen.dart';
import 'help_seeker_registration_screen.dart'
    show kChronicConditions, kLanguages;

class VolunteerRegistrationScreen extends StatefulWidget {
  const VolunteerRegistrationScreen({super.key});

  @override
  State<VolunteerRegistrationScreen> createState() =>
      _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState
    extends State<VolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _experienceController = TextEditingController();
  final _otherConditionController = TextEditingController();

  String? _condition;
  String? _language;
  PlatformFile? _pickedFile;
  bool _obscurePassword = true;
  bool _loading = false;

  bool get _isOtherCondition => _condition == 'Other';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _experienceController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1) Create the auth account itself (name/email/password) — this
      //    screen doubles as the sign-up step for the Volunteer path.
      await SupabaseService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2) Record the chosen role.
      await SupabaseService.setRole('volunteer');

      String? documentUrl;

      if (_pickedFile != null && _pickedFile!.bytes != null) {
        documentUrl = await SupabaseService.uploadVerificationDocument(
          fileBytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
        );
      }

      await SupabaseService.submitVolunteerRegistration(
        conditionExperience: _isOtherCondition
            ? _otherConditionController.text.trim()
            : _condition!,
        preferredLanguage: _language!,
        experienceDescription: _experienceController.text.trim(),
        verificationDocumentUrl: documentUrl,
      );

      if (!mounted) return;

      // After submitting the application, the Volunteer is redirected
      // to the pending screen and must wait for Admin approval before
      // accessing Volunteer features.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const VolunteerPendingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Volunteer Registration',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Share your experience and help others',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),

                const SizedBox(height: 24),

                const _FieldLabel('Full name'),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                const _FieldLabel('Email address'),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),

                const SizedBox(height: 16),

                const _FieldLabel('Password'),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),

                const SizedBox(height: 20),

                const _FieldLabel('Chronic condition experience'),

                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration:
                      const InputDecoration(hintText: 'Select condition'),
                  items: kChronicConditions
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _condition = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),

                if (_isOtherCondition) ...[
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _otherConditionController,
                    decoration: const InputDecoration(
                      hintText: 'Please specify the condition',
                    ),
                    validator: (v) =>
                        (_isOtherCondition &&
                                (v == null || v.trim().isEmpty))
                            ? 'Please specify the condition'
                            : null,
                  ),
                ],

                const SizedBox(height: 16),

                const _FieldLabel('Preferred language'),

                DropdownButtonFormField<String>(
                  initialValue: _language,
                  decoration:
                      const InputDecoration(hintText: 'Select language'),
                  items: kLanguages
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(l),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _language = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                const _FieldLabel('Experience description'),

                TextFormField(
                  controller: _experienceController,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Tell us about your lived experience and how you can support others...',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                const _FieldLabel('Verification document (optional)'),

                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
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
                          _pickedFile?.name ?? 'Upload file',
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
                      : const Text('Submit application'),
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
