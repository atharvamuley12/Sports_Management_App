import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/utils/seed_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';

class AdminDashboardData {
  final int totalStudents;
  final int activeStudents;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double netProfit;
  final double pendingDues;
  final int todayPresent;
  final int todayTotal;

  AdminDashboardData({
    required this.totalStudents,
    required this.activeStudents,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.netProfit,
    required this.pendingDues,
    required this.todayPresent,
    required this.todayTotal,
  });
}

final adminDashboardDataProvider = FutureProvider.autoDispose<AdminDashboardData>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final currentMonth = now.month;
  final currentYear = now.year;

  // 1. Fetch students status
  final studentsRes = await supabase.from('students').select('status');
  final totalStudents = studentsRes.length;
  final activeStudents = studentsRes.where((s) => s['status'] == 'active').length;

  // 2. Monthly income (payments this month)
  final incomeRes = await supabase
      .from('payments')
      .select('amount')
      .eq('month', currentMonth)
      .eq('year', currentYear);
  final double monthlyIncome = (incomeRes as List).fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

  // 3. Monthly expenses
  final firstDayStr = "${currentYear.toString().padLeft(4, '0')}-${currentMonth.toString().padLeft(2, '0')}-01";
  final lastDay = DateTime(currentYear, currentMonth + 1, 0);
  final lastDayStr = "${currentYear.toString().padLeft(4, '0')}-${currentMonth.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";
  
  final expensesRes = await supabase
      .from('expenses')
      .select('amount')
      .gte('date', firstDayStr)
      .lte('date', lastDayStr);
  final double monthlyExpenses = (expensesRes as List).fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

  // 4. Net profit (P&L): all-time payments sum - all-time expenses sum
  final allPaymentsRes = await supabase.from('payments').select('amount');
  final allExpensesRes = await supabase.from('expenses').select('amount');
  
  final double totalIncome = (allPaymentsRes as List).fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  final double totalExpenses = (allExpensesRes as List).fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  final double netProfit = totalIncome - totalExpenses;

  // 5. Pending dues (sum from view)
  final duesRes = await supabase.from('student_dues').select('pending_dues');
  final double pendingDues = (duesRes as List).fold(0.0, (sum, item) => sum + (item['pending_dues'] as num).toDouble());

  // 6. Today's attendance summary
  final todayStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  final attendanceRes = await supabase
      .from('attendance')
      .select('status')
      .eq('date', todayStr);
  final todayPresent = (attendanceRes as List).where((a) => a['status'] == 'present').length;
  final todayTotal = (attendanceRes as List).length;

  return AdminDashboardData(
    totalStudents: totalStudents,
    activeStudents: activeStudents,
    monthlyIncome: monthlyIncome,
    monthlyExpenses: monthlyExpenses,
    netProfit: netProfit,
    pendingDues: pendingDues,
    todayPresent: todayPresent,
    todayTotal: todayTotal,
  );
});

class CoachDashboardData {
  final List<Batch> batches;
  final int totalStudents;

  CoachDashboardData({
    required this.batches,
    required this.totalStudents,
  });
}

