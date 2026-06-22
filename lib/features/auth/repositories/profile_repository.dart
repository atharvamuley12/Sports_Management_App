import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfileRepository(supabase);
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  /// Fetches a single profile by [id].
  Future<Profile?> getProfile(String id) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Updates the user's password and sets [must_change_password] to false.
  Future<void> updatePasswordAndResetFlag(String newPassword) async {
    // Update Auth user password
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    // Set must_change_password = false on the profile
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase
          .from('profiles')
          .update({'must_change_password': false})
          .eq('id', userId);
    }
  }

  /// Invokes the RPC function to create a coach account.
  Future<void> createCoachUser({
    required String name,
    String? phone,
    required String email,
    required String password,
  }) async {
    await _supabase.rpc(
      'create_coach_user',
      params: {
        'coach_email': email,
        'coach_password': password,
        'coach_name': name,
        'coach_phone': phone,
      },
    );
  }

  /// Fetches all profiles with role 'coach'.
  Future<List<Profile>> getCoaches() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'coach')
        .order('full_name', ascending: true);
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  /// Toggles the active status of a coach.
  Future<void> toggleCoachActive(String id, bool isActive) async {
    await _supabase
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}
