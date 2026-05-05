/// Custom exception thrown when an unverified user attempts to login.
class EmailNotVerifiedException implements Exception {
  final String email;
  const EmailNotVerifiedException(this.email);

  @override
  String toString() => 'Email not verified: $email';
}

/// Utility class to map Firebase Auth error codes to user-friendly messages.
class AuthErrorMapper {
  static String mapFirebaseAuthError(dynamic error) {
    final String errorCode = _extractErrorCode(error);

    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  static String _extractErrorCode(dynamic error) {
    final errorString = error.toString();
    // Firebase errors typically contain a code in brackets like [firebase_auth/code]
    final regExp = RegExp(r'\[firebase_auth/([\w-]+)\]');
    final match = regExp.firstMatch(errorString);
    if (match != null) {
      return match.group(1) ?? '';
    }
    // Fallback: try to extract from FirebaseAuthException.code
    try {
      return error.code as String;
    } catch (_) {
      return '';
    }
  }
}