final coachDashboardDataProvider = FutureProvider.autoDispose<CoachDashboardData>((ref) async {
  final batchRepo = ref.watch(batchRepositoryProvider);
  final studentRepo = ref.watch(studentRepositoryProvider);

  final batches = await batchRepo.getBatches();
  final students = await studentRepo.getStudents();

  return CoachDashboardData(
    batches: batches,
    totalStudents: students.length,
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.accentLime,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 16),
              const Text('Loading your dashboard...', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (profile.isAdmin) {
              ref.invalidate(adminDashboardDataProvider);
            } else {
              ref.invalidate(coachDashboardDataProvider);
            }
          },
          color: AppTheme.accentLime,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom App Bar
              SliverToBoxAdapter(
                child: _buildTopBar(context, ref, profile.fullName, profile.isAdmin),
              ),
              // Greeting
              SliverToBoxAdapter(
                child: _buildGreetingCard(profile.fullName, profile.isAdmin),
              ),
              // Dashboard content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: profile.isAdmin
                      ? _buildAdminDashboard(context, ref)
                      : _buildCoachDashboard(context, ref),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, String name, bool isAdmin) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good Morning' : (now.hour < 17 ? 'Good Afternoon' : 'Good Evening');
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Notification / Profile area
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: () => _showLogoutDialog(context, ref),
              tooltip: 'Sign Out',
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 22),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
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

  Widget _buildGreetingCard(String name, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAdmin
                ? [
                    AppTheme.accentLime.withValues(alpha: 0.12),
                    AppTheme.accentLime.withValues(alpha: 0.03),
                    AppTheme.darkCard,
                  ]
                : [
                    AppTheme.accentTeal.withValues(alpha: 0.12),
                    AppTheme.accentTeal.withValues(alpha: 0.03),
                    AppTheme.darkCard,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isAdmin ? AppTheme.accentLime : AppTheme.accentTeal).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isAdmin ? AppTheme.limeGradient : AppTheme.tealGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (isAdmin ? AppTheme.accentLime : AppTheme.accentTeal).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isAdmin ? Icons.shield_outlined : Icons.sports_outlined,
                size: 24,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'Admin Dashboard' : 'Coach Dashboard',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    isAdmin
                        ? 'Full control over academy operations'
                        : 'Manage your batch and attendance',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dashboardAsync = ref.watch(adminDashboardDataProvider);

    return dashboardAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentLime,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (err, stack) => _buildErrorWidget(err.toString()),
      data: (data) {
        final isEmpty = data.totalStudents == 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isEmpty) _buildSeedCard(context, ref),

            // Stats section header
            const _SectionHeader(title: 'Overview', icon: Icons.analytics_outlined),
            const SizedBox(height: 12),

            // Stats Grid — 2 columns
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _StatCard(
                  label: 'Total Students',
                  value: '${data.totalStudents}',
                  icon: Icons.people_alt_rounded,
                  gradient: AppTheme.limeGradient,
                  iconBgColor: AppTheme.accentLime,
                ),
                _StatCard(
                  label: 'Active Students',
                  value: '${data.activeStudents}',
                  icon: Icons.verified_rounded,
                  gradient: AppTheme.tealGradient,
                  iconBgColor: AppTheme.accentTeal,
                ),
                _StatCard(
                  label: 'Monthly Income',
                  value: currencyFormat.format(data.monthlyIncome),
                  icon: Icons.trending_up_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF059669)],
                  ),
                  iconBgColor: AppTheme.successGreen,
                ),
                _StatCard(
                  label: 'Monthly Expenses',
                  value: currencyFormat.format(data.monthlyExpenses),
                  icon: Icons.trending_down_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
                  ),
                  iconBgColor: AppTheme.errorRed,
                ),
                _StatCard(
                  label: 'Net Profit (P&L)',
                  value: currencyFormat.format(data.netProfit),
                  icon: Icons.account_balance_rounded,
                  gradient: AppTheme.purpleGradient,
                  iconBgColor: AppTheme.accentPurple,
                  isHighlighted: true,
                ),
                _StatCard(
                  label: 'Pending Dues',
                  value: currencyFormat.format(data.pendingDues),
                  icon: Icons.warning_amber_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                  ),
                  iconBgColor: AppTheme.warningAmber,
                ),
                _StatCard(
                  label: 'Today\'s Attendance',
                  value: data.todayTotal > 0
                      ? '${data.todayPresent}/${data.todayTotal}'
                      : 'N/A',
                  icon: Icons.fact_check_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                  iconBgColor: AppTheme.infoBlue,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Quick Actions
            const _SectionHeader(title: 'Quick Actions', icon: Icons.bolt_rounded),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _ActionCard(
                  label: 'Students',
                  icon: Icons.school_rounded,
                  color: AppTheme.accentLime,
                  onTap: () => context.push('/students'),
                ),
                _ActionCard(
                  label: 'Attendance',
                  icon: Icons.event_note_rounded,
                  color: AppTheme.accentTeal,
                  onTap: () => context.push('/attendance'),
                ),
                _ActionCard(
                  label: 'Fee Ledger',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.accentPurple,
                  onTap: () => context.push('/fees'),
                ),
                _ActionCard(
                  label: 'Expenses',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.accentOrange,
                  onTap: () => context.push('/expenses'),
                ),
                _ActionCard(
                  label: 'Reports',
                  icon: Icons.insights_rounded,
                  color: AppTheme.accentPink,
                  onTap: () => context.push('/reports'),
                ),
                _ActionCard(
                  label: 'Coaches',
                  icon: Icons.supervised_user_circle_rounded,
                  color: AppTheme.infoBlue,
                  onTap: () => context.push('/users'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeedCard(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentLime.withValues(alpha: 0.08),
              AppTheme.darkCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentLime.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.rocket_launch_rounded, size: 32, color: AppTheme.accentLime),
            ),
            const SizedBox(height: 14),
            const Text(
              'Empty Database Detected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seed mock data to explore the dashboard with batches, students, payments, and expenses.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: const Text('Seed Test Data'),
                onPressed: () async {
                  try {
                    final supabase = ref.read(supabaseClientProvider);
                    await SeedHelper.seedTestData(supabase);
                    ref.invalidate(adminDashboardDataProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                              SizedBox(width: 12),
                              Text('Mock data seeded successfully!'),
                            ],
                          ),
                          backgroundColor: AppTheme.darkCard,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Seeding failed: $e'),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachDashboard(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(coachDashboardDataProvider);

    return dashboardAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: AppTheme.accentTeal, strokeWidth: 2.5)),
      ),
      error: (err, stack) => _buildErrorWidget(err.toString()),
      data: (data) {
        final batch = data.batches.isNotEmpty ? data.batches.first : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Batch Info Card
            const _SectionHeader(title: 'Your Batch', icon: Icons.groups_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.premiumCard(accentColor: AppTheme.accentTeal),
              child: batch != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppTheme.tealGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                batch.sport == 'cricket' ? Icons.sports_cricket : Icons.sports_soccer,
                                size: 22,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    batch.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentTeal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      batch.sport.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accentTeal,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.darkBorder),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Students', style: TextStyle(color: AppTheme.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.accentTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SelectableText(
                                '${data.totalStudents}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppTheme.accentTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 40, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Not assigned to any batch yet.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Please contact the administrator.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 28),

            // Coach Actions
            const _SectionHeader(title: 'Actions', icon: Icons.bolt_rounded),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _ActionCard(
                  label: 'Mark\nAttendance',
                  icon: Icons.checklist_rounded,
                  color: AppTheme.accentTeal,
                  onTap: batch == null ? null : () => context.push('/attendance'),
                ),
                _ActionCard(
                  label: 'View\nStudents',
                  icon: Icons.people_alt_rounded,
                  color: AppTheme.accentLime,
                  onTap: batch == null ? null : () => context.push('/students'),
                ),
                _ActionCard(
                  label: 'Add\nStudent',
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppTheme.accentPurple,
                  onTap: batch == null ? null : () => context.push('/students/new'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: AppTheme.errorRed),
          const SizedBox(height: 12),
          SelectableText(
            'Error loading dashboard: $error',
            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Components ─────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final Color iconBgColor;
  final bool isHighlighted;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.iconBgColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? iconBgColor.withValues(alpha: 0.3)
              : AppTheme.darkBorder,
        ),
        boxShadow: [
          if (isHighlighted)
            BoxShadow(
              color: iconBgColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
