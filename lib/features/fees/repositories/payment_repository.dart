import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/payment.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PaymentRepository(supabase);
});

class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository(this._supabase);

  /// Fetches all payment transactions. Admin only.
  Future<List<Payment>> getPayments() async {
    final response = await _supabase
        .from('payments')
        .select()
        .order('payment_date', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  /// Fetches payment transactions for a specific student. Admin only.
  Future<List<Payment>> getStudentPayments(String studentId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .order('payment_date', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  /// Records a new student payment. Admin only.
  Future<void> recordPayment({
    required String studentId,
    required double amount,
    required DateTime paymentDate,
    required int month,
    required int year,
    required String mode, // 'cash' | 'upi'
    required String recordedBy,
  }) async {
    await _supabase.from('payments').insert({
      'student_id': studentId,
      'amount': amount,
      'payment_date': "${paymentDate.year.toString().padLeft(4, '0')}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}",
      'month': month,
      'year': year,
      'mode': mode,
      'recorded_by': recordedBy,
    });
  }

  /// Queries the student_dues view. Admin only.
  Future<List<StudentDues>> getStudentDues() async {
    final response = await _supabase
        .from('student_dues')
        .select()
        .order('pending_dues', ascending: false);
    return (response as List).map((json) => StudentDues.fromJson(json)).toList();
  }
}
