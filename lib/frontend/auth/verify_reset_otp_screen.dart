import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/services/supabase_service.dart';
import '../widgets/maak_logo.dart';
import 'new_password_screen.dart';

class VerifyResetOtpScreen extends StatefulWidget {
  final String email;
  const VerifyResetOtpScreen({super.key, required this.email});
  @override
  State<VerifyResetOtpScreen> createState() => _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends State<VerifyResetOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _busy = false;
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() { super.initState(); _startCooldown(); }

  void _startCooldown() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await SupabaseService.verifyPasswordResetOtp(widget.email, _code.text);
      if (!mounted) {
        await SupabaseService.endPasswordRecovery();
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const NewPasswordScreen()));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid or expired code. Try again or request a new code.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await SupabaseService.sendPasswordReset(widget.email);
      if (!mounted) return;
      _code.clear();
      setState(_startCooldown);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code has been requested.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send code. Please try again later.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  void dispose() { _timer?.cancel(); _code.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(
        key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const MaakLogo(), const SizedBox(height: 24),
          Text('Enter the verification code sent to ${widget.email}', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextFormField(controller: _code, enabled: !_busy, keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
            decoration: const InputDecoration(labelText: 'Verification code'),
            validator: (v) => RegExp(r'^\d{6,8}$').hasMatch(v ?? '') ? null : 'Enter the code from your email'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _busy ? null : _verify, child: Text(_busy ? 'Please wait...' : 'Verify code')),
          TextButton(onPressed: _busy || _seconds > 0 ? null : _resend,
            child: Text(_seconds > 0 ? 'Resend code in ${_seconds}s' : 'Resend code')),
        ]),
      )),
    ),
  );
}
