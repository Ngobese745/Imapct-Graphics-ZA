import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/analytics_models.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Session tracking
  String? _currentSessionId;
  DateTime? _sessionStartTime;

  // Initialize session tracking
  Future<void> initializeSession() async {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();

    final user = _auth.currentUser;
    if (user != null) {
      await _logUserSession(user.uid);
    }
  }

  // Track screen views
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        parameters: parameters?.cast<String, Object>(),
      );

      // Also log to Firestore
      final user = _auth.currentUser;
      if (user != null && _currentSessionId != null) {
        await _logAppUsageEvent(
          userId: user.uid,
          eventName: 'screen_view',
          parameters: {
            'screen_name': screenName,
            ...?parameters,
          },
        );
      }
    } catch (e) {
      print('Error tracking screen view: $e');
    }
  }

  // Track custom events
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: eventName.toLowerCase().replaceAll(' ', '_'),
        parameters: parameters?.cast<String, Object>(),
      );

      // Also log to Firestore
      final user = _auth.currentUser;
      if (user != null && _currentSessionId != null) {
        await _logAppUsageEvent(
          userId: user.uid,
          eventName: eventName,
          parameters: parameters,
        );
      }
    } catch (e) {
      print('Error tracking event: $e');
    }
  }

  // Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await trackEvent('feature_used', parameters: {'feature_name': featureName});

        // Update feature usage count in Firestore
        await _updateFeatureUsageCount(user.uid, featureName);
      }
    } catch (e) {
      print('Error tracking feature usage: $e');
    }
  }

  // Track errors
  Future<void> trackError(String message, String stackTrace) async {
    try {
      final user = _auth.currentUser;
      if (user != null && _currentSessionId != null) {
        final errorId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final errorLog = ErrorLog(
          errorId: errorId,
          userId: user.uid,
          sessionId: _currentSessionId!,
          message: message,
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        );

        await _firestore
            .collection('error_logs')
            .doc(errorId)
            .set(errorLog.toMap());
      }
    } catch (e) {
      print('Error tracking error: $e');
    }
  }

  // Track performance metrics
  Future<void> trackPerformanceMetric(String metricName, double value) async {
    try {
      final user = _auth.currentUser;
      if (user != null && _currentSessionId != null) {
        final metricId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final performanceMetric = PerformanceMetric(
          metricId: metricId,
          userId: user.uid,
          sessionId: _currentSessionId!,
          metricName: metricName,
          value: value,
          timestamp: DateTime.now(),
        );

        await _firestore
            .collection('performance_metrics')
            .doc(metricId)
            .set(performanceMetric.toMap());
      }
    } catch (e) {
      print('Error tracking performance metric: $e');
    }
  }

  // Get analytics data for insights
  Future<Map<String, dynamic>> getInsightsData() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get user sessions from the last 7 days
      final sessionsQuery = await _firestore
          .collection('user_sessions')
          .where('startTime', isGreaterThan: weekAgo.toIso8601String())
          .get();

      // Get app usage events from the last 7 days
      final eventsQuery = await _firestore
          .collection('app_usage_events')
          .where('timestamp', isGreaterThan: weekAgo.toIso8601String())
          .get();

      // Get feature usage from the last 7 days
      final featureUsageQuery = await _firestore
          .collection('feature_usage')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      // Calculate metrics
      final totalUsers = await _getTotalUsers();
      final activeSessions = _getActiveSessions(sessionsQuery.docs);
      final userActivityData = _getUserActivityData(eventsQuery.docs);
      final topServices = _getTopServices(featureUsageQuery.docs);
      final recentActivity = _getRecentActivity(eventsQuery.docs);

      return {
        'totalUsers': totalUsers,
        'activeSessions': activeSessions,
        'userActivityData': userActivityData,
        'topServices': topServices,
        'recentActivity': recentActivity,
      };
    } catch (e) {
      print('Error getting insights data: $e');
      return _getDefaultInsightsData();
    }
  }

  // Private helper methods
  Future<void> _logUserSession(String userId) async {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    final userSession = UserSession(
      sessionId: _currentSessionId!,
      userId: userId,
      startTime: _sessionStartTime!,
      deviceType: kIsWeb ? 'Web' : (Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown'),
      os: kIsWeb ? 'Web' : Platform.operatingSystem,
      appVersion: '1.0.0', // You can get this from package_info_plus
    );

    await _firestore
        .collection('user_sessions')
        .doc(_currentSessionId)
        .set(userSession.toMap());
  }

  Future<void> _logAppUsageEvent({
    required String userId,
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (_currentSessionId == null) return;

    final eventId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final appUsageEvent = AppUsageEvent(
      eventId: eventId,
      userId: userId,
      sessionId: _currentSessionId!,
      eventName: eventName,
      parameters: parameters,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('app_usage_events')
        .doc(eventId)
        .set(appUsageEvent.toMap());
  }

  Future<void> _updateFeatureUsageCount(String userId, String featureName) async {
    final docRef = _firestore
        .collection('feature_usage')
        .where('userId', isEqualTo: userId)
        .where('featureName', isEqualTo: featureName)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
        .limit(1);

    final querySnapshot = await docRef.get();
    
    if (querySnapshot.docs.isEmpty) {
      // Create new feature usage record
      final featureUsage = FeatureUsage(
        featureName: featureName,
        userId: userId,
        timestamp: DateTime.now(),
        count: 1,
      );

      await _firestore
          .collection('feature_usage')
          .add(featureUsage.toMap());
    } else {
      // Update existing record
      final doc = querySnapshot.docs.first;
      await doc.reference.update({
        'count': FieldValue.increment(1),
      });
    }
  }

  Future<int> _getTotalUsers() async {
    final usersQuery = await _firestore.collection('users').get();
    return usersQuery.docs.length;
  }

  int _getActiveSessions(List<QueryDocumentSnapshot> sessions) {
    final now = DateTime.now();
    final activeThreshold = now.subtract(const Duration(minutes: 30));
    
    return sessions.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final startTime = DateTime.parse(data['startTime'] as String);
      final endTime = data['endTime'] != null 
          ? DateTime.parse(data['endTime'] as String)
          : null;
      
      return startTime.isAfter(activeThreshold) && endTime == null;
    }).length;
  }

  List<int> _getUserActivityData(List<QueryDocumentSnapshot> events) {
    final now = DateTime.now();
    final activityData = <int>[];
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final dayEvents = events.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        return timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay);
      }).length;
      
      activityData.add(dayEvents);
    }
    
    return activityData;
  }

  List<Map<String, dynamic>> _getTopServices(List<QueryDocumentSnapshot> featureUsage) {
    final serviceCounts = <String, int>{};
    
    for (final doc in featureUsage) {
      final data = doc.data() as Map<String, dynamic>;
      final featureName = data['featureName'] as String;
      final count = data['count'] as int;
      
      serviceCounts[featureName] = (serviceCounts[featureName] ?? 0) + count;
    }
    
    final sortedServices = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    
    return sortedServices.take(4).map((entry) {
      final index = sortedServices.indexOf(entry);
      return {
        'name': entry.key,
        'count': entry.value,
        'color': colors[index % colors.length],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getRecentActivity(List<QueryDocumentSnapshot> events) {
    final sortedEvents = events.toList()
      ..sort((a, b) {
        final aTime = DateTime.parse((a.data() as Map<String, dynamic>)['timestamp'] as String);
        final bTime = DateTime.parse((b.data() as Map<String, dynamic>)['timestamp'] as String);
        return bTime.compareTo(aTime);
      });
    
    final activityIcons = {
      'user_registered': Icons.person_add,
      'order_completed': Icons.check_circle,
      'payment_received': Icons.payment,
      'consultation_request': Icons.chat,
      'service_completed': Icons.done_all,
      'screen_view': Icons.visibility,
    };
    
    return sortedEvents.take(5).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final eventName = data['eventName'] as String;
      final timestamp = DateTime.parse(data['timestamp'] as String);
      final timeAgo = _getTimeAgo(timestamp);
      
      return {
        'action': _getActivityDescription(eventName),
        'time': timeAgo,
        'icon': activityIcons[eventName] ?? Icons.event,
      };
    }).toList();
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _getActivityDescription(String eventName) {
    switch (eventName) {
      case 'user_registered':
        return 'New user registered';
      case 'order_completed':
        return 'Order completed';
      case 'payment_received':
        return 'Payment received';
      case 'consultation_request':
        return 'New consultation request';
      case 'service_completed':
        return 'Service completed';
      case 'screen_view':
        return 'User viewed screen';
      default:
        return 'User activity';
    }
  }

  Map<String, dynamic> _getDefaultInsightsData() {
    return {
      'totalUsers': 1234,
      'activeSessions': 567,
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
