import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/super_admin_config.dart';
import '../../domain/entities/volunteer.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/datasources/invite_codes_datasource.dart';

// ── Providers ────────────────────────────────────────────────────────────────

/// Stream of Firebase Auth state (User? — logged in or not).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Real-time stream of the complete Volunteer profile.
/// StreamProvider ensures UI updates instantly when Firestore data changes.
final volunteerProfileProvider = StreamProvider<Volunteer?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).streamVolunteerProfile(user.uid);
});

/// Streams staff (CO + NA) for a specific NGO.
final ngoStaffProvider =
    StreamProvider.family<List<Volunteer>, String>((ref, ngoId) {
  return ref.watch(userRepositoryProvider).streamNgoStaff(ngoId);
});

/// Streams ALL members for a specific NGO.
final ngoMembersProvider =
    StreamProvider.family<List<Volunteer>, String>((ref, ngoId) {
  return ref.watch(userRepositoryProvider).streamNgoMembers(ngoId);
});

/// Auth controller for actions (sign in, sign up, invite code, etc.).
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(inviteCodeDatasourceProvider),
    ref.watch(superAdminConfigProvider),
  );
});

// ── Controller ───────────────────────────────────────────────────────────────

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final InviteCodesDatasource _inviteCodesDatasource;
  final SuperAdminConfig _saConfig;

  AuthController(
    this._authRepository,
    this._userRepository,
    this._inviteCodesDatasource,
    this._saConfig,
  ) : super(const AsyncValue.data(null));

  /// ── SIGN IN (Email) ─────────────────────────────────────────────────────
  /// After authentication, checks if the user's role needs upgrading to SA.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _authRepository.signInWithEmail(email, password);

      // Post-login role reconciliation
      if (cred.user != null) {
        await _reconcileRole(cred.user!.uid, email);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ── SIGN UP (Email) ─────────────────────────────────────────────────────
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _authRepository.signUpWithEmail(email, password);

      if (cred.user != null) {
        final isSA = _saConfig.isSuperAdmin(email);
        final volunteer = Volunteer(
          uid: cred.user!.uid,
          name: name,
          email: email,
          phone: phone,
          primaryNgoId: '',
          ngoMemberships: const [],
          platformRole: isSA ? 'SA' : 'CU',
          skills: [],
          isProfileComplete: false,
          createdAt: DateTime.now(),
        );
        await _userRepository.saveVolunteerProfile(volunteer);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ── GOOGLE SIGN IN ──────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final cred = await _authRepository.signInWithGoogle();

      if (cred.user != null) {
        final email = cred.user!.email ?? '';
        final existingProfile =
            await _userRepository.getVolunteerProfile(cred.user!.uid);

        if (existingProfile == null) {
          // Brand new user
          final isSA = _saConfig.isSuperAdmin(email);
          final volunteer = Volunteer(
            uid: cred.user!.uid,
            name: cred.user!.displayName ?? 'New User',
            email: email,
            phone: cred.user!.phoneNumber ?? '',
            primaryNgoId: '',
            ngoMemberships: const [],
            platformRole: isSA ? 'SA' : 'CU',
            skills: [],
            isProfileComplete: false,
            createdAt: DateTime.now(),
          );
          await _userRepository.saveVolunteerProfile(volunteer);
        } else {
          // Existing user — reconcile role (might need SA upgrade)
          await _reconcileRole(cred.user!.uid, email);
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ── SIGN OUT ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ── PROFILE SETUP ───────────────────────────────────────────────────────
  /// Saves updated profile data from the profile setup form.
  Future<void> completeProfileSetup({
    required String name,
    required String phone,
    required String city,
    required List<String> skills,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _authRepository.currentUser;
      if (user == null) throw Exception('Not logged in');

      final existing = await _userRepository.getVolunteerProfile(user.uid);
      if (existing == null) throw Exception('Profile not found');

      final updated = existing.copyWith(
        name: name,
        phone: phone,
        city: city,
        skills: skills,
        isProfileComplete: true,
      );
      await _userRepository.saveVolunteerProfile(updated);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ── INVITE CODE ─────────────────────────────────────────────────────────
  /// Redeems an invite code to join an NGO with a specific role.
  Future<void> consumeInviteCode(String code) async {
    state = const AsyncValue.loading();
    try {
      final user = _authRepository.currentUser;
      if (user == null) throw Exception('Not logged in');

      final inviteCode = await _inviteCodesDatasource.getInviteCode(code);
      if (inviteCode == null) throw Exception('Invalid Invite Code');

      // Block SA/NA assignment via invite codes
      if (inviteCode.targetRole == 'SA' || inviteCode.targetRole == 'NA') {
        throw Exception('${inviteCode.targetRole} role cannot be assigned via invite code');
      }

      final existingProfile =
          await _userRepository.getVolunteerProfile(user.uid);
      if (existingProfile == null) throw Exception('Profile not found');

      // Prevent duplicate membership
      if (existingProfile.isMemberOf(inviteCode.ngoId)) {
        throw Exception('You are already a member of this NGO');
      }

      // Build updated ngoMemberships array
      final newMembership = NgoMembership(
        ngoId: inviteCode.ngoId,
        role: inviteCode.targetRole,
        crossNgoConsent: false,
        status: 'active',
      );
      final updatedMemberships = [
        ...existingProfile.ngoMemberships,
        newMembership,
      ];

      // Determine new platformRole — take the highest role
      // BUT never downgrade SA via invite code
      final newRole = _highestRole(
        existingProfile.platformRole,
        inviteCode.targetRole,
      );

      final updatedProfile = existingProfile.copyWith(
        primaryNgoId: existingProfile.primaryNgoId.isEmpty
            ? inviteCode.ngoId
            : existingProfile.primaryNgoId,
        ngoMemberships: updatedMemberships,
        platformRole: newRole,
      );

      await _userRepository.saveVolunteerProfile(updatedProfile);

      if (inviteCode.isSingleUse) {
        await _inviteCodesDatasource.deleteInviteCode(code);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  /// Reconciles a user's Firestore role on every login.
  /// If their email is in the SA list but their role isn't SA, upgrades them.
  /// This fixes users who signed up before SA config was added.
  Future<void> _reconcileRole(String uid, String email) async {
    try {
      final profile = await _userRepository.getVolunteerProfile(uid);
      if (profile == null) return;

      final shouldBeSA = _saConfig.isSuperAdmin(email);

      if (shouldBeSA && profile.platformRole != 'SA') {
        debugPrint('[AuthController] Upgrading ${profile.email} to SA');
        final updated = profile.copyWith(platformRole: 'SA');
        await _userRepository.saveVolunteerProfile(updated);
      }
    } catch (e) {
      debugPrint('[AuthController] Role reconciliation failed: $e');
      // Non-fatal — don't block login
    }
  }

  /// Returns the higher-privileged role between two role codes.
  String _highestRole(String currentRole, String newRole) {
    const hierarchy = {'CU': 0, 'VL': 1, 'CO': 2, 'NA': 3, 'SA': 4};
    final currentLevel = hierarchy[currentRole] ?? 0;
    final newLevel = hierarchy[newRole] ?? 0;
    return newLevel > currentLevel ? newRole : currentRole;
  }
}
