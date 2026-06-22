import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/expense.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ExpenseRepository(supabase);
});

/// Caches and returns image bytes for receipts from the private storage bucket.
final expenseReceiptBytesProvider = FutureProvider.family<Uint8List, String>((ref, path) async {
  final supabase = ref.watch(supabaseClientProvider);
  return await supabase.storage.from('expense_receipts').download(path);
});

class ExpenseRepository {
  final SupabaseClient _supabase;

  ExpenseRepository(this._supabase);

  /// Fetches all expenses. Admin only (blocked by RLS for coaches).
  Future<List<Expense>> getExpenses() async {
    final response = await _supabase
        .from('expenses')
        .select()
        .order('date', ascending: false);
    return (response as List).map((json) => Expense.fromJson(json)).toList();
  }

  /// Uploads a receipt to the private expense_receipts bucket.
  Future<String?> uploadReceipt(XFile receipt) async {
    final bytes = await receipt.readAsBytes();
    final fileExt = receipt.name.split('.').last;
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$fileExt';
    final path = 'receipts/$fileName';

    await _supabase.storage.from('expense_receipts').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: receipt.mimeType, upsert: true),
        );
    return path;
  }

  /// Creates an expense entry. Admin only.
  Future<void> createExpense({
    required String category,
    required double amount,
    required DateTime date,
    String? description,
    required String recordedBy,
    XFile? receipt,
  }) async {
    String? receiptPath;
    if (receipt != null) {
      receiptPath = await uploadReceipt(receipt);
    }

    await _supabase.from('expenses').insert({
      'category': category,
      'amount': amount,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'description': description,
      'receipt_url': receiptPath,
      'recorded_by': recordedBy,
    });
  }

  /// Updates an existing expense. Admin only.
  Future<void> updateExpense({
    required String id,
    required String category,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    await _supabase.from('expenses').update({
      'category': category,
      'amount': amount,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'description': description,
    }).eq('id', id);
  }

  /// Deletes an expense. Admin only.
  Future<void> deleteExpense(String id, {String? receiptUrl}) async {
    await _supabase.from('expenses').delete().eq('id', id);
    if (receiptUrl != null && receiptUrl.isNotEmpty) {
      try {
        await _supabase.storage.from('expense_receipts').remove([receiptUrl]);
      } catch (_) {}
    }
  }
}
