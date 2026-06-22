import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/payment.dart';
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search student by name...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(studentDuesProvider);
              },
              child: duesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading dues ledger: $err'),
                  ),
                ),
                data: (duesList) {
                  final filtered = duesList.where((d) => d.name.toLowerCase().contains(_searchQuery)).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No student records found.')),
                      ],
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      final dues = filtered[index];
                      final hasDues = dues.pendingDues > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      dues.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: hasDues ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.successGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: hasDues ? AppTheme.errorRed.withValues(alpha: 0.3) : AppTheme.successGreen.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      hasDues
                                          ? 'DUE: ${currencyFormat.format(dues.pendingDues)}'
                                          : 'PAID / NO DUES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: hasDues ? AppTheme.errorRed : AppTheme.successGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SelectableText(
                                    'Monthly Fee: ${currencyFormat.format(dues.monthlyFee)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  SelectableText(
                                    'Total Paid: ${currencyFormat.format(dues.totalPaid)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add_card_outlined, size: 18),
                                      label: const Text('Record Fee', style: TextStyle(fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _showRecordPaymentDialog(dues),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.history_rounded, size: 18),
                                      label: const Text('History', style: TextStyle(fontSize: 13)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _showHistoryBottomSheet(dues),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final formKey = GlobalKey<FormState>();
          final amountController = TextEditingController(
            text: dues.pendingDues > 0 ? dues.pendingDues.toString() : dues.monthlyFee.toString(),
          );
          DateTime paymentDate = DateTime.now();
          int selectedMonth = DateTime.now().month;
          int selectedYear = DateTime.now().year;
          String selectedMode = 'upi';

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: paymentDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
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
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment recorded successfully!')),
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
            title: Text('Record Fee: ${dues.name}'),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
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
                            decoration: const InputDecoration(labelText: 'Amount Paid (₹) *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter amount';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Payment Date
                          InkWell(
                            onTap: pickDate,
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Payment Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('dd MMMM yyyy').format(paymentDate)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Month and Year Row
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: selectedMonth,
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: selectedYear,
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
                          const SizedBox(height: 12),
                          // Payment Mode
                          DropdownButtonFormField<String>(
                            value: selectedMode,
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
      builder: (ctx) {
        final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Payment History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dues.name,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: FutureBuilder<List<Payment>>(
                      future: ref.read(paymentRepositoryProvider).getStudentPayments(dues.studentId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        final payments = snapshot.data ?? [];
                        if (payments.isEmpty) {
                          return const Center(child: Text('No recorded payments found for this student.'));
                        }
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: payments.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = payments[index];
                            final monthName = DateFormat('MMMM').format(DateTime(2020, p.month));
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.successGreen, size: 20),
                              ),
                              title: Text(
                                '${currencyFormat.format(p.amount)} - ${p.mode.toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                'For $monthName ${p.year}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              trailing: Text(
                                DateFormat('dd MMM yyyy').format(p.paymentDate),
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
