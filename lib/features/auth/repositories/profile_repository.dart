import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfileRepository(supabase);
});

final coachesListProvider = FutureProvider<List<Profile>>((ref) async {
  return ref.watch(profileRepositoryProvider).getCoaches();
});

/// Caches and returns image bytes for coach photos from the private storage bucket.
final coachPhotoBytesProvider = FutureProvider.family.autoDispose<Uint8List, String>((ref, path) async {
  final supabase = ref.watch(supabaseClientProvider);
  return await supabase.storage
      .from('coach_photos')
      .download(path)
      .timeout(const Duration(seconds: 20));
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

  /// Uploads photo to the private coach_photos bucket.
  Future<String?> uploadCoachPhoto(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final fileExt = photo.name.split('.').last;
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$fileExt';
    final path = 'coaches/$fileName';

    await _supabase.storage.from('coach_photos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: photo.mimeType, upsert: true),
        ).timeout(const Duration(seconds: 30));
    return path;
  }

  /// Invokes the RPC function to create a coach account.
  Future<void> createCoachUser({
    required String name,
    String? phone,
    required String email,
    required String password,
    String? degree,
    String? experience,
    String? speciality,
    String? achievements,
    String? photoUrl,
  }) async {
    await _supabase.rpc(
      'create_coach_user',
      params: {
        'coach_email': email,
        'coach_password': password,
        'coach_name': name,
        'coach_phone': phone,
        'coach_degree': degree,
        'coach_experience': experience,
        'coach_speciality': speciality,
        'coach_achievements': achievements,
        'coach_photo_url': photoUrl,
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

  /// Resets a coach's password securely (Admin only RPC).
  Future<void> resetCoachPassword(String coachId, String newPassword) async {
    await _supabase.rpc(
      'reset_coach_password',
      params: {
        'coach_id': coachId,
        'new_password': newPassword,
      },
    );
  }

  /// Updates a coach's profile details (Admin only RPC).
  Future<void> updateCoachProfile({
    required String coachId,
    required String name,
    required String phone,
    required String email,
    String? degree,
    String? experience,
    String? speciality,
    String? achievements,
    String? photoUrl,
  }) async {
    await _supabase.rpc(
      'update_coach_profile',
      params: {
        'coach_id': coachId,
        'new_name': name,
        'new_phone': phone,
        'new_email': email,
        'new_degree': degree,
        'new_experience': experience,
        'new_speciality': speciality,
        'new_achievements': achievements,
        'new_photo_url': photoUrl,
      },
    );
  }
}

