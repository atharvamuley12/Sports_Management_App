import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/activity_repository.dart';
import '../../../shared/models/activity.dart';
import '../../auth/controllers/auth_controller.dart';

final activityListProvider = FutureProvider.family<List<Activity>, ({String? coachId, DateTime? date})>((ref, params) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.getActivities(coachId: params.coachId, date: params.date);
});

class ActivityController extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _repo;
  final Ref _ref;

  ActivityController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> addActivity({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authControllerProvider).user;
      if (user == null) throw Exception('User not logged in');

      final activity = Activity(
        id: '', // Supabase will generate this
        coachId: user.id,
        coachName: '', // Not needed for insert
        date: date,
        title: title,
        description: description,
        createdAt: DateTime.now(),
      );

      await _repo.createActivity(activity);
      state = const AsyncValue.data(null);
      _ref.invalidate(activityListProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateActivity(Activity activity) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateActivity(activity);
      state = const AsyncValue.data(null);
      _ref.invalidate(activityListProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteActivity(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteActivity(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(activityListProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _repo.updateStatus(id, status);
      _ref.invalidate(activityListProvider);
    } catch (e) {
      // Handle error
    }
  }
}

final activityControllerProvider = StateNotifierProvider<ActivityController, AsyncValue<void>>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return ActivityController(repo, ref);
});
