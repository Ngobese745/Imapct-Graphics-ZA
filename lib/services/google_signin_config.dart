import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInConfig {
  // iOS Client ID from Firebase configuration
  static const String iosClientId =
      '884752435887-et497k30lajc3he52n5eu72g2dt9dnhs.apps.googleusercontent.com';

  // Android Client ID from Firebase configuration
  static const String androidClientId =
      '884752435887-4rf9jhikf4ht028d0gbikmvfgl2o13hr.apps.googleusercontent.com';

  // Web Client ID from Firebase configuration
  static const String webClientId =
      '884752435887-f57pbhsivqj444gdf0anmhq5ld1krcj1.apps.googleusercontent.com';

  // Project ID
  static const String projectId = 'impact-graphics-za-266ef';

  // App name that will be displayed
  static const String appName = 'IMPACT GRAPHICS ZA';

  // Get configured GoogleSignIn instance based on platform
  static GoogleSignIn getGoogleSignIn() {
    try {
      if (kIsWeb) {
        return getGoogleSignInWeb();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return getGoogleSignInIOS();
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return getGoogleSignInAndroid();
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        return getGoogleSignInMacOS();
      } else {
        // Fallback for other platforms - use iOS client ID for compatibility
        return GoogleSignIn(
          clientId: iosClientId,
          scopes: ['email', 'profile'],
        );
      }
    } catch (e) {
      // print('Error creating GoogleSignIn instance: $e');
      // Fallback configuration
      return GoogleSignIn(scopes: ['email', 'profile']);
    }
  }

  // Get configured GoogleSignIn instance for iOS
  static GoogleSignIn getGoogleSignInIOS() {
    return GoogleSignIn(
      clientId: iosClientId,
      scopes: ['email', 'profile'],
      hostedDomain: '',
      signInOption: SignInOption.standard,
    );
  }

  // Get configured GoogleSignIn instance for Android
  static GoogleSignIn getGoogleSignInAndroid() {
    return GoogleSignIn(
      // Use serverClientId for Android (web client ID for backend verification)
      serverClientId: webClientId,
      scopes: ['email', 'profile'],
    );
  }

  // Get configured GoogleSignIn instance for Web
  static GoogleSignIn getGoogleSignInWeb() {
    return GoogleSignIn(
      clientId: webClientId,
      scopes: ['email', 'profile'],
      hostedDomain: '',
      signInOption: SignInOption.standard,
    );
  }

  // Get configured GoogleSignIn instance for macOS
  static GoogleSignIn getGoogleSignInMacOS() {
    return GoogleSignIn(
      clientId: iosClientId, // Use iOS client ID for macOS
      scopes: ['email', 'profile'],
      hostedDomain: '',
      signInOption: SignInOption.standard,
    );
  }

  // Validate Google Sign-In configuration
  static bool isConfigurationValid() {
    try {
      final googleSignIn = getGoogleSignIn();
      return googleSignIn != null;
    } catch (e) {
      // print('Google Sign-In configuration validation failed: $e');
      return false;
    }
  }

  // Get platform-specific client ID
  static String getClientId() {
    if (kIsWeb) {
      return webClientId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosClientId;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return androidClientId;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return iosClientId; // Use iOS client ID for macOS
    } else {
      return iosClientId; // Default fallback
    }
  }
}
