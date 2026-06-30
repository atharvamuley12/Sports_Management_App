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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await authNotifier.signIn(email, password);
    if (success && mounted) {
      _showSuccessSnackBar('Welcome back! Signed in successfully.');
    }
  }

  void _showSuccessSnackBar(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.body2.copyWith(
                  color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = _selectedRole == 'admin';
    final roleColor = isAdmin
        ? (isDark ? AppTheme.accentLime : AppTheme.accentLimeDark)
        : (isDark ? AppTheme.accentTeal : AppTheme.accentTealDark);

    return Scaffold(
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgAnimController, roleColor: roleColor),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space20,
                  vertical: AppTheme.space32,
                ),
                child: SlideTransition(
                  position: _formSlideAnim,
                  child: FadeTransition(
                    opacity: _formFadeAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        children: [
                          _buildHeader(roleColor),
                          const SizedBox(height: AppTheme.space32),
                          _buildFormCard(authState, roleColor),
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
            width: 80,
            height: 80,
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
                color: roleColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _selectedRole == 'admin'
                  ? Icons.shield_outlined
                  : Icons.sports_soccer_outlined,
              size: 36,
              color: roleColor,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space20),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimaryLight, roleColor.withValues(alpha: 0.8)],
          ).createShader(bounds),
          child: Text(
            'Sports Academy',
            style: AppTheme.heading1.copyWith(
              fontSize: 32,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimaryLight,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Welcome back! Sign in to continue',
          textAlign: TextAlign.center,
          style: AppTheme.body2.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthStateData authState, Color roleColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radius24),
        border: Border.all(
          color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
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
            _buildRoleSwitcher(roleColor),
            const SizedBox(height: AppTheme.space24),
            if (authState.errorMessage != null)
              _buildErrorBanner(authState.errorMessage!),
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
            const SizedBox(height: AppTheme.space16),
            _buildPasswordField(),
            const SizedBox(height: AppTheme.space8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space4),
                  foregroundColor: roleColor,
                ),
                child: Text(
                  'Forgot password?',
                  style: AppTheme.caption.copyWith(
                    color: roleColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space20),
            _buildSubmitButton(authState, roleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher(Color roleColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 50,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radius14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1),
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
          const SizedBox(width: 3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppTheme.durationNormal,
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
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
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
                  size: 15,
                  color: isSelected ? (isDark ? Colors.black : Colors.white) : unselectedColor,
                ),
                const SizedBox(width: AppTheme.space6),
                Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : unselectedColor,
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
      style: AppTheme.body1,
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
      style: AppTheme.body1,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: AnimatedSwitcher(
            duration: AppTheme.durationFast,
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
        return null;
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space14, horizontal: AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radius14),
          border: Border.all(
            color: AppTheme.errorRed.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radius8),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppTheme.errorRed, size: 18),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: SelectableText(
                message,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.errorRed,
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
      duration: AppTheme.durationNormal,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius16),
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
                  color: roleColor.withValues(alpha: 0.3),
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
            borderRadius: BorderRadius.circular(AppTheme.radius16),
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
                  const Icon(Icons.login_rounded, size: 20, color: Colors.black),
                  const SizedBox(width: AppTheme.space10),
                  Text(
                    'Sign In',
                    style: AppTheme.buttonText.copyWith(color: Colors.black),
                  ),
                ],
              ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius10),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: AppTheme.accentTeal, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Text('Reset Password', style: AppTheme.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a password reset link.',
              style: AppTheme.body2.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppTheme.space16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTheme.body1,
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
                        content: Text(
                          'Password reset email sent! Check your inbox.',
                          style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
                        ),
                        backgroundColor: AppTheme.darkCard,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BgPainter(
            progress: controller.value,
            accentColor: roleColor,
            isDark: isDark,
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
  final bool isDark;

  _BgPainter({required this.progress, required this.accentColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamic background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = isDark ? AppTheme.darkBg : AppTheme.lightBg,
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
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.012)
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
