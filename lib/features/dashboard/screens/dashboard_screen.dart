import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/utils/seed_helper.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';

// ═══════════════════════════════════════════════════════════════════
// DATA CLASSES & PROVIDERS — Completely unchanged
// ═══════════════════════════════════════════════════════════════════

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
  final Map<String, int> studentsPerBatch;

  CoachDashboardData({
    required this.batches,
    required this.totalStudents,
    required this.studentsPerBatch,
  });
}

final coachDashboardDataProvider = FutureProvider.autoDispose<CoachDashboardData>((ref) async {
  final batchRepo = ref.watch(batchRepositoryProvider);
  final studentRepo = ref.watch(studentRepositoryProvider);

  final batches = await batchRepo.getBatches();
  final students = await studentRepo.getStudents();

  final batchIds = batches.map((b) => b.id).toSet();
  final coachStudents = students.where((s) => batchIds.contains(s.batchId)).toList();

  final Map<String, int> studentsPerBatch = {};
  for (var s in coachStudents) {
    if (s.batchId != null) {
      studentsPerBatch[s.batchId!] = (studentsPerBatch[s.batchId!] ?? 0) + 1;
    }
  }

  return CoachDashboardData(
    batches: batches,
    totalStudents: coachStudents.length,
    studentsPerBatch: studentsPerBatch,
  );
});

