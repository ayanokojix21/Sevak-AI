import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env_config.dart';

import '../core/constants/super_admin_config.dart';
import '../features/auth/data/datasources/invite_codes_datasource.dart';
import '../features/auth/data/repositories/firebase_auth_repository.dart';
import '../features/auth/data/repositories/user_repository.dart';
import '../features/auth/domain/entities/volunteer.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

export '../features/auth/presentation/controllers/auth_controller.dart';

final inviteCodeDatasourceProvider = Provider<InviteCodesDatasource>((ref) {
  return InviteCodesDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    GoogleSignIn(
      clientId: kIsWeb ? EnvConfig.googleServerClientId : null,
      serverClientId: kIsWeb ? null : EnvConfig.googleServerClientId,
    ),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

/// Stream of Firebase Auth state (User? — logged in or not).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Real-time stream of the complete Volunteer profile.
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
