import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/payment_repository.dart';
import '../../../core/utils/error_handler.dart';

final studentDuesProvider = FutureProvider.autoDispose<List<StudentDues>>((ref) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.getStudentDues();
});

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final duesAsync = ref.watch(studentDuesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Ledger & Dues'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: AppSearchBar(
              hint: 'Search student by name...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              onRefresh: () async {
                ref.invalidate(studentDuesProvider);
              },
              child: duesAsync.when(
                loading: () => const AppLoadingState(itemCount: 4, itemHeight: 140),
                error: (err, stack) => AppErrorState(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(studentDuesProvider),
                ),
                data: (duesList) {
                  final filtered = duesList.where((d) => d.name.toLowerCase().contains(_searchQuery)).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        AppEmptyState(
                          icon: Icons.payments_rounded,
                          title: 'No student records found',
                          subtitle: 'All students are up to date or no matches exist.',
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                    itemBuilder: (context, index) {
                      final dues = filtered[index];
                      final hasDues = dues.pendingDues > 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space12),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dues.name,
                                      style: AppTheme.subtitle1,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space10,
                                      vertical: AppTheme.space4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasDues 
                                          ? AppTheme.errorRed.withValues(alpha: 0.08) 
                                          : AppTheme.successGreen.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                                      border: Border.all(
                                        color: hasDues 
                                            ? AppTheme.errorRed.withValues(alpha: 0.15) 
                                            : AppTheme.successGreen.withValues(alpha: 0.15),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      hasDues
                                          ? 'DUE: ${currencyFormat.format(dues.pendingDues)}'
                                          : 'PAID / NO DUES',
                                      style: AppTheme.overline.copyWith(
                                        fontSize: 10,
                                        color: hasDues ? AppTheme.errorRed : AppTheme.successGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Monthly Fee: ${currencyFormat.format(dues.monthlyFee)}',
                                    style: AppTheme.caption,
                                  ),
                                  Text(
                                    'Total Paid: ${currencyFormat.format(dues.totalPaid)}',
                                    style: AppTheme.caption,
                                  ),
                                ],
                              ),
                              const Divider(height: AppTheme.space24),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.add_card_outlined, size: 16),
                                        label: const Text('Record Fee'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 0),
                                          backgroundColor: AppTheme.accentLime,
                                          foregroundColor: Colors.black,
                                          textStyle: AppTheme.buttonText.copyWith(fontSize: 13),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppTheme.radius12),
                                          ),
                                        ),
                                        onPressed: () => _showRecordPaymentDialog(dues),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.history_rounded, size: 16),
                                        label: const Text('History'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 0),
                                          textStyle: AppTheme.buttonText.copyWith(fontSize: 13),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppTheme.radius12),
                                          ),
                                        ),
                                        onPressed: () => _showHistoryBottomSheet(dues),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(StudentDues dues) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: dues.pendingDues > 0 ? dues.pendingDues.toString() : dues.monthlyFee.toString(),
    );
    DateTime paymentDate = DateTime.now();
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    String selectedMode = 'upi';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: dialogCtx,
              initialDate: paymentDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (dialogCtx, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark
                        ? const ColorScheme.dark(
                            primary: AppTheme.accentLime,
                            onPrimary: Colors.black,
                            surface: AppTheme.darkCard,
                            onSurface: AppTheme.textPrimary,
                          )
                        : const ColorScheme.light(
                            primary: AppTheme.accentLimeDark,
                            onPrimary: Colors.white,
                            surface: AppTheme.lightCard,
                            onSurface: AppTheme.textPrimaryLight,
                          ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                paymentDate = picked;
              });
            }
          }

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(paymentRepositoryProvider);
              final profile = ref.read(authControllerProvider).profile!;

              await repo.recordPayment(
                studentId: dues.studentId,
                amount: double.parse(amountController.text),
                paymentDate: paymentDate,
                month: selectedMonth,
                year: selectedYear,
                mode: selectedMode,
                recordedBy: profile.id,
              );

              ref.invalidate(studentDuesProvider);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Payment recorded successfully!',
                      style: AppTheme.body2.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.textPrimary
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ErrorHandler.showError(context, 'Failed to record payment', e);
              }
            } finally {
              setState(() {
                _isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLime.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius10),
                  ),
                  child: const Icon(Icons.add_card_rounded, color: AppTheme.accentLime, size: 20),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    'Record Fee: ${dues.name}',
                    style: AppTheme.heading3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
                      ),
                    ),
                  )
                : Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Amount Paid (₹) *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter amount';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space12),
                          // Payment Date
                          InkWell(
                            onTap: pickDate,
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Payment Date',
                                suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                              ),
                              child: Text(
                                DateFormat('dd MMMM yyyy').format(paymentDate),
                                style: AppTheme.body1,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          // Month and Year Row
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedMonth,
                                  style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                                  decoration: const InputDecoration(labelText: 'Month'),
                                  items: List.generate(12, (i) => i + 1)
                                      .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(DateFormat('MMMM').format(DateTime(2020, m))),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) selectedMonth = val;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedYear,
                                  style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                                  decoration: const InputDecoration(labelText: 'Year'),
                                  items: [selectedYear - 1, selectedYear, selectedYear + 1]
                                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) selectedYear = val;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          // Payment Mode
                          DropdownButtonFormField<String>(
                            initialValue: selectedMode,
                            style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                            decoration: const InputDecoration(labelText: 'Payment Mode'),
                            items: const [
                              DropdownMenuItem(value: 'upi', child: Text('UPI')),
                              DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            ],
                            onChanged: (val) {
                              if (val != null) selectedMode = val;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentLime,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHistoryBottomSheet(StudentDues dues) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      builder: (ctx) {
        final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.space8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBorderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment History',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        dues.name,
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                const Divider(height: AppTheme.space24),
                Expanded(
                  child: FutureBuilder<List<Payment>>(
                    future: ref.read(paymentRepositoryProvider).getStudentPayments(dues.studentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime)));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: AppTheme.body2.copyWith(color: AppTheme.errorRed)));
                      }
                      final payments = snapshot.data ?? [];
                      if (payments.isEmpty) {
                        return Center(
                          child: Text(
                            'No recorded payments found.',
                            style: AppTheme.body2.copyWith(color: AppTheme.textMuted),
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: payments.length,
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.darkBorderSubtle),
                        itemBuilder: (context, index) {
                          final p = payments[index];
                          final monthName = DateFormat('MMMM').format(DateTime(2020, p.month));
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(AppTheme.space8),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.15)),
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.successGreen, size: 18),
                            ),
                            title: Text(
                              '${currencyFormat.format(p.amount)} - ${p.mode.toUpperCase()}',
                              style: AppTheme.subtitle2,
                            ),
                            subtitle: Text(
                              'For $monthName ${p.year}',
                              style: AppTheme.caption,
                            ),
                            trailing: Text(
                              DateFormat('dd MMM yyyy').format(p.paymentDate),
                              style: AppTheme.caption,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
