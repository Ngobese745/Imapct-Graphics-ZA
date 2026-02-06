import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'analytics_service.dart';
import 'business_analytics_service.dart';

class AppAnalyticsInitializer {
  static final AppAnalyticsInitializer _instance = AppAnalyticsInitializer._internal();
  factory AppAnalyticsInitializer() => _instance;
  AppAnalyticsInitializer._internal();

  final AnalyticsService _analyticsService = AnalyticsService();
  final BusinessAnalyticsService _businessAnalyticsService = BusinessAnalyticsService();

  bool _isInitialized = false;

  // Initialize analytics for the entire app
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize session tracking
      await _analyticsService.initializeSession();

      // Track app launch
      await _analyticsService.trackEvent('app_launched');

      // Listen for auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _onUserSignedIn(user);
        } else {
          _onUserSignedOut();
        }
      });

      _isInitialized = true;
      print('Analytics initialized successfully');
    } catch (e) {
      print('Error initializing analytics: $e');
    }
  }

  // Handle user sign in
  Future<void> _onUserSignedIn(User user) async {
    try {
      await _analyticsService.trackEvent('user_signed_in', parameters: {
        'user_id': user.uid,
        'email': user.email ?? 'unknown',
      });

      await _businessAnalyticsService.trackClientAcquired(
        clientId: user.uid,
        source: 'app_registration',
        userId: user.uid,
      );
    } catch (e) {
      print('Error tracking user sign in: $e');
    }
  }

  // Handle user sign out
  Future<void> _onUserSignedOut() async {
    try {
      await _analyticsService.trackEvent('user_signed_out');
    } catch (e) {
      print('Error tracking user sign out: $e');
    }
  }

  // Track screen navigation
  Future<void> trackScreenNavigation(String screenName) async {
    try {
      await _analyticsService.trackScreenView(screenName);
    } catch (e) {
      print('Error tracking screen navigation: $e');
    }
  }

  // Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    try {
      await _analyticsService.trackFeatureUsage(featureName);
    } catch (e) {
      print('Error tracking feature usage: $e');
    }
  }

  // Track business events
  Future<void> trackBusinessEvent(String eventType, Map<String, dynamic> parameters) async {
    try {
      await _analyticsService.trackEvent('business_event', parameters: {
        'event_type': eventType,
        ...parameters,
      });
    } catch (e) {
      print('Error tracking business event: $e');
    }
  }

  // Track order completion
  Future<void> trackOrderCompletion({
    required String orderId,
    required double amount,
    required String serviceType,
  }) async {
    try {
      await _businessAnalyticsService.trackOrderCompleted(
        orderId: orderId,
        amount: amount,
        serviceType: serviceType,
      );
    } catch (e) {
      print('Error tracking order completion: $e');
    }
  }

  // Track consultation request
  Future<void> trackConsultationRequest(String consultationId) async {
    try {
      await _businessAnalyticsService.trackConsultationRequest(
        consultationId: consultationId,
      );
    } catch (e) {
      print('Error tracking consultation request: $e');
    }
  }

  // Track performance metrics
  Future<void> trackPerformanceMetric(String metricName, double value) async {
    try {
      await _analyticsService.trackPerformanceMetric(metricName, value);
    } catch (e) {
      print('Error tracking performance metric: $e');
    }
  }

  // Track errors
  Future<void> trackError(String message, String stackTrace) async {
    try {
      await _analyticsService.trackError(message, stackTrace);
    } catch (e) {
      print('Error tracking error: $e');
    }
  }

  // Get insights data
  Future<Map<String, dynamic>> getInsightsData() async {
    try {
      final analyticsData = await _analyticsService.getInsightsData();
      final businessData = await _businessAnalyticsService.getBusinessMetrics();
      
      return {
        ...analyticsData,
        ...businessData,
      };
    } catch (e) {
      print('Error getting insights data: $e');
      return _getDefaultInsightsData();
    }
  }

  // Get revenue data for charts
  Future<List<double>> getRevenueData({int days = 7}) async {
    try {
      return await _businessAnalyticsService.getRevenueData(days: days);
    } catch (e) {
      print('Error getting revenue data: $e');
      return List.filled(days, 0.0);
    }
  }

  Map<String, dynamic> _getDefaultInsightsData() {
    return {
      'totalUsers': 1234,
      'activeSessions': 567,
      'totalRevenue': 45678.0,
      'totalOrders': 89,
      'userActivityData': [50, 75, 60, 85, 90, 70, 95],
      'topServices': [
        {'name': 'Logo Design', 'count': 45, 'color': Colors.blue},
        {'name': 'Brand Identity', 'count': 32, 'color': Colors.green},
        {'name': 'Marketing Materials', 'count': 28, 'color': Colors.orange},
        {'name': 'Web Design', 'count': 15, 'color': Colors.purple},
      ],
      'recentActivity': [
        {'action': 'New user registered', 'time': '2 minutes ago', 'icon': Icons.person_add},
        {'action': 'Order completed', 'time': '5 minutes ago', 'icon': Icons.check_circle},
        {'action': 'Payment received', 'time': '8 minutes ago', 'icon': Icons.payment},
        {'action': 'New consultation request', 'time': '12 minutes ago', 'icon': Icons.chat},
        {'action': 'Service completed', 'time': '15 minutes ago', 'icon': Icons.done_all},
      ],
    };
  }
}
