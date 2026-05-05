import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import 'auth_exceptions.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Check if the current user's email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Login with email and password.
  /// Throws [EmailNotVerifiedException] if email is not verified.
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Reload to get the latest emailVerified status
        await result.user!.reload();
        final refreshedUser = _auth.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          // Sign out the unverified user
          await _auth.signOut();
          throw EmailNotVerifiedException(email);
        }

        // Update Firestore verification status if needed
        await _updateEmailVerificationStatus(refreshedUser!.uid, true);

        return await _userService.getUser(refreshedUser.uid);
      }
      return null;
    } on EmailNotVerifiedException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Register a new user with email verification.
  /// After registration, a verification email is sent automatically.
  /// The user remains signed in so we can send the verification email,
  /// but they must verify before they can use the app.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    UserRole role = UserRole.PATIENT,
  }) async {
    try {
      debugPrint('[AuthService] Starting registration for: $email');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('[AuthService] User created: ${result.user?.uid}');

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(fullName);

        // Create user document in Firestore
        final newUser = UserModel(
          userId: result.user!.uid,
          fullName: fullName,
          email: email,
          phone: phone,
          dateJoined: DateTime.now(),
          role: role,
          isEmailVerified: false,
        );

        await _userService.createUser(newUser);
        debugPrint('[AuthService] Firestore user doc created');

        // Send verification email
        try {
          await result.user!.sendEmailVerification();
          debugPrint('[AuthService] ✅ Verification email sent to: $email');
        } catch (emailError) {
          debugPrint('[AuthService] ❌ Failed to send verification email: $emailError');
          // Still don't rethrow — user is created, they can resend from verification screen
        }
      }
    } catch (e) {
      debugPrint('[AuthService] ❌ Registration failed: $e');
      rethrow;
    }
  }

  /// Send email verification to the currently signed-in user.
  /// Used for resending from the verification screen.
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    debugPrint('[AuthService] sendVerificationEmail called. currentUser: ${user?.uid}, email: ${user?.email}, emailVerified: ${user?.emailVerified}');

    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        debugPrint('[AuthService] ✅ Verification email resent to: ${user.email}');
      } catch (e) {
        debugPrint('[AuthService] ❌ Failed to resend verification email: $e');
        rethrow;
      }
    } else if (user == null) {
      debugPrint('[AuthService] ⚠️ No current user — cannot send verification email');
      throw Exception('No user is currently signed in. Please register again.');
    } else {
      debugPrint('[AuthService] ℹ️ Email already verified, skipping');
    }
  }

  /// Resend verification email for a user who is trying to login
  /// but hasn't verified yet. Signs them in temporarily to send the email.
  Future<void> resendVerificationForEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }
      // Don't sign out — let them stay signed in for polling
    } catch (e) {
      rethrow;
    }
  }

  /// Reload the current user's data from Firebase to check
  /// for updated emailVerified status.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Check if the current user's email has been verified.
  /// Reloads the user first to get the latest status from Firebase.
  /// Returns true if verified, false otherwise.
  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        // Update Firestore
        await _updateEmailVerificationStatus(user.uid, true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Update the isEmailVerified field in Firestore
  Future<void> _updateEmailVerificationStatus(String uid, bool verified) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isEmailVerified': verified,
      });
    } catch (e) {
      // Silently fail — this is supplementary data
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authServiceProvider).authStateChanges);

