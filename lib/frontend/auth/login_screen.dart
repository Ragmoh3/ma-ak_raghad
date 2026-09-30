import 'package:flutter/material.dart';
import '../../backend/services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/maak_logo.dart';
import 'reset_password_screen.dart';
import 'choose_role_screen.dart';
import '../patient/patient_shell.dart';
import '../volunteer/volunteer_shell.dart';
import '../volunteer/volunteer_pending_screen.dart';
import '../volunteer/volunteer_rejected_screen.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Sign in using the same login screen for all account types.
      await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Get the saved role to determine which part of the application
      // the signed-in user should be allowed to access.
      final role = await SupabaseService.getMyRole();

      if (!mounted) return;

      Widget destination;

      if (role == 'help_seeker') {
        // Support Seekers can enter their main area directly
        // after a successful login.
        destination = const PatientShell();
      } else if (role == 'volunteer') {
        // Volunteers require an additional application check.
        // This returns both the application status and the rejection
        // reason when one has been provided by the Admin.
        final application =
            await SupabaseService.getMyVolunteerApplication();

        if (!mounted) return;

        final status = application?['status'] as String?;
        final rejectionReason =
            application?['rejection_reason'] as String? ?? '';

        if (status == 'approved') {
          // Only approved Volunteers can access Volunteer features.
          destination = const VolunteerShell();
        } else if (status == 'rejected') {
          // Rejected Volunteers are shown the Admin's rejection reason
          // and can choose to submit a new application.
          destination = VolunteerRejectedScreen(
            rejectionReason: rejectionReason,
          );
        } else {
          // Pending applications remain on the waiting screen.
          // This also acts as a safe fallback if no application
          // status is available.
          destination = const VolunteerPendingScreen();
        }
      } else if (role == 'admin') {
        // Admin accounts are routed to the Admin dashboard.
        destination = const AdminDashboardScreen();
      } else {
        // No valid role was found for this account, send the user back to
        // the login screen to sign in again.
        destination = const LoginScreen();
      }

      // Replace the login screen with the correct destination.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => destination,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تسجيل الدخول: ${e.toString()}'),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),

                              const MaakLogo(),

                              const SizedBox(height: 28),

                              const Text(
                                'Welcome back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                "Log in to continue to Ma'ak",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),

                              const SizedBox(height: 28),

                              TextFormField(
                                controller: _emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'Email address',
                                  prefixIcon:
                                      Icon(Icons.mail_outline),
                                ),
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'Enter a valid email'
                                        : null,
                              ),

                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword =
                                          !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Enter your password'
                                        : null,
                              ),

                              const SizedBox(height: 20),

                              ElevatedButton(
                                onPressed: _loading ? null : _login,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                            CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Log in'),
                              ),

                              const SizedBox(height: 12),

                              Center(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ResetPasswordScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'Forgot your password?',
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChooseRoleScreen(),
                                  ),
                                ),
                                child:
                                    const Text('Create a new account'),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      const MaakBottomHills(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
