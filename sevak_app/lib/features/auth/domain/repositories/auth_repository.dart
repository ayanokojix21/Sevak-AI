import 'package:firebase_auth/firebase_auth.dart';

/// Interface defining the contract for Authentication operations.
/// This abstracts the authentication provider (Firebase) from the rest of the app.
abstract class AuthRepository {
  /// Stream of authentication state changes. Emits the current user or null if logged out.
  Stream<User?> get authStateChanges;

  /// Gets the currently logged in user synchronously.
  User? get currentUser;

  /// Signs in a user with email and password.
  /// Throws [AuthFailure], [WrongPasswordFailure], or [UserNotFoundFailure].
  Future<UserCredential> signInWithEmail(String email, String password);

  /// Registers a new user with email and password.
  /// Throws [AuthFailure] or [EmailAlreadyInUseFailure].
  Future<UserCredential> signUpWithEmail(String email, String password);

  /// Signs in or registers a user using their Google account.
  /// Throws [AuthFailure].
  Future<UserCredential> signInWithGoogle();

  /// Signs the current user out of the application.
  Future<void> signOut();
}
