import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../../core/utils/date_utils.dart';

class MonthlyFinancials {
  final String label; // e.g. "Jan", "Feb"
  final double income;
  final double expense;

  MonthlyFinancials({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class ReportsData {
  final List<MonthlyFinancials> last6Months;
  final double totalIncome;
  final double totalExpenses;

  ReportsData({
    required this.last6Months,
    required this.totalIncome,
    required this.totalExpenses,
  });
}

class BatchAttendanceStats {
  final String batchName;
  final double attendanceRate;
  final int presentCount;
  final int totalCount;

  BatchAttendanceStats({
    required this.batchName,
    required this.attendanceRate,
    required this.presentCount,
    required this.totalCount,
  });
}

class DailyAttendanceStats {
  final String dateLabel;
  final DateTime date;
  final int present;
  final int total;

  DailyAttendanceStats({
    required this.dateLabel,
    required this.date,
    required this.present,
    required this.total,
  });
}

class AttendanceReportsData {
  final double overallRate;
  final List<BatchAttendanceStats> batchStats;
  final List<DailyAttendanceStats> dailyTrend;

  AttendanceReportsData({
    required this.overallRate,
    required this.batchStats,
    required this.dailyTrend,
  });
}

final reportsDataProvider = FutureProvider.autoDispose<ReportsData>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final now = DateTime.now();

  final List<MonthlyFinancials> last6Months = [];
  double totalIncome = 0;
  double totalExpenses = 0;

  for (int i = 5; i >= 0; i--) {
    final monthDate = DateTime(now.year, now.month - i, 1);
    final m = monthDate.month;
    final y = monthDate.year;
    final monthLabel = DateFormat('MMM').format(monthDate);

    // Fetch payments
    final paymentsRes = await supabase
        .from('payments')
        .select('amount')
        .eq('month', m)
        .eq('year', y);
    final double income = (paymentsRes as List).fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

    // Fetch expenses
    final firstDayStr = "$y-${m.toString().padLeft(2, '0')}-01";
    final lastDay = DateTime(y, m + 1, 0);
    final lastDayStr = "$y-${m.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";
    
    final expensesRes = await supabase
        .from('expenses')
        .select('amount')
        .gte('date', firstDayStr)
        .lte('date', lastDayStr);
    final double expense = (expensesRes as List).fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

    last6Months.add(MonthlyFinancials(
      label: monthLabel,
      income: income,
      expense: expense,
    ));

    totalIncome += income;
    totalExpenses += expense;
  }

  return ReportsData(
    last6Months: last6Months,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
  );
});

final attendanceReportsDataProvider = FutureProvider.autoDispose<AttendanceReportsData>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  // 1. Fetch batches
  final batchesRes = await supabase.from('batches').select('id, name');
  final batchMap = {for (var b in batchesRes as List) b['id'] as String: b['name'] as String};

  // 2. Fetch students
  final studentsRes = await supabase.from('students').select('id, batch_id');
  final studentBatchMap = {for (var s in studentsRes as List) s['id'] as String: s['batch_id'] as String?};

  // 3. Fetch attendance (past 30 days)
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final thirtyDaysAgoStr = "${thirtyDaysAgo.year.toString().padLeft(4, '0')}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}";
  final attendanceRes = await supabase
      .from('attendance')
      .select('student_id, date, status')
      .gte('date', thirtyDaysAgoStr);

  final records = attendanceRes as List;
  if (records.isEmpty) {
    return AttendanceReportsData(overallRate: 0.0, batchStats: [], dailyTrend: []);
  }

  // 4. Calculate overall rate
  final totalPresent = records.where((r) => r['status'] == 'present').length;
  final totalCount = records.length;
  final overallRate = totalPresent / totalCount;

  // 5. Calculate batch stats
  final batchPresentCounts = <String, int>{};
  final batchTotalCounts = <String, int>{};
  
  for (final rec in records) {
    final sId = rec['student_id'] as String;
    final status = rec['status'] as String;
    final bId = studentBatchMap[sId];
    if (bId != null) {
      batchTotalCounts[bId] = (batchTotalCounts[bId] ?? 0) + 1;
      if (status == 'present') {
        batchPresentCounts[bId] = (batchPresentCounts[bId] ?? 0) + 1;
      }
    }
  }

