import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/super_admin_config.dart';
import '../../../../core/services/prefs_service.dart';
import '../../domain/entities/volunteer.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/datasources/invite_codes_datasource.dart';

// Providers moved to lib/providers/auth_providers.dart


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

  /// After authentication, checks if the user's role needs upgrading to SA.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _authRepository.signInWithEmail(email, password);

      if (cred.user != null) {
        // Post-login role reconciliation
        await _reconcileRole(cred.user!.uid, email);
        // Persist UID for WorkManager background isolate
        await PrefsService.saveVolunteerUid(cred.user!.uid);
      }

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
          isProfileComplete: true, // Community users do not need to complete volunteer profile initially
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
            isProfileComplete: true,
            createdAt: DateTime.now(),
          );
          await _userRepository.saveVolunteerProfile(volunteer);
        } else {
          // Existing user — reconcile role (might need SA upgrade)
          await _reconcileRole(cred.user!.uid, email);
        }
        // Persist UID for WorkManager background isolate
        await PrefsService.saveVolunteerUid(cred.user!.uid);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final cred = await _authRepository.signInAnonymously();

      if (cred.user != null) {
        final existingProfile =
            await _userRepository.getVolunteerProfile(cred.user!.uid);

        if (existingProfile == null) {
          final volunteer = Volunteer(
            uid: cred.user!.uid,
            name: 'Anonymous User',
            email: 'anonymous_${cred.user!.uid.substring(0, 5)}@sevakai.local',
            phone: '',
            primaryNgoId: '',
            ngoMemberships: const [],
            platformRole: 'CU',
            skills: [],
            isProfileComplete: true,
            createdAt: DateTime.now(),
          );
          await _userRepository.saveVolunteerProfile(volunteer);
        }
        // Persist UID for WorkManager background isolate
        await PrefsService.saveVolunteerUid(cred.user!.uid);
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
      // Remove UID so WorkManager stops sending location updates
      await PrefsService.clearVolunteerUid();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

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

  /// Redeems an invite code to join an NGO with a specific role.
  Future<void> consumeInviteCode(String code) async {
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
  }


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
