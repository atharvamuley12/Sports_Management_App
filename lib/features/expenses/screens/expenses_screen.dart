import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/expense.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/expense_repository.dart';
import '../../../core/utils/error_handler.dart';

final expensesListProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return await expenseRepo.getExpenses();
});

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  bool _isSaving = false;

  String _formatCategory(String cat) {
    return cat.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Registry'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogExpenseDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesListProvider);
        },
        child: expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading expenses: $err'),
            ),
          ),
          data: (expenses) {
            if (expenses.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No expenses recorded yet.')),
                ],
              );
            }

            return ListView.builder(
              itemCount: expenses.length,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _formatCategory(expense.category),
                                style: const TextStyle(fontSize: 10, color: AppTheme.errorRed, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                            ),
                            SelectableText(
                              currencyFormat.format(expense.amount),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.errorRed),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (expense.description != null && expense.description!.isNotEmpty) ...[
                          SelectableText(
                            expense.description!,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SelectableText(
                              DateFormat('dd MMM yyyy').format(expense.date),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _showReceiptPreview(expense.receiptUrl!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentLime.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.accentLime.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.receipt_long, size: 14, color: AppTheme.accentLime),
                                        SizedBox(width: 4),
                                        Text('View Receipt', style: TextStyle(fontSize: 10, color: AppTheme.accentLime, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Text('No Receipt', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit', style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () => _showEditExpenseDialog(expense),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
                                label: const Text('Delete', style: TextStyle(fontSize: 13, color: AppTheme.errorRed)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.4)),
                                ),
                                onPressed: () => _confirmDeleteExpense(expense),
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
    );
  }

  void _showLogExpenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final formKey = GlobalKey<FormState>();
          final amountController = TextEditingController();
          final descController = TextEditingController();

          String selectedCategory = 'equipment';
          DateTime expenseDate = DateTime.now();
          XFile? receiptFile;
          final picker = ImagePicker();

          Future<void> pickImage(ImageSource source) async {
            final file = await picker.pickImage(source: source, imageQuality: 70);
            if (file != null) {
              setState(() {
                receiptFile = file;
              });
            }
          }

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: expenseDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                expenseDate = picked;
              });
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(expenseRepositoryProvider);
              final profile = ref.read(authControllerProvider).profile!;

              await repo.createExpense(
                category: selectedCategory,
                amount: double.parse(amountController.text),
                date: expenseDate,
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                recordedBy: profile.id,
                receipt: receiptFile,
              );

              ref.invalidate(expensesListProvider);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense logged successfully!')),
                );
              }
            } catch (e) {
              if (mounted) {
                ErrorHandler.showError(context, 'Failed to log expense', e);
              }
            } finally {
              setState(() {
                _isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Log Expense'),
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
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: const InputDecoration(labelText: 'Category *'),
                            items: const [
                              DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                              DropdownMenuItem(value: 'cricket_pitch', child: Text('Cricket Pitch')),
                              DropdownMenuItem(value: 'football_ground', child: Text('Football Ground')),
                              DropdownMenuItem(value: 'shed_construction', child: Text('Shed Construction')),
                              DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                              DropdownMenuItem(value: 'salary', child: Text('Salary')),
                              DropdownMenuItem(value: 'misc', child: Text('Miscellaneous')),
                            ],
                            onChanged: (val) {
                              if (val != null) selectedCategory = val;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Amount (₹) *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter amount';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: pickDate,
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('dd MMMM yyyy').format(expenseDate)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descController,
                            decoration: const InputDecoration(labelText: 'Description / Remarks'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          // Receipt Image Selector
                          const Text('Attach Receipt Receipt (Optional)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (bctx) => SafeArea(
                                    child: Wrap(
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.camera_alt),
                                          title: const Text('Capture Camera'),
                                          onTap: () {
                                            Navigator.of(bctx).pop();
                                            pickImage(ImageSource.camera);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.photo_library),
                                          title: const Text('Choose Library'),
                                          onTap: () {
                                            Navigator.of(bctx).pop();
                                            pickImage(ImageSource.gallery);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.lime, style: BorderStyle.solid),
                                ),
                                child: receiptFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(receiptFile!.path), fit: BoxFit.cover),
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, color: Colors.lime),
                                            SizedBox(height: 4),
                                            Text('Add Photo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
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
                onPressed: _isSaving ? null : save,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReceiptPreview(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receipt Attachment'),
        content: Consumer(
          builder: (context, ref, child) {
            final bytesAsync = ref.watch(expenseReceiptBytesProvider(path));
            return bytesAsync.when(
              data: (bytes) => Image.memory(bytes, fit: BoxFit.contain),
              loading: () => const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('Failed to load image: $err'),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final formKey = GlobalKey<FormState>();
          final amountController = TextEditingController(text: expense.amount.toStringAsFixed(0));
          final descController = TextEditingController(text: expense.description ?? '');

          String selectedCategory = expense.category;
          DateTime expenseDate = expense.date;

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: expenseDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                expenseDate = picked;
              });
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(expenseRepositoryProvider);
              await repo.updateExpense(
                id: expense.id,
                category: selectedCategory,
                amount: double.parse(amountController.text),
                date: expenseDate,
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
              );

              ref.invalidate(expensesListProvider);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense updated successfully!')),
                );
              }
            } catch (e) {
              if (mounted) {
                ErrorHandler.showError(context, 'Failed to update expense', e);
              }
            } finally {
              setState(() {
                _isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Edit Expense'),
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
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: const InputDecoration(labelText: 'Category *'),
                            items: const [
                              DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                              DropdownMenuItem(value: 'cricket_pitch', child: Text('Cricket Pitch')),
                              DropdownMenuItem(value: 'football_ground', child: Text('Football Ground')),
                              DropdownMenuItem(value: 'shed_construction', child: Text('Shed Construction')),
                              DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                              DropdownMenuItem(value: 'salary', child: Text('Salary')),
                              DropdownMenuItem(value: 'misc', child: Text('Miscellaneous')),
                            ],
                            onChanged: (val) {
                              if (val != null) selectedCategory = val;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Amount (₹) *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter amount';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: pickDate,
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('dd MMMM yyyy').format(expenseDate)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descController,
                            decoration: const InputDecoration(labelText: 'Description / Remarks'),
                            maxLines: 2,
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
                onPressed: _isSaving ? null : save,
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteExpense(Expense expense) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete the expense for ${currencyFormat.format(expense.amount)} (${_formatCategory(expense.category)})? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(expenseRepositoryProvider);
                await repo.deleteExpense(expense.id, receiptUrl: expense.receiptUrl);
                ref.invalidate(expensesListProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorHandler.showError(context, 'Failed to delete expense', e);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