  final List<BatchAttendanceStats> batchStatsList = [];
  batchMap.forEach((bId, bName) {
    final total = batchTotalCounts[bId] ?? 0;
    final present = batchPresentCounts[bId] ?? 0;
    batchStatsList.add(BatchAttendanceStats(
      batchName: bName,
      presentCount: present,
      totalCount: total,
      attendanceRate: total > 0 ? (present / total) : 0.0,
    ));
  });
  batchStatsList.sort((a, b) => b.attendanceRate.compareTo(a.attendanceRate));

  // 6. Daily trend (past 30 days)
  final dailyMap = <String, List<String>>{}; // date -> list of status
  for (final rec in records) {
    final dStr = rec['date'] as String;
    final status = rec['status'] as String;
    dailyMap.putIfAbsent(dStr, () => []).add(status);
  }

  final List<DailyAttendanceStats> dailyTrendList = [];
  dailyMap.forEach((dStr, statuses) {
    final parsedDate = DateUtilsHelper.parseSqlDate(dStr);
    final present = statuses.where((s) => s == 'present').length;
    final total = statuses.length;
    dailyTrendList.add(DailyAttendanceStats(
      dateLabel: DateFormat('d MMM').format(parsedDate),
      date: parsedDate,
      present: present,
      total: total,
    ));
  });
  dailyTrendList.sort((a, b) => a.date.compareTo(b.date));

  return AttendanceReportsData(
    overallRate: overallRate,
    batchStats: batchStatsList,
    dailyTrend: dailyTrendList,
  );
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Financials'),
              Tab(icon: Icon(Icons.rule_rounded, size: 20), text: 'Attendance'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FinancialReportsView(),
            _AttendanceReportsView(),
          ],
        ),
      ),
    );
  }
}

