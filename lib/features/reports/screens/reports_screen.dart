import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/screens/dashboard_screen.dart';

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
    final parsedDate = DateTime.parse(dStr);
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
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Financials'),
              Tab(icon: Icon(Icons.rule_rounded), text: 'Attendance'),
            ],
            indicatorColor: AppTheme.accentLime,
            labelColor: AppTheme.accentLime,
            unselectedLabelColor: AppTheme.textSecondary,
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
      onRefresh: () async {
        ref.invalidate(reportsDataProvider);
        ref.invalidate(adminDashboardDataProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dashboard Dues summary card
            dashboardAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => const SizedBox(),
              data: (dData) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'P&L Performance Overview',
                        style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Net Profit (All-Time):'),
                          SelectableText(
                            currencyFormat.format(dData.netProfit),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: dData.netProfit >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Outstanding Fees:'),
                          SelectableText(
                            currencyFormat.format(dData.pendingDues),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.warningAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Chart Container
            const Text(
              'Income vs Expenses (Last 6 Months)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            reportsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error loading reports: $err')),
              data: (rData) {
                double maxVal = 5000;
                for (final item in rData.last6Months) {
                  if (item.income > maxVal) maxVal = item.income;
                  if (item.expense > maxVal) maxVal = item.expense;
                }
                maxVal = (maxVal / 1000).ceil() * 1000.0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 16, 12),
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
                                  getTooltipColor: (_) => Colors.grey[850]!,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final monthLabel = rData.last6Months[groupIndex].label;
                                    final isIncome = rodIndex == 0;
                                    return BarTooltipItem(
                                      '$monthLabel\n${isIncome ? 'Income' : 'Expense'}: ${currencyFormat.format(rod.toY)}',
                                      TextStyle(
                                        color: isIncome ? Colors.lime : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
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
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                                      if (value == 0) return const Text('₹0', style: TextStyle(fontSize: 8, color: Colors.grey));
                                      return Text(
                                        '₹${(value / 1000).toStringAsFixed(1)}k',
                                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: true, drawVerticalLine: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(rData.last6Months.length, (index) {
                                final financials = rData.last6Months[index];
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: financials.income,
                                      color: Colors.lime,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    BarChartRodData(
                                      toY: financials.expense,
                                      color: AppTheme.errorRed,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Legend
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.square, size: 12, color: Colors.lime),
                                SizedBox(width: 4),
                                Text('Income', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                            SizedBox(width: 24),
                            Row(
                              children: [
                                Icon(Icons.square, size: 12, color: AppTheme.errorRed),
                                SizedBox(width: 4),
                                Text('Expense', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Rolling summary cards
            reportsAsync.when(
              loading: () => const SizedBox(),
              error: (err, stack) => const SizedBox(),
              data: (rData) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '6-Month Financial Summary',
                        style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Period Income:'),
                          SelectableText(
                            currencyFormat.format(rData.totalIncome),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentLime),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Period Expenses:'),
                          SelectableText(
                            currencyFormat.format(rData.totalExpenses),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ],
                  ),
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
      onRefresh: () async {
        ref.invalidate(attendanceReportsDataProvider);
      },
      child: attendanceReportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading attendance reports: $err')),
        data: (data) {
          if (data.batchStats.isEmpty && data.dailyTrend.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No attendance records logged in the last 30 days.')),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Rate Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLime.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.rule_rounded, size: 28, color: AppTheme.accentLime),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('30-Day Attendance Rate', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                '${(data.overallRate * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Attendance Trend Chart
                if (data.dailyTrend.isNotEmpty) ...[
                  const Text('Attendance Trend (Past 30 Days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 24, 16, 12),
                      child: SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => Colors.grey[850]!,
                                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final dayData = data.dailyTrend[spot.x.toInt()];
                                    final percentage = dayData.total > 0 ? (dayData.present / dayData.total * 100) : 0.0;
                                    return LineTooltipItem(
                                      '${dayData.dateLabel}\nPresent: ${dayData.present}/${dayData.total}\nRate: ${percentage.toStringAsFixed(1)}%',
                                      const TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.bold),
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
                                    // Show labels for every 5th item to avoid crowding on mobile screen
                                    if (index >= 0 && index < data.dailyTrend.length && index % 5 == 0) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(data.dailyTrend[index].dateLabel, style: const TextStyle(fontSize: 8, color: Colors.grey)),
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
                                    return Text('${value.toInt()}%', style: const TextStyle(fontSize: 8, color: Colors.grey));
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
                                color: AppTheme.accentTeal,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.accentTeal.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Batch Stats Section
                const Text('Attendance by Batch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.batchStats.length,
                  itemBuilder: (context, idx) {
                    final bStats = data.batchStats[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(bStats.batchName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                Text(
                                  '${(bStats.attendanceRate * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: bStats.attendanceRate >= 0.75
                                        ? AppTheme.successGreen
                                        : (bStats.attendanceRate >= 0.5 ? AppTheme.warningAmber : AppTheme.errorRed),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: bStats.attendanceRate,
                                minHeight: 8,
                                color: bStats.attendanceRate >= 0.75
                                    ? AppTheme.successGreen
                                    : (bStats.attendanceRate >= 0.5 ? AppTheme.warningAmber : AppTheme.errorRed),
                                backgroundColor: AppTheme.darkBorder,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Present Count: ${bStats.presentCount} / ${bStats.totalCount} marks total',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