// ═══════════════════════════════════════════════════════════════════
// DASHBOARD SCREEN
// ═══════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;

    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppTheme.accentLime,
              strokeWidth: 2.5,
            ),
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
          backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Bar
              SliverToBoxAdapter(
                child: _buildTopBar(context, ref, profile.fullName, profile.isAdmin),
              ),
              // Role Badge
              SliverToBoxAdapter(
                child: _buildRoleBadge(context, profile.isAdmin),
              ),
              // Dashboard Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  child: profile.isAdmin
                      ? _buildAdminDashboard(context, ref)
                      : _buildCoachDashboard(context, ref),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppTheme.space24)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, WidgetRef ref, String name, bool isAdmin) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : (now.hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final dateStr = DateFormat('EEE, d MMM').format(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space12, AppTheme.space16, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: isAdmin ? AppTheme.limeGradient : AppTheme.tealGradient,
              borderRadius: BorderRadius.circular(AppTheme.radius10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTheme.subtitle1.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: AppTheme.caption.copyWith(
                    color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Text(name, style: AppTheme.heading3.copyWith(fontSize: 15)),
              ],
            ),
          ),
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space10,
              vertical: AppTheme.space4,
            ),
            decoration: AppTheme.subtleCard(borderRadius: AppTheme.radius8, isDark: isDark),
            child: Text(
              dateStr,
              style: AppTheme.labelSmall.copyWith(
                fontSize: 9,
                color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space6),
          // Logout
          AppIconButton(
            icon: Icons.logout_rounded,
            onTap: () => _showLogoutDialog(context, ref),
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  // ─── LOGOUT DIALOG ──────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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

  // ─── ROLE BADGE ──────────────────────────────────────────────────

  Widget _buildRoleBadge(BuildContext context, bool isAdmin) {
    final theme = Theme.of(context);
    final gradient = isAdmin ? AppTheme.limeGradient : AppTheme.tealGradient;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space12, AppTheme.space16, AppTheme.space12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space10),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius10),
          border: Border.all(color: theme.colorScheme.outline, width: 0.8),
        ),
        child: Row(
          children: [
            AppGradientIcon(
              icon: isAdmin ? Icons.shield_outlined : Icons.sports_outlined,
              gradient: gradient,
              size: 16,
              padding: AppTheme.space6,
            ),
            const SizedBox(width: AppTheme.space10),
            Expanded(
              child: Text(
                isAdmin ? 'Admin Portal Access' : 'Coach Portal Access',
                style: AppTheme.subtitle2.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADMIN DASHBOARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAdminDashboard(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dashboardAsync = ref.watch(adminDashboardDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dashboardAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTheme.space32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppTheme.accentGold,
              strokeWidth: 2.5,
            ),
          ),
        ),
      ),
      error: (err, stack) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(adminDashboardDataProvider),
      ),
      data: (data) {
        final isEmpty = data.totalStudents == 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isEmpty) _buildSeedCard(context, ref),

            // High-end P&L Performance Summary Card
            _buildNetProfitBanner(context, data.netProfit, currencyFormat),

            // Overview Section Header
            const AppSectionHeader(title: 'OVERVIEW', icon: Icons.grid_view_rounded),
            const SizedBox(height: AppTheme.space8),

            // Stats Grid — 2-column layout (exactly 2 rows of horizontal cards)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.space8,
              crossAxisSpacing: AppTheme.space8,
              childAspectRatio: 2.1,
              children: [
                _StatCard(
                  label: 'Total Students',
                  value: '${data.totalStudents}',
                  icon: Icons.people_outline_rounded,
                  iconColor: isDark ? const Color(0xFFD4A017) : const Color(0xFFC67D15),
                  iconBgColor: isDark ? const Color(0xFF2C261A) : const Color(0xFFEFDEBC),
                ),
                _StatCard(
                  label: 'Active Students...',
                  value: '${data.activeStudents}',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1C6B5F),
                  iconBgColor: isDark ? const Color(0xFF1E2F38) : const Color(0xFFD1E6E1),
                ),
                _StatCard(
                  label: 'Attendance',
                  value: data.todayTotal > 0
                      ? '${data.todayPresent}/${data.todayTotal}'
                      : '1/2',
                  icon: Icons.contrast_rounded,
                  iconColor: isDark ? const Color(0xFFB6C2D1) : const Color(0xFF4A5D6E),
                  iconBgColor: isDark ? const Color(0xFF232A35) : const Color(0xFFE2E8F0),
                ),
                _StatCard(
                  label: '%',
                  value: '0',
                  icon: Icons.calendar_month_rounded,
                  iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2C6B75),
                  iconBgColor: isDark ? const Color(0xFF192A35) : const Color(0xFFD3E7E8),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),

            // Full-width Detail Stats Cards
            _FullWidthStatCard(
              label: 'Monthly Income',
              value: currencyFormat.format(data.monthlyIncome),
              icon: Icons.trending_up_rounded,
              iconBgColor: isDark ? const Color(0xFF2C261A) : const Color(0xFFEFDEBC),
              iconColor: isDark ? const Color(0xFFD4A017) : const Color(0xFFC67D15),
              valueColor: isDark ? const Color(0xFFD4A017) : const Color(0xFFC67D15),
              barHeights: const [0.35, 0.65, 0.95],
            ),
            _FullWidthStatCard(
              label: 'Monthly Expense',
              value: currencyFormat.format(data.monthlyExpenses),
              icon: Icons.trending_down_rounded,
              iconBgColor: isDark ? const Color(0xFF232A20) : const Color(0xFFE5E9D5),
              iconColor: isDark ? const Color(0xFF8C7A53) : const Color(0xFF8C9672),
              valueColor: isDark ? const Color(0xFF8C7A53) : const Color(0xFF8C9672),
              barHeights: const [0.95, 0.75, 0.95],
            ),
            _FullWidthStatCard(
              label: 'Pending Dues',
              value: '-${currencyFormat.format(data.pendingDues.abs())}',
              icon: Icons.warning_amber_rounded,
              iconBgColor: isDark ? const Color(0xFF361C1C) : const Color(0xFFFBEBE8),
              iconColor: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
              valueColor: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
            ),
            const SizedBox(height: AppTheme.space8),
          ],
        );
      },
    );
  }

  Widget _buildNetProfitBanner(BuildContext context, double netProfit, NumberFormat currencyFormat) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isProfit = netProfit >= 0;
    
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    
    final iconBgColor = isDark ? const Color(0xFF2C261A) : const Color(0xFFC67D15);
    final iconColor = isDark ? const Color(0xFFD4A017) : const Color(0xFFFAF0DC);
    
    final valueColor = isDark ? const Color(0xFFD4A017) : const Color(0xFF103F4C);
    
    final chipBgColor = isDark ? const Color(0xFF0A2E1C) : const Color(0xFFD1E6E1);
    final chipTextColor = isDark ? const Color(0xFF22C55E) : const Color(0xFF1C6B5F);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radius14),
          border: Border.all(color: theme.colorScheme.outline, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(AppTheme.radius10),
              ),
              child: Icon(Icons.payments_outlined, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppTheme.space14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Profit (P&L Summary)',
                    style: AppTheme.caption.copyWith(
                      color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    currencyFormat.format(netProfit),
                    style: AppTheme.heading2.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: valueColor.withValues(alpha: isDark ? 0.35 : 0.15),
                          blurRadius: isDark ? 8 : 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10, vertical: AppTheme.space6),
              decoration: BoxDecoration(
                color: chipBgColor,
                borderRadius: BorderRadius.circular(AppTheme.radius8),
              ),
              child: Text(
                isProfit ? 'PROFIT' : 'LOSS',
                style: AppTheme.overline.copyWith(
                  color: chipTextColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SEED CARD ──────────────────────────────────────────────────

  Widget _buildSeedCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(color: AppTheme.accentLime.withValues(alpha: 0.15), width: 0.8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch_rounded, size: 18, color: AppTheme.accentLime),
                const SizedBox(width: AppTheme.space8),
                Text('Empty Database Detected', style: AppTheme.subtitle2),
              ],
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'Seed mock data to explore the dashboard with batches, students, payments, and expenses.',
              style: AppTheme.caption.copyWith(height: 1.3),
            ),
            const SizedBox(height: AppTheme.space12),
            SizedBox(
              height: 38,
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                label: const Text('Seed Test Data', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentLime,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius8)),
                ),
                onPressed: () async {
                  try {
                    final supabase = ref.read(supabaseClientProvider);
                    await SeedHelper.seedTestData(supabase);
                    ref.invalidate(adminDashboardDataProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mock data seeded successfully!', style: AppTheme.body2.copyWith(color: AppTheme.textPrimary)),
                          backgroundColor: AppTheme.darkCard,
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

  // ═══════════════════════════════════════════════════════════════════
  // COACH DASHBOARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCoachDashboard(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(coachDashboardDataProvider);
    final profile = ref.watch(authControllerProvider).profile!;

    return dashboardAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTheme.space32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: AppTheme.accentTeal, strokeWidth: 2.5),
          ),
        ),
      ),
      error: (err, stack) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(coachDashboardDataProvider),
      ),
      data: (data) {
        final batch = data.batches.isNotEmpty ? data.batches.first : null;
        final isRestrictedCoach = profile.isCoach && !profile.isActive;
        final themeMode = ref.watch(themeModeProvider);
        final isDarkMode = themeMode == ThemeMode.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restricted Warning Banner
            if (isRestrictedCoach) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.space12),
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.05),
                  border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.15), width: 0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: AppTheme.errorRed, size: 18),
                    const SizedBox(width: AppTheme.space10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Restricted',
                            style: AppTheme.subtitle2.copyWith(color: AppTheme.errorRed, fontSize: 12),
                          ),
                          const SizedBox(height: AppTheme.space2),
                          Text(
                            'An administrator has suspended active modifications. You have view-only access.',
                            style: AppTheme.caption.copyWith(fontSize: 10, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Batch Info
            AppSectionHeader(
              title: data.batches.length > 1 ? 'YOUR BATCHES' : 'YOUR BATCH',
              icon: Icons.groups_rounded,
            ),
            const SizedBox(height: AppTheme.space8),

            if (data.batches.isEmpty)
              const AppEmptyState(
                icon: Icons.info_outline_rounded,
                title: 'Not assigned to any batch yet',
                subtitle: 'Please contact the administrator to get assigned to a batch.',
              )
            else
              ...data.batches.map((batch) {
                final batchStudentsCount = data.studentsPerBatch[batch.id] ?? 0;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final sportLower = batch.sport.toLowerCase();
                Color accentColor = sportLower == 'cricket'
                    ? AppTheme.accentLime
                    : (sportLower == 'chess' ? AppTheme.accentPurple : AppTheme.accentTeal);
                if (!isDark) {
                  if (accentColor == AppTheme.accentLime) {
                    accentColor = AppTheme.accentLimeDark;
                  } else if (accentColor == AppTheme.accentTeal) {
                    accentColor = AppTheme.accentTealDark;
                  } else if (accentColor == AppTheme.accentPurple) {
                    accentColor = AppTheme.accentPurpleDark;
                  }
                }
                final gradient = sportLower == 'cricket'
                    ? AppTheme.limeGradient
                    : (sportLower == 'chess' ? AppTheme.purpleGradient : AppTheme.tealGradient);
                final capacityRatio = batch.capacity > 0 ? batchStudentsCount / batch.capacity : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.space8),
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: AppTheme.accentCard(accentColor: accentColor, borderRadius: AppTheme.radius12, isDark: isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppGradientIcon(
                            icon: sportLower == 'cricket'
                                ? Icons.sports_cricket
                                : (sportLower == 'chess' ? Icons.grid_on : Icons.sports_soccer),
                            gradient: gradient,
                            size: 16,
                            padding: AppTheme.space6,
                          ),
                          const SizedBox(width: AppTheme.space10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(batch.name, style: AppTheme.subtitle1.copyWith(fontSize: 14)),
                                const SizedBox(height: AppTheme.space2),
                                Text(
                                  batch.sport.toUpperCase(),
                                  style: AppTheme.overline.copyWith(color: accentColor, fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space10),
                      // Capacity progress bar
                      Row(
                        children: [
                          Text('Roster Capacity', style: AppTheme.caption.copyWith(fontSize: 10)),
                          const Spacer(),
                          Text(
                            '$batchStudentsCount / ${batch.capacity}',
                            style: AppTheme.caption.copyWith(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radius6),
                        child: LinearProgressIndicator(
                          value: capacityRatio.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder,
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: AppTheme.space16),

            // Coach Actions
            const AppSectionHeader(title: 'ACTIONS', icon: Icons.bolt_rounded),
            const SizedBox(height: AppTheme.space8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.space8,
              crossAxisSpacing: AppTheme.space8,
              childAspectRatio: 1.15,
              children: [
                _ActionCard(
                  label: 'Attendance',
                  icon: Icons.checklist_rounded,
                  color: isRestrictedCoach ? AppTheme.textMuted : Theme.of(context).colorScheme.secondary,
                  onTap: (batch == null || isRestrictedCoach) ? null : () => context.go('/attendance'),
                ),
                _ActionCard(
                  label: 'View Students',
                  icon: Icons.people_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: batch == null ? null : () => context.go('/students'),
                ),
                _ActionCard(
                  label: 'Add Student',
                  icon: Icons.person_add_alt_1_rounded,
                  color: isRestrictedCoach ? AppTheme.textMuted : AppTheme.accentPurple,
                  onTap: (batch == null || isRestrictedCoach) ? null : () => context.push('/students/new'),
                ),
                _ActionCard(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => context.go('/settings'),
                ),
                _ActionCard(
                  label: isDarkMode ? 'Dark Mode' : 'Light Mode',
                  icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDarkMode ? AppTheme.accentLime : AppTheme.accentTeal,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).state =
                        isDarkMode ? ThemeMode.light : ThemeMode.dark;
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius14),
        border: Border.all(color: theme.colorScheme.outline, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radius10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.statValue.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                    shadows: [
                      Shadow(
                        color: (isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight).withValues(alpha: isDark ? 0.35 : 0.15),
                        blurRadius: isDark ? 8 : 4,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullWidthStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color valueColor;
  final List<double>? barHeights;

  const _FullWidthStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.valueColor,
    this.barHeights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius14),
        border: Border.all(color: theme.colorScheme.outline, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radius10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppTheme.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  value,
                  style: AppTheme.heading2.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: valueColor.withValues(alpha: isDark ? 0.35 : 0.15),
                        blurRadius: isDark ? 8 : 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (barHeights != null) ...[
            const SizedBox(width: AppTheme.space16),
            SizedBox(
              height: 36,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(barHeights!.length, (index) {
                  final h = barHeights![index];
                  final barColor = index == 0
                      ? const Color(0xFFC67D15)
                      : (index == 1 ? const Color(0xFF8C9672) : const Color(0xFF134C5A));
                  final darkBarColor = index == 0
                      ? const Color(0xFFD4A017)
                      : (index == 1 ? const Color(0xFF8C7A53) : const Color(0xFF38BDF8));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 10,
                    height: 36 * h,
                    decoration: BoxDecoration(
                      color: isDark ? darkBarColor : barColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  );
                }),
              ),
            ),
          ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onTap == null;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(AppTheme.radius12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        splashColor: color.withValues(alpha: isDark ? 0.08 : 0.12),
        highlightColor: color.withValues(alpha: isDark ? 0.04 : 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(color: theme.colorScheme.outline, width: 0.8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDisabled ? 0.04 : 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                  border: Border.all(
                    color: color.withValues(alpha: isDisabled ? 0.05 : 0.15),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDisabled ? (isDark ? AppTheme.textMuted : AppTheme.textMutedLight) : color,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                label,
                style: AppTheme.subtitle2.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDisabled
                      ? (isDark ? AppTheme.textMuted : AppTheme.textMutedLight)
                      : (theme.textTheme.bodyLarge?.color ?? AppTheme.textPrimary),
                  letterSpacing: -0.1,
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
