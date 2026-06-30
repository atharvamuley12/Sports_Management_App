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
import '../../../shared/widgets/app_widgets.dart';

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

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'equipment':
        return AppTheme.accentLime;
      case 'cricket_pitch':
        return AppTheme.accentOrange;
      case 'football_ground':
        return AppTheme.accentTeal;
      case 'shed_construction':
        return AppTheme.accentPurple;
      case 'maintenance':
        return AppTheme.infoBlue;
      case 'salary':
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
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
        child: const Icon(Icons.add_rounded, size: 24),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          ref.invalidate(expensesListProvider);
        },
        child: expensesAsync.when(
          loading: () => const AppLoadingState(itemCount: 4, itemHeight: 150),
          error: (err, stack) => AppErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(expensesListProvider),
          ),
          data: (expenses) {
            if (expenses.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'No expenses recorded yet',
                    subtitle: 'Use the floating action button below to log a new expense.',
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: expenses.length,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final catColor = _getCategoryColor(expense.category);

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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space10,
                                vertical: AppTheme.space4,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppTheme.radius8),
                                border: Border.all(color: catColor.withValues(alpha: 0.15), width: 0.5),
                              ),
                              child: Text(
                                _formatCategory(expense.category),
                                style: AppTheme.overline.copyWith(
                                  fontSize: 9,
                                  color: catColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              currencyFormat.format(expense.amount),
                              style: AppTheme.subtitle1.copyWith(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space12),
                        if (expense.description != null && expense.description!.isNotEmpty) ...[
                          Text(
                            expense.description!,
                            style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: AppTheme.space12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_rounded, size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: AppTheme.space4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(expense.date),
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                            if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _showReceiptPreview(expense.receiptUrl!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space10,
                                      vertical: AppTheme.space4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentLime.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                                      border: Border.all(color: AppTheme.accentLime.withValues(alpha: 0.15), width: 0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.receipt_long_rounded, size: 12, color: AppTheme.accentLime),
                                        const SizedBox(width: AppTheme.space4),
                                        Text(
                                          'VIEW RECEIPT',
                                          style: AppTheme.overline.copyWith(
                                            fontSize: 9,
                                            color: AppTheme.accentLime,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                'No Receipt Attached',
                                style: AppTheme.caption.copyWith(fontSize: 10),
                              ),
                          ],
                        ),
                        const Divider(height: AppTheme.space24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit_outlined, size: 14),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radius10),
                                    ),
                                    textStyle: AppTheme.buttonText.copyWith(fontSize: 12),
                                  ),
                                  onPressed: () => _showEditExpenseDialog(expense),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.errorRed),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: AppTheme.errorRed,
                                    side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radius10),
                                    ),
                                    textStyle: AppTheme.buttonText.copyWith(fontSize: 12),
                                  ),
                                  onPressed: () => _confirmDeleteExpense(expense),
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
    );
  }

  void _showLogExpenseDialog() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'equipment';
    DateTime expenseDate = DateTime.now();
    XFile? receiptFile;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {


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
              context: dialogCtx,
              initialDate: expenseDate,
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
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Expense logged successfully!',
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
                ErrorHandler.showError(context, 'Failed to log expense', e);
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
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.errorRed, size: 20),
                ),
                const SizedBox(width: AppTheme.space12),
                Text('Log Expense', style: AppTheme.heading3),
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
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Amount (₹) *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter amount';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space12),
                          InkWell(
                            onTap: pickDate,
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                              ),
                              child: Text(
                                DateFormat('dd MMMM yyyy').format(expenseDate),
                                style: AppTheme.body1,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: descController,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Description / Remarks'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppTheme.space16),
                          Text(
                            'Attach Receipt (Optional)', 
                            style: AppTheme.caption,
                          ),
                          const SizedBox(height: AppTheme.space8),
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
                                          leading: const Icon(Icons.camera_alt_rounded),
                                          title: const Text('Capture Camera'),
                                          onTap: () {
                                            Navigator.of(bctx).pop();
                                            pickImage(ImageSource.camera);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.photo_library_rounded),
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
                                height: 110,
                                decoration: BoxDecoration(
                                  color: AppTheme.darkBg,
                                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                                  border: Border.all(color: AppTheme.darkBorder),
                                ),
                                child: receiptFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                                        child: Image.file(File(receiptFile!.path), fit: BoxFit.cover),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, color: AppTheme.accentLime, size: 24),
                                            const SizedBox(height: AppTheme.space4),
                                            Text(
                                              'Add Photo', 
                                              style: AppTheme.caption.copyWith(fontSize: 10),
                                            ),
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

  void _showReceiptPreview(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppTheme.accentLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius10),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.accentLime, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Text('Receipt Attachment', style: AppTheme.heading3),
          ],
        ),
        content: Consumer(
          builder: (context, ref, child) {
            final bytesAsync = ref.watch(expenseReceiptBytesProvider(path));
            return bytesAsync.when(
              data: (bytes) => Container(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              loading: () => const SizedBox(
                height: 150,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
                  ),
                ),
              ),
              error: (err, stack) => Text('Failed to load image: $err', style: AppTheme.caption.copyWith(color: AppTheme.errorRed)),
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
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: expense.amount.toStringAsFixed(0));
    final descController = TextEditingController(text: expense.description ?? '');
    String selectedCategory = expense.category;
    DateTime expenseDate = expense.date;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {


          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: dialogCtx,
              initialDate: expenseDate,
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
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Expense updated successfully!',
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
                ErrorHandler.showError(context, 'Failed to update expense', e);
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
                  child: const Icon(Icons.edit_rounded, color: AppTheme.accentLime, size: 20),
                ),
                const SizedBox(width: AppTheme.space12),
                Text('Edit Expense', style: AppTheme.heading3),
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
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Amount (₹) *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter amount';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space12),
                          InkWell(
                            onTap: pickDate,
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                              ),
                              child: Text(
                                DateFormat('dd MMMM yyyy').format(expenseDate),
                                style: AppTheme.body1,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: descController,
                            style: AppTheme.body1,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentLime,
                  foregroundColor: Colors.black,
                ),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Text('Delete Expense', style: AppTheme.heading3),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the expense for ${currencyFormat.format(expense.amount)} (${_formatCategory(expense.category)})? This action cannot be undone.',
          style: AppTheme.body2.copyWith(height: 1.4),
        ),
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
                    SnackBar(
                      content: Text(
                        'Expense deleted successfully!',
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
                  ErrorHandler.showError(context, 'Failed to delete expense', e);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
