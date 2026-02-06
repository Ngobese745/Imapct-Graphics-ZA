import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'delayed_subscription_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class AppInitializationService extends ChangeNotifier {
  static AppInitializationService? _instance;
  static AppInitializationService get instance =>
      _instance ??= AppInitializationService._();

  AppInitializationService._();

  // Initialization states
  bool _isInitializing = true;
  bool _isFirebaseReady = false;
  bool _isAuthReady = false;
  bool _isServicesReady = false;
  bool _isProfileLoaded = false;
  String _currentStep = 'Initializing...';
  double _progress = 0.0;

  // Getters
  bool get isInitializing => _isInitializing;
  bool get isFirebaseReady => _isFirebaseReady;
  bool get isAuthReady => _isAuthReady;
  bool get isServicesReady => _isServicesReady;
  bool get isProfileLoaded => _isProfileLoaded;
  String get currentStep => _currentStep;
  double get progress => _progress;
  bool get isFullyReady =>
      _isFirebaseReady && _isAuthReady && _isServicesReady && _isProfileLoaded;

  // Initialize the app with proper coordination
  Future<void> initializeApp() async {
    if (!_isInitializing) return;

    try {
      _updateStep('Initializing Firebase...', 0.1);
      await _initializeFirebase();

      _updateStep('Setting up authentication...', 0.3);
      await _initializeAuthentication();

      _updateStep('Loading user profile...', 0.5);
      await _loadUserProfile();

      _updateStep('Starting services...', 0.7);
      await _initializeServices();

      _updateStep('Finalizing setup...', 0.9);
      await _finalizeInitialization();

      _updateStep('Ready!', 1.0);

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      // print('App initialization error: $e');
      _updateStep('Initialization failed', 0.0);
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      await FirebaseService.initializeAuth();
      _isFirebaseReady = true;
      notifyListeners();
    } catch (e) {
      // print('Firebase initialization error: $e');
      rethrow;
    }
  }

  Future<void> _initializeAuthentication() async {
    try {
      // Wait for AuthService to be ready
      final authService = AuthService.instance;
      if (authService != null) {
        // Wait for auth service to complete its initialization
        await Future.delayed(const Duration(milliseconds: 100));
        _isAuthReady = true;
        notifyListeners();
      }
    } catch (e) {
      // print('Auth initialization error: $e');
      rethrow;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final authService = AuthService.instance;
      if (authService != null && authService.isAuthenticated) {
        // Refresh user profile to ensure it's loaded
        await authService.refreshUserProfile();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      _isProfileLoaded = true;
      notifyListeners();
    } catch (e) {
      // print('Profile loading error: $e');
      // Don't rethrow - profile loading can fail without breaking the app
      _isProfileLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize notification service
      await NotificationService.initialize();

      // AdMob initialization moved to main.dart to avoid conflicts

      // Check and activate pending subscriptions
      await DelayedSubscriptionService.checkAndActivatePendingSubscriptions();

      // Pending payments are now handled by webhooks automatically
      print('✅ Webhook-based payment verification active');

      _isServicesReady = true;
      notifyListeners();
    } catch (e) {
      // print('Services initialization error: $e');
      // Don't rethrow - services can fail without breaking the app
      _isServicesReady = true;
      notifyListeners();
    }
  }

  Future<void> _finalizeInitialization() async {
    // Any final setup tasks
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void _updateStep(String step, double progress) {
    _currentStep = step;
    _progress = progress;
    notifyListeners();
  }

  // Reset for testing
  void reset() {
    _isInitializing = true;
    _isFirebaseReady = false;
    _isAuthReady = false;
    _isServicesReady = false;
    _isProfileLoaded = false;
    _currentStep = 'Initializing...';
    _progress = 0.0;
    notifyListeners();
  }
}
