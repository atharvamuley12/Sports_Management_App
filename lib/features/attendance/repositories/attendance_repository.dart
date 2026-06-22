import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/attendance.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AttendanceRepository(supabase);
});

class AttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository(this._supabase);

  /// Fetches attendance records for a specific [batchId] and [date].
  Future<List<Attendance>> getAttendanceForBatchAndDate(String batchId, DateTime date) async {
    final formattedDate = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    final response = await _supabase
        .from('attendance')
        .select('*, students!inner(batch_id)')
        .eq('date', formattedDate)
        .eq('students.batch_id', batchId);
        
    return (response as List).map((json) => Attendance.fromJson(json)).toList();
  }

  /// Bulk inserts attendance records.
  /// If database constraints are violated (e.g. duplicate for the day), it throws.
  Future<void> saveAttendanceEntries(List<Map<String, dynamic>> entries) async {
    await _supabase.from('attendance').insert(entries);
  }

  /// Bulk upserts attendance records (Admin only, as RLS blocks update policy for coaches).
  Future<void> upsertAttendanceEntries(List<Map<String, dynamic>> entries) async {
    await _supabase.from('attendance').upsert(entries, onConflict: 'student_id,date');
  }

  /// Updates a single attendance status (Admin only).
  Future<void> updateAttendanceEntry({
    required String id,
    required String status,
  }) async {
    await _supabase.from('attendance').update({
      'status': status,
    }).eq('id', id);
  }
}
