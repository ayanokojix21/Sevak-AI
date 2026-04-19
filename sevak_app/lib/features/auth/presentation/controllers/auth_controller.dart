import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/volunteer.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/user_repository.dart';

/// Provider exposing the current authentication state (User?)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provider exposing the complete Volunteer profile data for the current user
final volunteerProfileProvider = FutureProvider<Volunteer?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  
  return ref.watch(userRepositoryProvider).getVolunteerProfile(user.uid);
});

/// Controller to handle authentication actions and loading states
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthController(this._authRepository, this._userRepository) : super(const AsyncValue.data(null));

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmail(email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _authRepository.signUpWithEmail(email, password);
      
      // Initialize the volunteer profile in Firestore
      if (cred.user != null) {
        final volunteer = Volunteer(
          uid: cred.user!.uid,
          name: name,
          email: email,
          phone: phone,
          ngoId: '', // Unassigned initially
          skills: [], // Can be filled later
          createdAt: DateTime.now(),
        );
        await _userRepository.saveVolunteerProfile(volunteer);
      }
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final cred = await _authRepository.signInWithGoogle();
      
      // Check if profile exists, if not, create a base profile
      if (cred.user != null) {
        final existingProfile = await _userRepository.getVolunteerProfile(cred.user!.uid);
        
        if (existingProfile == null) {
          final volunteer = Volunteer(
            uid: cred.user!.uid,
            name: cred.user!.displayName ?? 'New Volunteer',
            email: cred.user!.email ?? '',
            phone: cred.user!.phoneNumber ?? '',
            ngoId: '',
            skills: [],
            createdAt: DateTime.now(),
          );
          await _userRepository.saveVolunteerProfile(volunteer);
        }
      }
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
