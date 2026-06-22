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
  Future<void> createBatch(String name, String sport, String? coachId) async {
    await _supabase.from('batches').insert({
      'name': name,
      'sport': sport,
      'coach_id': coachId,
    });
  }

  /// Updates an existing batch. Admin only.
  Future<void> updateBatch(String id, String name, String sport, String? coachId) async {
    await _supabase.from('batches').update({
      'name': name,
      'sport': sport,
      'coach_id': coachId,
    }).eq('id', id);
  }

  /// Deletes a batch. Admin only.
  Future<void> deleteBatch(String id) async {
    await _supabase.from('batches').delete().eq('id', id);
  }
}
