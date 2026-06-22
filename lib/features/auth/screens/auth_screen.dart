import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/theme/theme.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _isSignUp = false;
  String _selectedRole = 'admin';
  bool _obscurePassword = true;

  // Animation controllers
  late AnimationController _bgAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _formFadeAnim;
  late Animation<Offset> _formSlideAnim;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _formFadeAnim = CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeOutCubic,
    );

    _formSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeOutCubic,
    ));

    _formAnimController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bgAnimController.dispose();
    _formAnimController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    ref.read(authControllerProvider.notifier).clearError();
    _formAnimController.reset();
    setState(() {
      _isSignUp = !_isSignUp;
    });
    _formAnimController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success = false;
    if (_isSignUp) {
      final name = _fullNameController.text.trim();
      final phone = _phoneController.text.trim();

      success = await authNotifier.signUp(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
        role: _selectedRole,
      );

      if (success && mounted) {
        final currentUser = supabase.Supabase.instance.client.auth.currentUser;
        if (currentUser == null) {
          _showVerifyEmailDialog();
        } else {
          _showSuccessSnackBar(
            'Welcome! Registered successfully as ${_selectedRole == 'admin' ? 'Admin' : 'Coach'}.',
          );
        }
      }
    } else {
      success = await authNotifier.signIn(email, password);
      if (success && mounted) {
        _showSuccessSnackBar('Welcome back! Signed in successfully.');
      }
    }
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: AppTheme.accentTeal, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Verify Your Email'),
          ],
        ),
        content: const Text(
          'A confirmation link has been sent to your email address. '
          'Please verify it to complete your registration.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isSignUp = false);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = _selectedRole == 'admin';
    final roleColor = isAdmin ? AppTheme.accentLime : AppTheme.accentTeal;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _AnimatedBackground(controller: _bgAnimController, roleColor: roleColor),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width > 600 ? screenSize.width * 0.15 : 20,
                  vertical: 32,
                ),
                child: SlideTransition(
                  position: _formSlideAnim,
                  child: FadeTransition(
                    opacity: _formFadeAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          _buildHeader(roleColor),
                          const SizedBox(height: 32),
                          _buildFormCard(authState, roleColor),
                          const SizedBox(height: 20),
                          _buildToggleSection(roleColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color roleColor) {
    return Column(
      children: [
        // Animated logo
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  roleColor.withValues(alpha: 0.2),
                  roleColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: roleColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _selectedRole == 'admin'
                  ? Icons.shield_outlined
                  : Icons.sports_soccer_outlined,
              size: 40,
              color: roleColor,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title with gradient text effect
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, roleColor.withValues(alpha: 0.8)],
          ).createShader(bounds),
          child: const Text(
            'Sports Academy',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isSignUp
                ? 'Create your account to get started'
                : 'Welcome back! Sign in to continue',
            key: ValueKey(_isSignUp),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthStateData authState, Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: roleColor.withValues(alpha: 0.03),
            blurRadius: 60,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role switcher
            _buildRoleSwitcher(roleColor),
            const SizedBox(height: 24),

            // Error display
            if (authState.errorMessage != null)
              _buildErrorBanner(authState.errorMessage!),

            // Dynamic form fields
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  if (_isSignUp) ...[
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (_isSignUp && (value == null || value.isEmpty)) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (_isSignUp && (value == null || value.isEmpty)) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Forgot password link (sign-in only)
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Show forgot password dialog
                    _showForgotPasswordDialog();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    foregroundColor: roleColor,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 13,
                      color: roleColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Submit button
            _buildSubmitButton(authState, roleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher(Color roleColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
      ),
      child: Row(
        children: [
          _buildRoleTab(
            label: 'Admin Portal',
            icon: Icons.shield_outlined,
            isSelected: _selectedRole == 'admin',
            color: AppTheme.accentLime,
            onTap: () => setState(() => _selectedRole = 'admin'),
          ),
          const SizedBox(width: 4),
          _buildRoleTab(
            label: 'Coach Portal',
            icon: Icons.sports_outlined,
            isSelected: _selectedRole == 'coach',
            color: AppTheme.accentTeal,
            onTap: () => setState(() => _selectedRole = 'coach'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.black : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.black : AppTheme.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey(_obscurePassword),
              size: 20,
              color: AppTheme.textMuted,
            ),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (_isSignUp && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.errorRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppTheme.errorRed, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                message,
                style: const TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AuthStateData authState, Color roleColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: authState.isLoading
            ? null
            : LinearGradient(
                colors: [roleColor, roleColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: authState.isLoading
            ? null
            : [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: authState.isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: authState.isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: roleColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSignUp
                        ? Icons.person_add_alt_1_rounded
                        : Icons.login_rounded,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isSignUp
                        ? 'Create ${_selectedRole == 'admin' ? 'Admin' : 'Coach'} Account'
                        : 'Sign In',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleSection(Color roleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account?' : "Don't have an account?",
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _toggleMode,
          style: TextButton.styleFrom(
            foregroundColor: roleColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppTheme.accentTeal, size: 24),
            SizedBox(width: 12),
            Text('Reset Password', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a password reset link.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await supabase.Supabase.instance.client.auth
                      .resetPasswordForEmail(email);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Password reset email sent! Check your inbox.',
                        ),
                        backgroundColor: AppTheme.darkCard,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}

/// Animated floating orbs background
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Color roleColor;

  const _AnimatedBackground({
    required this.controller,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BgPainter(
            progress: controller.value,
            accentColor: roleColor,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _BgPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.darkBg,
    );

    // Animated gradient orbs
    final orbs = [
      _Orb(
        x: size.width * (0.15 + 0.1 * math.sin(progress * math.pi * 2)),
        y: size.height * (0.2 + 0.08 * math.cos(progress * math.pi * 2)),
        radius: size.width * 0.45,
        color: accentColor.withValues(alpha: 0.04),
      ),
      _Orb(
        x: size.width * (0.85 - 0.12 * math.cos(progress * math.pi * 2)),
        y: size.height * (0.65 + 0.1 * math.sin(progress * math.pi * 2)),
        radius: size.width * 0.5,
        color: AppTheme.accentPurple.withValues(alpha: 0.03),
      ),
      _Orb(
        x: size.width * (0.5 + 0.15 * math.sin(progress * math.pi * 2 + 1)),
        y: size.height * (0.85 - 0.05 * math.cos(progress * math.pi * 2)),
        radius: size.width * 0.35,
        color: AppTheme.accentTeal.withValues(alpha: 0.03),
      ),
    ];

    for (final orb in orbs) {
      canvas.drawCircle(
        Offset(orb.x, orb.y),
        orb.radius,
        Paint()
          ..color = orb.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
      );
    }

    // Subtle grid pattern
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
}

class _Orb {
  final double x, y, radius;
  final Color color;
  _Orb({required this.x, required this.y, required this.radius, required this.color});
}
