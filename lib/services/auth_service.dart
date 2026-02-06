import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';
import 'gold_tier_trial_service.dart';
import 'mailersend_service.dart';
import 'web_auth_config.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userProfile;
  bool _isAdmin = false;
  static bool _hasExplicitlyLoggedIn =
      false; // Track if user explicitly logged in this session
  bool _wasExplicitlyLoggedOut =
      false; // Track if user was explicitly logged out

  // Static method to get the current AuthService instance
  static AuthService? _instance;

  static AuthService? get instance => _instance;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated {
    // If user was explicitly logged out, they are not authenticated
    if (_wasExplicitlyLoggedOut) {
      // print(
      //        'AuthService: Auth check - user was explicitly logged out, not authenticated',
      //      );
      return false;
    }

    // Check if user is properly authenticated
    final currentUser = FirebaseService.currentUser;
    final isAuth = _user != null && currentUser != null;
    // print(
    //      'AuthService: Auth check - _user=${_user?.email}, currentUser=${currentUser?.email}, hasExplicitLogin=$_hasExplicitlyLoggedIn, isAuthenticated=$isAuth',
    //    );
    return isAuth;
  }

  bool get wasExplicitlyLoggedOut => _wasExplicitlyLoggedOut;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isAdmin => _isAdmin;

  AuthService() {
    _instance = this;
    _init();
  }

  void _init() {
    // print('AuthService: Starting smart auth initialization...');
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check if user was explicitly logged out using SharedPreferences
      _wasExplicitlyLoggedOut = await _checkIfExplicitlyLoggedOut();
      // print('AuthService: Was explicitly logged out: $_wasExplicitlyLoggedOut');

      // Check if there's a current Firebase user
      final currentUser = FirebaseService.currentUser;

      if (currentUser != null) {
        if (_wasExplicitlyLoggedOut) {
          // User was explicitly logged out but is still authenticated - clear the logout flag
          // This happens when the user refreshes the page after logging out
          // print('AuthService: User was explicitly logged out but still authenticated - clearing logout flag');
          await _clearLogoutState();
          _wasExplicitlyLoggedOut = false;
        }

        // User is authenticated - allow auto-login
        // print('AuthService: User is authenticated - allowing auto-login');
        _user = currentUser;
        _hasExplicitlyLoggedIn = true; // Allow auto-login for existing sessions
        await _loadUserProfile(); // Load user profile immediately
        notifyListeners();
      } else {
        // No user authenticated
        // print('AuthService: No current user found');
        _user = null;
        _userProfile = null;
        _isAdmin = false;
        _hasExplicitlyLoggedIn = false;
        notifyListeners();
      }

      // print('AuthService: Initialized with smart auth state');

      // Listen to auth state changes
      FirebaseService.authStateChanges.listen((User? user) {
        // print(
        //          'AuthService: Auth state changed: ${user?.email ?? 'null'}, hasExplicitLogin: $_hasExplicitlyLoggedIn, wasExplicitlyLoggedOut: $_wasExplicitlyLoggedOut',
        //        );

        // Only handle auth state changes if we're not in the middle of a manual login
        if (_isLoading) {
          // print('AuthService: Ignoring auth state change during manual login');
          return;
        }

        if (user != null) {
          // User is authenticated
          if (!_wasExplicitlyLoggedOut) {
            // User wasn't explicitly logged out - allow auto-login
            // print('AuthService: Allowing auto-login for user: ${user.email}');
            _user = user;
            _hasExplicitlyLoggedIn = true;
            _loadUserProfile();
            notifyListeners();
          } else {
            // User was explicitly logged out - ignore
            // print(
            //              'AuthService: Ignoring Firebase user state - user was explicitly logged out',
            //            );
            _user = null;
            _userProfile = null;
            _isAdmin = false;
            notifyListeners();
          }
        } else {
          // User is not authenticated
          // print('AuthService: User is not authenticated');
          _user = null;
          _userProfile = null;
          _isAdmin = false;
          notifyListeners();
        }
      });
    } catch (e) {
      // print('AuthService: Error during initialization: $e');
      // Fallback to safe state
      _user = null;
      _userProfile = null;
      _isAdmin = false;
      _hasExplicitlyLoggedIn = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      print('🔄 AuthService: Loading user profile for ${_user!.uid}...');

      // Check and update trial status first
      await GoldTierTrialService.checkAndExpireTrials();

      final profileDoc = await FirebaseService.getUserProfile(_user!.uid);
      if (profileDoc != null && profileDoc.exists) {
        _userProfile = profileDoc.data() as Map<String, dynamic>?;
        _isAdmin =
            _userProfile?['role'] == 'admin' ||
            _userProfile?['email']?.toString().contains(
                  '@impactgraphicsza.co.za',
                ) ==
                true;

        // Log important user data for debugging
        print('✅ AuthService: User profile loaded successfully');
        print('   - Email: ${_userProfile?['email']}');
        print('   - Wallet Balance: R${_userProfile?['walletBalance'] ?? 0}');
        print(
          '   - Gold Tier Status: ${_userProfile?['goldTierStatus'] ?? 'none'}',
        );
        print(
          '   - Account Status: ${_userProfile?['accountStatus'] ?? 'unknown'}',
        );
        print('   - Is Admin: $_isAdmin');

        notifyListeners();
      } else {
        print('⚠️ AuthService: No user profile found in Firestore');
        // If no profile exists, check if user is admin based on email
        _isAdmin =
            _user?.email?.toLowerCase().endsWith('@impactgraphicsza.co.za') ==
            true;
        notifyListeners();
      }
    } catch (e) {
      print('❌ AuthService: Error loading user profile: $e');
      // Fallback: check if user is admin based on email
      _isAdmin =
          _user?.email?.toLowerCase().endsWith('@impactgraphicsza.co.za') ==
          true;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    // Clear logout state when user logs in
    await _clearLogoutState();

    try {
      final userCredential = await FirebaseService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential != null) {
        _user = userCredential.user; // Set the user
        _hasExplicitlyLoggedIn = true; // Mark as explicitly logged in
        _wasExplicitlyLoggedOut = false; // Clear logout flag
        await _clearLogoutState(); // Clear logout flag in SharedPreferences
        await _loadUserProfile(); // Load user profile
        // print('AuthService: Explicit login successful for $email');
        // print('AuthService: Setting _user to: ${_user?.email}');
        _setLoading(false);
        // print('AuthService: Calling notifyListeners() for manual login');
        notifyListeners(); // Notify listeners of state change AFTER setting loading to false

        // Force additional notifications to ensure UI updates
        Future.delayed(Duration(milliseconds: 10), () {
          // print('AuthService: Additional notifyListeners() call');
          notifyListeners();
        });

        Future.delayed(Duration(milliseconds: 50), () {
          // print('AuthService: Final notifyListeners() call');
          notifyListeners();
        });

        // print('AuthService: Manual login completed, returning true');
        return true;
      } else {
        // Check if user is authenticated despite keychain error
        final currentUser = FirebaseService.currentUser;
        if (currentUser != null && currentUser.email == email) {
          _user = currentUser; // Set the user
          _hasExplicitlyLoggedIn = true; // Mark as explicitly logged in
          _wasExplicitlyLoggedOut = false; // Clear logout flag
          await _clearLogoutState(); // Clear logout flag in SharedPreferences
          await _loadUserProfile(); // Load user profile
          // print('User authenticated successfully despite keychain error');
          _setLoading(false);
          notifyListeners(); // Notify listeners of state change AFTER setting loading to false
          return true;
        } else {
          _setError('Authentication failed. Please try again.');
          _setLoading(false);
          return false;
        }
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String role,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential =
          await FirebaseService.createUserWithEmailAndPassword(email, password);

      if (userCredential?.user != null) {
        _user = userCredential!.user; // Set the user
        await FirebaseService.createUserProfile(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          role: role,
          provider: 'email',
        );

        // Send welcome email to new user
        print('📧 ========================================');
        print('📧 AuthService: About to send welcome email');
        print('📧 Email: $email');
        print('📧 Name: $name');
        print('📧 ========================================');
        try {
          final welcomeResult = await MailerSendService.sendWelcomeEmail(
            toEmail: email,
            toName: name,
          );
          if (welcomeResult.success) {
            print(
              '📧 ✅ AuthService: Welcome email sent successfully to $email',
            );
            print('📧 ✅ Message ID: ${welcomeResult.messageId}');
          } else {
            print(
              '📧 ❌ AuthService: Failed to send welcome email to $email: ${welcomeResult.message}',
            );
          }
        } catch (e) {
          print('📧 ❌ AuthService: Error sending welcome email to $email: $e');
          print('📧 ❌ Stack trace: ${StackTrace.current}');
          // Don't fail the signup process if welcome email fails
        }
        print('📧 ========================================');
        print('📧 AuthService: Welcome email process completed');
        print('📧 ========================================');

        _hasExplicitlyLoggedIn = true; // Mark as explicitly logged in
        _wasExplicitlyLoggedOut = false; // Clear logout flag
        await _clearLogoutState(); // Clear logout flag in SharedPreferences
        await _loadUserProfile(); // Load user profile
        // print('AuthService: Explicit signup successful for $email');
        _setLoading(false);
        notifyListeners(); // Notify listeners of state change AFTER setting loading to false
        return true;
      } else if (userCredential == null) {
        // Check if user was created despite keychain error
        final currentUser = FirebaseService.currentUser;
        if (currentUser != null && currentUser.email == email) {
          // print('User created successfully despite keychain error');
          await FirebaseService.createUserProfile(
            uid: currentUser.uid,
            name: name,
            email: email,
            role: role,
            provider: 'email',
          );

          // Send welcome email to new user
          print('📧 ========================================');
          print('📧 AuthService (Google): About to send welcome email');
          print('📧 Email: $email');
          print('📧 Name: $name');
          print('📧 ========================================');
          try {
            final welcomeResult = await MailerSendService.sendWelcomeEmail(
              toEmail: email,
              toName: name,
            );
            if (welcomeResult.success) {
              print(
                '📧 ✅ AuthService (Google): Welcome email sent successfully to $email',
              );
              print('📧 ✅ Message ID: ${welcomeResult.messageId}');
            } else {
              print(
                '📧 ❌ AuthService (Google): Failed to send welcome email to $email: ${welcomeResult.message}',
              );
            }
          } catch (e) {
            print(
              '📧 ❌ AuthService (Google): Error sending welcome email to $email: $e',
            );
            print('📧 ❌ Stack trace: ${StackTrace.current}');
            // Don't fail the signup process if welcome email fails
          }
          print('📧 ========================================');
          print('📧 AuthService (Google): Welcome email process completed');
          print('📧 ========================================');

          _setLoading(false);
          return true;
        }
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential = await FirebaseService.signInWithGoogle();

      if (userCredential != null) {
        _user = userCredential.user; // Set the user
        _hasExplicitlyLoggedIn = true; // Mark as explicitly logged in
        _wasExplicitlyLoggedOut = false; // Clear logout flag
        await _clearLogoutState(); // Clear logout flag in SharedPreferences
        await _loadUserProfile(); // Load user profile
        // print('AuthService: Explicit Google login successful');
        _setLoading(false);
        notifyListeners(); // Notify listeners of state change AFTER setting loading to false
        return true;
      } else {
        _setError('Google sign in was cancelled or failed.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut({VoidCallback? onComplete}) async {
    _setLoading(true);
    try {
      print('🚪 AuthService: Starting signOut...');
      print('   - Current user: ${_user?.email}');
      print('   - Current wallet balance: ${_userProfile?['walletBalance']}');
      print('   - Current gold tier: ${_userProfile?['goldTierStatus']}');

      // IMPORTANT: Only clear local app state, NOT Firestore data
      // Firestore data persistence will keep user data cached

      // Clear local state immediately and notify listeners
      _user = null;
      _userProfile = null;
      _isAdmin = false;
      _hasExplicitlyLoggedIn = false; // Clear explicit login flag
      _wasExplicitlyLoggedOut = true; // Mark as explicitly logged out
      _clearError();
      notifyListeners(); // Immediate UI update

      // Mark as explicitly logged out in SharedPreferences
      await _markAsExplicitlyLoggedOut();

      // Then sign out from Firebase (this does NOT clear Firestore cache)
      await FirebaseService.signOut();

      // Final state check and notify
      _user = null;
      _userProfile = null;
      _isAdmin = false;
      _hasExplicitlyLoggedIn = false; // Ensure explicit login flag is cleared
      _wasExplicitlyLoggedOut = true; // Ensure logout flag is set
      notifyListeners(); // Final UI update

      // Force multiple notifications to ensure UI updates
      await Future.delayed(Duration(milliseconds: 10));
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 50));
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 100));
      notifyListeners();

      // Call the completion callback if provided
      onComplete?.call();

      print('✅ AuthService: SignOut completed successfully');
      print('   ℹ️  User data remains in Firestore for next login');
    } catch (e) {
      print('❌ AuthService: SignOut error: $e');
      _setError(_getErrorMessage(e));

      // Even if there's an error, clear local state
      _user = null;
      _userProfile = null;
      _isAdmin = false;
      _hasExplicitlyLoggedIn = false; // Clear explicit login flag even on error
      _wasExplicitlyLoggedOut = true; // Mark as logged out even on error
      await _markAsExplicitlyLoggedOut(); // Mark as logged out even on error
      notifyListeners();

      // Call the completion callback even on error
      onComplete?.call();
    }
    _setLoading(false);
  }

  Future<void> refreshUserProfile() async {
    await _loadUserProfile();
  }

  void refreshAuthState() {
    _user = FirebaseService.currentUser;
    // print('AuthService: Refreshed auth state - user: ${_user?.email}');
    notifyListeners();
  }

  // Check if user was explicitly logged out using SharedPreferences
  Future<bool> _checkIfExplicitlyLoggedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('was_explicitly_logged_out') ?? false;
    } catch (e) {
      // print('Error checking logout state: $e');
      return false;
    }
  }

  // Mark user as explicitly logged out in SharedPreferences
  Future<void> _markAsExplicitlyLoggedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_explicitly_logged_out', true);
      // print(
      //        'AuthService: Marked as explicitly logged out in SharedPreferences',
      //      );
    } catch (e) {
      // print('Error marking logout state: $e');
    }
  }

  // Clear logout state when user logs in
  Future<void> _clearLogoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_explicitly_logged_out', false);
      _wasExplicitlyLoggedOut = false;
      // print('AuthService: Cleared logout state in SharedPreferences');
    } catch (e) {
      // print('Error clearing logout state: $e');
    }
  }

  // Force clear authentication state
  void forceClearAuth() {
    // print('AuthService: Force clearing authentication state');
    _user = null;
    _userProfile = null;
    _isAdmin = false;
    _hasExplicitlyLoggedIn = false; // Clear explicit login flag
    _clearError();
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await FirebaseService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Test Firebase Authentication by creating a test user
  Future<bool> testAuthCreation() async {
    try {
      final testEmail =
          'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'test123456';

      // print('Testing Firebase Auth creation with email: $testEmail');

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );

      // print('Test user created successfully: ${userCredential.user?.email}');

      // Clean up - delete the test user
      await userCredential.user?.delete();
      // print('Test user deleted successfully');

      return true;
    } catch (e) {
      // print('Firebase Auth creation test failed: $e');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // print('AuthService: _setLoading called with: $loading');
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    // print('AuthService: _setError called with: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    // print('AuthService: _clearError called');
    notifyListeners();
  }

  @override
  void notifyListeners() {
    // print('AuthService: notifyListeners() called');
    super.notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      if (kIsWeb) {
        // Use web-specific error messages
        return WebAuthConfig.getWebAuthErrorMessage(error);
      } else {
        // Use mobile-specific error messages
        switch (error.code) {
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
          case 'user-disabled':
            return 'This account has been disabled.';
          case 'too-many-requests':
            return 'Too many failed attempts. Please try again later.';
          case 'operation-not-allowed':
            return 'This operation is not allowed.';
          case 'network-request-failed':
            return 'Firebase Authentication is not enabled. Please enable it in the Firebase console:\nhttps://console.firebase.google.com/project/impact-graphics-za-266ef/authentication';
          case 'account-exists-with-different-credential':
            return 'An account already exists with the same email address but different sign-in credentials.';
          case 'invalid-credential':
            return 'Invalid credentials. Please try again.';
          case 'operation-not-allowed':
            return 'This sign-in method is not enabled. Please contact support.';
          case 'user-disabled':
            return 'This account has been disabled.';
          case 'user-token-expired':
            return 'Your session has expired. Please sign in again.';
          case 'user-token-revoked':
            return 'Your session has been revoked. Please sign in again.';
          default:
            return 'Authentication failed. Please try again.';
        }
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  void clearError() {
    _clearError();
  }
}
