import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/batch.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BatchRepository(supabase);
});

class BatchRepository {
  final SupabaseClient _supabase;

  BatchRepository(this._supabase);

  /// Fetches all batches. Under RLS, a coach will only receive their own batch.
  Future<List<Batch>> getBatches() async {
    final response = await _supabase
        .from('batches')
        .select()
        .order('name', ascending: true);
    return (response as List).map((json) => Batch.fromJson(json)).toList();
  }

  /// Inserts a new batch. Admin only.
  Future<void> createBatch({
    required String name,
    required String sport,
    String? coachId,
    required int capacity,
    required List<String> days,
    String? startTime,
    String? endTime,
  }) async {
    await _supabase.from('batches').insert({
      'name': name,
      'sport': sport,
      'coach_id': coachId,
      'capacity': capacity,
      'days': days,
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  /// Updates an existing batch. Admin only.
  Future<void> updateBatch({
    required String id,
    required String name,
    required String sport,
    String? coachId,
    required int capacity,
    required List<String> days,
    String? startTime,
    String? endTime,
  }) async {
    await _supabase.from('batches').update({
      'name': name,
      'sport': sport,
      'coach_id': coachId,
      'capacity': capacity,
      'days': days,
      'start_time': startTime,
      'end_time': endTime,
    }).eq('id', id);
  }

  /// Deletes a batch. Admin only.
  Future<void> deleteBatch(String id) async {
    await _supabase.from('batches').delete().eq('id', id);
  }

  /// Gets student count assigned to a specific batch
  Future<int> getStudentCountForBatch(String batchId) async {
    final response = await _supabase
        .from('students')
        .select('id')
        .eq('batch_id', batchId);
    return (response as List).length;
  }

  /// Maps a list of student IDs to a batch, clearing previous students
  Future<void> updateBatchStudents(String batchId, List<String> studentIds) async {
    // 1. Clear batch_id for students currently in this batch
    await _supabase
        .from('students')
        .update({'batch_id': null})
        .eq('batch_id', batchId);
    
    // 2. Set batch_id for selected students
    if (studentIds.isNotEmpty) {
      await _supabase
          .from('students')
          .update({'batch_id': batchId})
          .inFilter('id', studentIds);
    }
  }
}

