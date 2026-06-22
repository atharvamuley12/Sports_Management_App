import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/profile.dart';
import '../repositories/profile_repository.dart';

class AuthStateData {
  final supabase.User? user;
  final Profile? profile;
  final bool isLoading;
  final String? errorMessage;

  AuthStateData({
    this.user,
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthStateData copyWith({
    supabase.User? user,
    Profile? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return AuthStateData(
      user: user ?? this.user,
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthStateData> {
  final supabase.SupabaseClient _client;
  final ProfileRepository _profileRepo;

  AuthController(this._client, this._profileRepo) : super(AuthStateData()) {
    _init();
  }

  void _init() {
    _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (session == null || event == supabase.AuthChangeEvent.signedOut) {
        state = AuthStateData();
      } else {
        state = state.copyWith(user: session.user, isLoading: true);
        await _fetchProfile(session.user.id);
      }
    });

    // Check initial session
    final session = _client.auth.currentSession;
    if (session != null) {
      state = state.copyWith(user: session.user, isLoading: true);
      _fetchProfile(session.user.id);
    }
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      // 1. Try to ensure the profile exists in the DB
      try {
        await _client.rpc('create_profile_if_missing');
      } catch (_) {
        // Silent catch if the database function doesn't exist yet
      }

      // 2. Fetch the profile
      var profile = await _profileRepo.getProfile(userId);

      // 3. Construct a fallback profile locally if it's still missing from the database
      if (profile == null) {
        final currentUser = _client.auth.currentUser;
        if (currentUser != null) {
          final metadata = currentUser.userMetadata ?? {};
          profile = Profile(
            id: currentUser.id,
            fullName: metadata['full_name'] as String? ?? currentUser.email?.split('@').first ?? 'User',
            phone: metadata['phone'] as String?,
            role: metadata['role'] as String? ?? 'coach',
            isActive: true,
            mustChangePassword: false,
            createdAt: DateTime.now(),
          );
        }
      }

      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to fetch user profile: $e',
        isLoading: false,
      );
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is supabase.AuthException ? e.message : e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is supabase.AuthException ? e.message : e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _client.auth.signOut();
    } catch (_) {}
    state = AuthStateData();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _profileRepo.updatePasswordAndResetFlag(newPassword);
      // Reload profile
      if (state.user != null) {
        await _fetchProfile(state.user!.id);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStateData>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  return AuthController(client, profileRepo);
});
