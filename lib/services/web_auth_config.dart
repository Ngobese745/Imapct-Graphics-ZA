import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebAuthConfig {
  // Web-specific authentication configuration
  static const List<String> supportedAuthProviders = ['google.com', 'password'];

  // Google Sign In configuration for web
  static GoogleAuthProvider getGoogleProvider() {
    final provider = GoogleAuthProvider();

    // Add scopes
    provider.addScope('https://www.googleapis.com/auth/userinfo.email');
    provider.addScope('https://www.googleapis.com/auth/userinfo.profile');

    // Set custom parameters
    provider.setCustomParameters({'prompt': 'select_account'});

    return provider;
  }

  // Check if running on web
  static bool get isWeb => kIsWeb;

  // Web-specific error handling
  static String getWebAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'popup-closed-by-user':
        return 'Sign in was cancelled. Please try again.';
      case 'popup-blocked':
        return 'Pop-up was blocked by your browser. Please allow pop-ups for this site.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Web-specific authentication settings
  static const Map<String, dynamic> webAuthSettings = {
    'signInOptions': ['google.com', 'password'],
    'signInFlow': 'popup',
    'allowDuplicateEmails': false,
    'requireDisplayName': true,
  };

  // Check if a specific auth provider is enabled
  static bool isProviderEnabled(String providerId) {
    return supportedAuthProviders.contains(providerId);
  }

  // Get the preferred sign-in method for web
  static String getPreferredSignInMethod() {
    if (isWeb) {
      return 'popup'; // Use popup for web
    }
    return 'redirect'; // Use redirect for mobile
  }

  // Web-specific authentication persistence
  static const String persistenceKey = 'firebase:auth:persistence';

  // Check if authentication persistence is enabled
  static bool isPersistenceEnabled() {
    if (isWeb) {
      // On web, we typically want to persist authentication
      return true;
    }
    // On mobile, we can be more flexible
    return true;
  }
}
