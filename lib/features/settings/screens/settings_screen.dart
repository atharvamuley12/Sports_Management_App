import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/utils/seed_helper.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/utils/error_handler.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSeeding = false;

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      await SeedHelper.seedTestData(supabase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Database successfully seeded!',
                  style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
                ),
              ],
            ),
            backgroundColor: AppTheme.darkCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to seed database', e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Text('Sign Out', style: AppTheme.heading3),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: AppTheme.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            _buildProfileCard(profile),
            const SizedBox(height: AppTheme.space24),

            // Appearance Preferences
            const AppSectionHeader(
              title: 'APPEARANCE',
              icon: Icons.palette_rounded,
            ),
            const SizedBox(height: AppTheme.space12),
            _buildThemeToggleTile(),
            const SizedBox(height: AppTheme.space24),

            // General Actions
            const AppSectionHeader(
              title: 'SECURITY ACTIONS',
              icon: Icons.security_rounded,
            ),
            const SizedBox(height: AppTheme.space12),
            _buildActionTile(
              icon: Icons.vpn_key_rounded,
              title: 'Change Password',
              subtitle: 'Update your login credentials',
              color: AppTheme.accentTeal,
              onTap: () {
                context.push('/change-password');
              },
            ),
            const SizedBox(height: AppTheme.space12),
            _buildActionTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Disconnect from your account',
              color: AppTheme.errorRed,
              onTap: () => _showLogoutDialog(context),
            ),
            const SizedBox(height: AppTheme.space24),

            // Admin Tools Section
            if (profile.isAdmin) ...[
              const AppSectionHeader(
                title: 'ADMINISTRATION & DEBUG TOOLS',
                icon: Icons.admin_panel_settings_rounded,
              ),
              const SizedBox(height: AppTheme.space12),
              _buildActionTile(
                icon: Icons.storage_rounded,
                title: 'Seed Database with Test Data',
                subtitle: 'Creates mock batches, active students, attendance history, and monthly payment records.',
                color: AppTheme.accentLime,
                onTap: _isSeeding ? null : _seedDatabase,
                trailingWidget: _isSeeding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        ref.read(themeModeProvider.notifier).state =
            isDark ? ThemeMode.light : ThemeMode.dark;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.accentLime : AppTheme.accentTeal).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radius10),
                border: Border.all(
                  color: (isDark ? AppTheme.accentLime : AppTheme.accentTeal).withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? AppTheme.accentLime : AppTheme.accentTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    isDark ? 'Dark Mode Active' : 'Light Mode Active',
                    style: AppTheme.caption.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              activeThumbColor: AppTheme.accentLime,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).state =
                    val ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic profile) {
    final isLimes = profile.isAdmin;
    final roleColor = isLimes ? AppTheme.accentLime : AppTheme.accentTeal;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space14),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withValues(alpha: 0.15)),
            ),
            child: Icon(
              profile.isAdmin ? Icons.shield_rounded : Icons.sports_rounded,
              color: roleColor,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  ref.read(authControllerProvider).user?.email ?? 'No email associated',
                  style: AppTheme.caption,
                ),
                const SizedBox(height: AppTheme.space10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10, vertical: AppTheme.space4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Text(
                    profile.role.toUpperCase(),
                    style: AppTheme.overline.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: roleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.space8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radius10),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: AppTheme.subtitle2),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppTheme.space4),
          child: Text(subtitle, style: AppTheme.caption.copyWith(height: 1.4)),
        ),
        trailing: trailingWidget ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
