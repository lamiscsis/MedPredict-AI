import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../configurations/theme/app_colors.dart';
import '../../configurations/theme/app_typography.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../../services/auth_exceptions.dart';
import '../../models/enums/user_role.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authService = ref.read(authServiceProvider);
      try {
        final user = await authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          if (user != null) {
            if (user.role == UserRole.ADMIN) {
              context.go('/admin_dashboard');
            } else {
              context.go('/patient_dashboard');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login failed')),
            );
          }
        }
      } on EmailNotVerifiedException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showEmailNotVerifiedDialog(e.email);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          final errorMessage = AuthErrorMapper.mapFirebaseAuthError(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white,
                      size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _showEmailNotVerifiedDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_unread_rounded,
              color: AppColors.accent, size: 40),
        ),
        title: Text(
          'Email Not Verified',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your email address has not been verified yet. Please check your inbox and click the verification link.',
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                email,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _resendVerificationFromLogin(email);
            },
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Resend Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerificationFromLogin(String email) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendVerificationForEmail(
        email,
        _passwordController.text,
      );
      if (mounted) {
        // Navigate to verification screen
        context.go('/email_verification', extra: email);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to resend verification: ${AuthErrorMapper.mapFirebaseAuthError(e)}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    // Pre-fill with current email if available
    resetEmailController.text = _emailController.text.trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: AppColors.primary, size: 40),
        ),
        title: Text(
          'Reset Password',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid email address')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                final authService = ref.read(authServiceProvider);
                await authService.sendPasswordResetEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white,
                              size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                              child:
                                  Text('Password reset email sent! Check your inbox.')),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(AuthErrorMapper.mapFirebaseAuthError(e)),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send Reset Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/medpredict_logo.png',
                  ),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  label: "Email",
                  hint: "Enter your email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textSecondary),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter your email';
                    if (!value.contains('@'))
                      return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: "Password",
                  hint: "Enter your password",
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      "Forgot Password?",
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: "Login",
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        "Sign Up",
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

