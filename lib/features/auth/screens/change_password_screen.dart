import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../controllers/auth_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).changePassword(
          _passwordController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password updated successfully! Welcome to the Academy.',
            style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.darkCard,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Password', style: AppTheme.heading2),
        automaticallyImplyLeading: false, // Prevent returning back
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.accentLime.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentLime.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.vpn_key_outlined,
                      size: 32,
                      color: AppTheme.accentLime,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  Text(
                    'First Time Sign-In',
                    textAlign: TextAlign.center,
                    style: AppTheme.heading2,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'For security, you must update your password before you can use the application.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body2.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space14),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppTheme.radius14),
                        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: AppTheme.caption.copyWith(color: AppTheme.errorRed),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                  ],
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: AppTheme.body1,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: AppTheme.body1,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Update Password', style: AppTheme.buttonText.copyWith(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
