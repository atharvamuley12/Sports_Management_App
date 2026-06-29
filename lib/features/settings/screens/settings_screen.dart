import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/supabase/supabase_client.dart';
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
      final profile = ref.read(authControllerProvider).profile!;

      // 1. Seed Batches
      final batch1 = await supabase.from('batches').insert({
        'name': 'Cricket Academy Junior',
        'sport': 'cricket',
        'coach_id': profile.isCoach ? profile.id : null,
        'capacity': 15,
        'days': ['Monday', 'Wednesday', 'Friday'],
        'start_time': '04:00 PM',
        'end_time': '05:30 PM',
      }).select().single();

      final batch2 = await supabase.from('batches').insert({
        'name': 'Football Elite Club',
        'sport': 'football',
        'coach_id': null,
        'capacity': 25,
        'days': ['Tuesday', 'Thursday', 'Saturday'],
        'start_time': '05:00 PM',
        'end_time': '06:30 PM',
      }).select().single();

      final b1Id = batch1['id'] as String;
      final b2Id = batch2['id'] as String;

      // 2. Seed Students
      final s1 = await supabase.from('students').insert({
        'name': 'John Doe',
        'age': 12,
        'sport': 'cricket',
        'status': 'active',
        'batch_id': b1Id,
        'parent_name': 'Robert Doe',
        'phone': '9876543210',
        'join_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      }).select().single();

      final s2 = await supabase.from('students').insert({
        'name': 'Jane Smith',
        'age': 14,
        'sport': 'cricket',
        'status': 'active',
        'batch_id': b1Id,
        'parent_name': 'Mary Smith',
        'phone': '9876543211',
        'join_date': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      }).select().single();

      await supabase.from('students').insert({
        'name': 'Alex Mercer',
        'age': 15,
        'sport': 'football',
        'status': 'active',
        'batch_id': b2Id,
        'parent_name': 'Ken Mercer',
        'phone': '9876543212',
        'join_date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      });

      final s1Id = s1['id'] as String;
      final s2Id = s2['id'] as String;

      // 3. Seed Attendance Logs
      await supabase.from('attendance').insert([
        {
          'student_id': s1Id,
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
          'status': 'present',
          'marked_by': profile.id,
        },
        {
          'student_id': s2Id,
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
          'status': 'absent',
          'marked_by': profile.id,
        },
        {
          'student_id': s1Id,
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
          'status': 'present',
          'marked_by': profile.id,
        },
        {
          'student_id': s2Id,
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
          'status': 'present',
          'marked_by': profile.id,
        },
      ]);

      // 4. Seed Payments
      await supabase.from('payments').insert([
        {
          'student_id': s1Id,
          'amount': 2500,
          'month': 6,
          'year': 2026,
          'mode': 'upi',
          'payment_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        },
        {
          'student_id': s2Id,
          'amount': 2500,
          'month': 6,
          'year': 2026,
          'mode': 'cash',
          'payment_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database successfully seeded with mock Batches, Students, Attendance & Payments!'),
            backgroundColor: AppTheme.successGreen,
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            _buildProfileCard(profile),
            const SizedBox(height: 24),

            // General Actions
            const Text(
              'Security Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              icon: Icons.vpn_key_rounded,
              title: 'Change Password',
              subtitle: 'Update your login credentials',
              color: AppTheme.accentTeal,
              onTap: () {
                context.push('/change-password');
              },
            ),
            const SizedBox(height: 24),

            // Admin Tools Section
            if (profile.isAdmin) ...[
              const Text(
                'Academy Administration & Debug Tools',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
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

  Widget _buildProfileCard(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: profile.isAdmin
                  ? AppTheme.accentLime.withValues(alpha: 0.15)
                  : AppTheme.accentTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              profile.isAdmin ? Icons.shield_rounded : Icons.sports_rounded,
              color: profile.isAdmin ? AppTheme.accentLime : AppTheme.accentTeal,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  profile.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  ref.read(authControllerProvider).user?.email ?? 'No email associated',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Text(
                    profile.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: profile.isAdmin ? AppTheme.accentLime : AppTheme.accentTeal,
                      letterSpacing: 1.0,
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: ListTile(
        onTap: onTap,
        mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4)),
        trailing: trailingWidget ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
