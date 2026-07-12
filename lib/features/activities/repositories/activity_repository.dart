import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/activity.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ActivityRepository(supabase);
});

class ActivityRepository {
  final SupabaseClient _supabase;

  ActivityRepository(this._supabase);

  Future<List<Activity>> getActivities({String? coachId, DateTime? date}) async {
    var query = _supabase.from('activities').select('*, profiles(full_name)');

    if (coachId != null) {
      query = query.eq('coach_id', coachId);
    }

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query = query.eq('date', dateStr);
    }

    final response = await query.order('date', ascending: false).order('created_at', ascending: false);
    
    return (response as List).map((json) {
      // Flatten the join result for coach_name
      final coachName = json['profiles']?['full_name'] as String?;
      final activityJson = Map<String, dynamic>.from(json);
      activityJson['coach_name'] = coachName;
      return Activity.fromJson(activityJson);
    }).toList();
  }

  Future<void> createActivity(Activity activity) async {
    await _supabase.from('activities').insert(activity.toJson());
  }

  Future<void> updateActivity(Activity activity) async {
    await _supabase.from('activities').update(activity.toJson()).eq('id', activity.id);
  }

  Future<void> deleteActivity(String id) async {
    await _supabase.from('activities').delete().eq('id', id);
  }

  Future<void> updateStatus(String id, String status) async {
    await _supabase.from('activities').update({'status': status}).eq('id', id);
  }
}
