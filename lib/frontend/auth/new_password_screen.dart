import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import '../../backend/validation/password_policy.dart';
import '../widgets/maak_logo.dart';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});
  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  bool _passwordSaved = false;

  Future<void> _finish({bool save = false}) async {
    if (_busy) return;
    if (save && !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (save && !_passwordSaved) {
        await SupabaseService.setRecoveredPassword(_password.text);
        _passwordSaved = true;
      }
      await SupabaseService.endPasswordRecovery();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      if (_passwordSaved) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Log in with your new password.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        _passwordSaved ? 'Password updated. Please retry to return to login.' : 'Could not complete the request. Please try again.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  void dispose() { _password.dispose(); _confirmation.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvoked: (didPop) { if (!didPop && !_busy) _finish(); },
    child: Scaffold(
      appBar: AppBar(title: const Text('New password'), leading: IconButton(
        onPressed: _busy ? null : () => _finish(), icon: const Icon(Icons.arrow_back))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(
        key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const MaakLogo(), const SizedBox(height: 24),
          const Text('Use at least 8 characters, including an uppercase letter, a number and a symbol.'),
          const SizedBox(height: 20),
          TextFormField(controller: _password, enabled: !_busy && !_passwordSaved,
            obscureText: _hidden, autocorrect: false, enableSuggestions: false,
            autofillHints: const [AutofillHints.newPassword], validator: validateNewPassword,
            decoration: InputDecoration(labelText: 'New password', suffixIcon: IconButton(
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
          const SizedBox(height: 16),
          TextFormField(controller: _confirmation, enabled: !_busy && !_passwordSaved,
            obscureText: _hidden, autocorrect: false, enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Confirm new password'),
            validator: (v) => v == null || v.isEmpty ? 'Confirm your password'
              : v != _password.text ? 'Passwords do not match' : null),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _busy ? null : () => _finish(save: true),
            child: Text(_busy ? 'Please wait...' : _passwordSaved ? 'Return to login' : 'Save password')),
        ]),
      )),
    ),
  );
}
