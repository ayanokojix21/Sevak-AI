import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

/// Riverpod provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    GoogleSignIn(
      serverClientId: '29483186959-kkfe05gcogr1s638h81ponal5du3gt7i.apps.googleusercontent.com',
    ),
  );
});

/// Implementation of [AuthRepository] using Firebase Auth.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository(this._firebaseAuth, this._googleSignIn);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw const UserNotFoundFailure();
      } else if (e.code == 'wrong-password') {
        throw const WrongPasswordFailure();
      }
      throw AuthFailure(e.message ?? 'An unknown authentication error occurred.');
    } catch (e) {
      throw const AuthFailure();
    }
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const EmailAlreadyInUseFailure();
      }
      throw AuthFailure(e.message ?? 'An unknown error occurred during signup.');
    } catch (e) {
      throw const AuthFailure();
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        throw const AuthFailure('Google sign in was canceled.');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Google sign in failed.');
    } catch (e) {
      throw const AuthFailure('An unexpected error occurred during Google sign in.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw const AuthFailure('Failed to sign out completely.');
    }
  }
}