class _FinancialReportsView extends ConsumerWidget {
  const _FinancialReportsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsDataProvider);
    final dashboardAsync = ref.watch(adminDashboardDataProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      onRefresh: () async {
        ref.invalidate(reportsDataProvider);
        ref.invalidate(adminDashboardDataProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dashboard Dues summary card
            dashboardAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: SizedBox(height: 2, child: LinearProgressIndicator()),
              )),
              error: (err, stack) => const SizedBox(),
              data: (dData) => AppCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: 'P&L PERFORMANCE OVERVIEW',
                      icon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Net Profit (All-Time)', style: AppTheme.body2),
                        SelectableText(
                          currencyFormat.format(dData.netProfit),
                          style: AppTheme.heading3.copyWith(
                            color: dData.netProfit >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppTheme.space20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Outstanding Fees', style: AppTheme.body2),
                        SelectableText(
                          currencyFormat.format(dData.pendingDues),
                          style: AppTheme.heading3.copyWith(
                            color: AppTheme.warningAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Chart Container
            const AppSectionHeader(
              title: 'INCOME VS EXPENSES (LAST 6 MONTHS)',
              icon: Icons.bar_chart_rounded,
            ),
            const SizedBox(height: AppTheme.space12),
            reportsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.space40),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
                  ),
                ),
              ),
              error: (err, stack) => AppErrorState(message: err.toString()),
              data: (rData) {
                double maxVal = 5000;
                for (final item in rData.last6Months) {
                  if (item.income > maxVal) maxVal = item.income;
                  if (item.expense > maxVal) maxVal = item.expense;
                }
                maxVal = (maxVal / 1000).ceil() * 1000.0;

                return AppCard(
                  padding: const EdgeInsets.fromLTRB(AppTheme.space8, AppTheme.space24, AppTheme.space16, AppTheme.space12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxVal,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                 getTooltipColor: (_) => Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard,
                                 getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                   final monthLabel = rData.last6Months[groupIndex].label;
                                   final isIncome = rodIndex == 0;
                                   final isDark = Theme.of(context).brightness == Brightness.dark;
                                   return BarTooltipItem(
                                     '$monthLabel\n${isIncome ? 'Income' : 'Expense'}: ${currencyFormat.format(rod.toY)}',
                                     AppTheme.subtitle2.copyWith(
                                       color: isIncome
                                           ? (isDark ? AppTheme.accentLime : AppTheme.successGreen)
                                           : AppTheme.errorRed,
                                       fontSize: 12,
                                     ),
                                   );
                                 },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < rData.last6Months.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          rData.last6Months[index].label,
                                          style: AppTheme.caption.copyWith(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value == 0) return Text('₹0', style: AppTheme.caption.copyWith(fontSize: 8));
                                    return Text(
                                      '₹${(value / 1000).toStringAsFixed(1)}k',
                                      style: AppTheme.caption.copyWith(fontSize: 8),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1000,
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(rData.last6Months.length, (index) {
                              final financials = rData.last6Months[index];
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: financials.income,
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(AppTheme.radius6),
                                  ),
                                  BarChartRodData(
                                    toY: financials.expense,
                                    color: AppTheme.errorRed,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(AppTheme.radius6),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                               Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 6),
                              Text('Income', style: AppTheme.caption),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.errorRed, borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 6),
                              Text('Expense', style: AppTheme.caption),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.space20),

            // Rolling summary cards
            reportsAsync.when(
              loading: () => const SizedBox(),
              error: (err, stack) => const SizedBox(),
              data: (rData) => AppCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: '6-MONTH FINANCIAL SUMMARY',
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                    const Divider(height: AppTheme.space24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Period Income', style: AppTheme.body2),
                        SelectableText(
                          currencyFormat.format(rData.totalIncome),
                          style: AppTheme.subtitle1.copyWith(color: AppTheme.accentLime, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Period Expenses', style: AppTheme.body2),
                        SelectableText(
                          currencyFormat.format(rData.totalExpenses),
                          style: AppTheme.subtitle1.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceReportsView extends ConsumerWidget {
  const _AttendanceReportsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceReportsAsync = ref.watch(attendanceReportsDataProvider);

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      onRefresh: () async {
        ref.invalidate(attendanceReportsDataProvider);
      },
      child: attendanceReportsAsync.when(
        loading: () => const AppLoadingState(itemCount: 4, itemHeight: 90),
        error: (err, stack) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(attendanceReportsDataProvider),
        ),
        data: (data) {
          if (data.batchStats.isEmpty && data.dailyTrend.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                AppEmptyState(
                  icon: Icons.rule_folder_rounded,
                  title: 'No attendance records logged',
                  subtitle: 'There are no logged entries in the last 30 days.',
                ),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Rate Card
                AppCard(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLime.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentLime.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.rule_rounded, size: 24, color: AppTheme.accentLime),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('30-Day Attendance Rate', style: AppTheme.caption),
                            const SizedBox(height: AppTheme.space4),
                            Text(
                              '${(data.overallRate * 100).toStringAsFixed(1)}%',
                              style: AppTheme.heading1.copyWith(fontSize: 28),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space20),

                // Attendance Trend Chart
                if (data.dailyTrend.isNotEmpty) ...[
                  const AppSectionHeader(
                    title: 'ATTENDANCE TREND (PAST 30 DAYS)',
                    icon: Icons.show_chart_rounded,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(AppTheme.space8, AppTheme.space24, AppTheme.space16, AppTheme.space12),
                    child: SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard,
                              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final dayData = data.dailyTrend[spot.x.toInt()];
                                  final percentage = dayData.total > 0 ? (dayData.present / dayData.total * 100) : 0.0;
                                  return LineTooltipItem(
                                    '${dayData.dateLabel}\nPresent: ${dayData.present}/${dayData.total}\nRate: ${percentage.toStringAsFixed(1)}%',
                                    AppTheme.subtitle2.copyWith(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < data.dailyTrend.length && index % 5 == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(data.dailyTrend[index].dateLabel, style: AppTheme.caption.copyWith(fontSize: 8)),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}%', style: AppTheme.caption.copyWith(fontSize: 8));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minY: 0,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(data.dailyTrend.length, (idx) {
                                final day = data.dailyTrend[idx];
                                final rate = day.total > 0 ? (day.present / day.total * 100) : 0.0;
                                return FlSpot(idx.toDouble(), rate);
                              }),
                              isCurved: true,
                              color: Theme.of(context).colorScheme.secondary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),
                ],

                // Batch Stats Section
                const AppSectionHeader(
                  title: 'ATTENDANCE BY BATCH',
                  icon: Icons.groups_rounded,
                ),
                const SizedBox(height: AppTheme.space12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.batchStats.length,
                  itemBuilder: (context, idx) {
                    final bStats = data.batchStats[idx];
                    final Color progressColor = bStats.attendanceRate >= 0.75
                        ? AppTheme.successGreen
                        : (bStats.attendanceRate >= 0.5 ? AppTheme.warningAmber : AppTheme.errorRed);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space10),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(bStats.batchName, style: AppTheme.subtitle1),
                                Text(
                                  '${(bStats.attendanceRate * 100).toStringAsFixed(0)}%',
                                  style: AppTheme.subtitle1.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: progressColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radius6),
                              child: LinearProgressIndicator(
                                value: bStats.attendanceRate,
                                minHeight: 6,
                                color: progressColor,
                                backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              'Present Count: ${bStats.presentCount} / ${bStats.totalCount} marks total',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
