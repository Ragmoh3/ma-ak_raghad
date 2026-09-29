import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/maak_logo.dart';
import '../patient/patient_shell.dart';

const List<String> kChronicConditions = [
  'Diabetes',
  'Hypertension',
  'Asthma',
  'Chronic kidney disease',
  'Rheumatoid arthritis',
  'Other',
];

const List<String> kLanguages = ['Arabic', 'English', 'French'];

class HelpSeekerRegistrationScreen extends StatefulWidget {
  const HelpSeekerRegistrationScreen({super.key});

  @override
  State<HelpSeekerRegistrationScreen> createState() =>
      _HelpSeekerRegistrationScreenState();
}

class _HelpSeekerRegistrationScreenState
    extends State<HelpSeekerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otherConditionController = TextEditingController();

  String? _condition;
  String? _language;
  bool _obscurePassword = true;
  bool _loading = false;

  bool get _isOtherCondition => _condition == 'Other';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1) Create the authentication account.
      await SupabaseService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2) Save the user's role and full name in the profiles table.
      await SupabaseService.setRole(
        'help_seeker',
        fullName: _nameController.text.trim(),
      );

      // 3) Save the Help Seeker specific information.
      await SupabaseService.submitHelpSeekerRegistration(
        chronicCondition: _isOtherCondition
            ? _otherConditionController.text.trim()
            : _condition!,
        preferredLanguage: _language!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PatientShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
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
                  'Help Seeker Registration',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Tell us a little about yourself',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                  ),
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
                  validator: (v) =>
                      (v == null || !v.contains('@'))
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
                      onPressed: () {
                        setState(
                          () => _obscurePassword = !_obscurePassword,
                        );
                      },
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6)
                          ? 'At least 6 characters'
                          : null,
                ),

                const SizedBox(height: 20),

                const _FieldLabel('Chronic condition'),

                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: const InputDecoration(
                    hintText: 'Select your condition',
                  ),
                  items: kChronicConditions
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _condition = v);
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),

                if (_isOtherCondition) ...[
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _otherConditionController,
                    decoration: const InputDecoration(
                      hintText: 'Please specify your condition',
                    ),
                    validator: (v) =>
                        (_isOtherCondition &&
                                (v == null || v.trim().isEmpty))
                            ? 'Please specify your condition'
                            : null,
                  ),
                ],

                const SizedBox(height: 16),

                const _FieldLabel('Preferred language'),

                DropdownButtonFormField<String>(
                  initialValue: _language,
                  decoration: const InputDecoration(
                    hintText: 'Select language',
                  ),
                  items: kLanguages
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(l),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _language = v);
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                const _FieldLabel('Short description (optional)'),

                TextFormField(
                  controller: _descriptionController,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        "Tell us a bit about your experience or what kind of support you're looking for...",
                  ),
                ),

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _loading ? null : _createAccount,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create account'),
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
