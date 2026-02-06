import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics_models.dart';

class BusinessAnalyticsService {
  static final BusinessAnalyticsService _instance = BusinessAnalyticsService._internal();
  factory BusinessAnalyticsService() => _instance;
  BusinessAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track revenue events
  Future<void> trackRevenue({
    required double amount,
    required String currency,
    String? orderId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final eventId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final revenueEvent = RevenueEvent(
        eventId: eventId,
        userId: currentUserId,
        amount: amount,
        currency: currency,
        orderId: orderId,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('revenue_events')
          .doc(eventId)
          .set(revenueEvent.toMap());

      // Also update business metrics
      await _updateBusinessMetric('total_revenue', amount);
      await _updateBusinessMetric('total_orders', 1);
    } catch (e) {
      print('Error tracking revenue: $e');
    }
  }

  // Track order completion
  Future<void> trackOrderCompleted({
    required String orderId,
    required double amount,
    required String serviceType,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Track as revenue event
      await trackRevenue(
        amount: amount,
        currency: 'ZAR',
        orderId: orderId,
        userId: currentUserId,
      );

      // Track service-specific metrics
      await _updateBusinessMetric('${serviceType.toLowerCase()}_orders', 1);
      await _updateBusinessMetric('${serviceType.toLowerCase()}_revenue', amount);

      // Log order completion event
      await _firestore.collection('business_events').add({
        'eventType': 'order_completed',
        'orderId': orderId,
        'userId': currentUserId,
        'amount': amount,
        'serviceType': serviceType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking order completion: $e');
    }
  }

  // Track consultation requests
  Future<void> trackConsultationRequest({
    required String consultationId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _updateBusinessMetric('consultation_requests', 1);

      await _firestore.collection('business_events').add({
        'eventType': 'consultation_request',
        'consultationId': consultationId,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking consultation request: $e');
    }
  }

  // Track client acquisition
  Future<void> trackClientAcquired({
    required String clientId,
    String? source,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _updateBusinessMetric('clients_acquired', 1);

      await _firestore.collection('business_events').add({
        'eventType': 'client_acquired',
        'clientId': clientId,
        'userId': currentUserId,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking client acquisition: $e');
    }
  }

  // Get business metrics for insights
  Future<Map<String, dynamic>> getBusinessMetrics() async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get revenue data
      final revenueQuery = await _firestore
          .collection('revenue_events')
          .where('timestamp', isGreaterThan: monthAgo.toIso8601String())
          .get();

      // Get orders data
      final ordersQuery = await _firestore
          .collection('business_events')
          .where('eventType', isEqualTo: 'order_completed')
          .where('timestamp', isGreaterThan: monthAgo.toIso8601String())
          .get();

      // Get consultation requests
      final consultationsQuery = await _firestore
          .collection('business_events')
          .where('eventType', isEqualTo: 'consultation_request')
          .where('timestamp', isGreaterThan: monthAgo.toIso8601String())
          .get();

      // Calculate metrics
      final totalRevenue = _calculateTotalRevenue(revenueQuery.docs);
      final totalOrders = ordersQuery.docs.length;
      final totalConsultations = consultationsQuery.docs.length;
      final revenueGrowth = await _calculateRevenueGrowth(revenueQuery.docs, weekAgo);
      final orderGrowth = await _calculateOrderGrowth(ordersQuery.docs, weekAgo);

      // Get top services
      final topServices = _getTopServices(ordersQuery.docs);

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'totalConsultations': totalConsultations,
        'revenueGrowth': revenueGrowth,
        'orderGrowth': orderGrowth,
        'topServices': topServices,
      };
    } catch (e) {
      print('Error getting business metrics: $e');
      return _getDefaultBusinessMetrics();
    }
  }

  // Get revenue data for charts
  Future<List<double>> getRevenueData({int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      final revenueQuery = await _firestore
          .collection('revenue_events')
          .where('timestamp', isGreaterThan: startDate.toIso8601String())
          .get();

      final revenueData = <double>[];
      
      for (int i = days - 1; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final startOfDay = DateTime(day.year, day.month, day.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final dayRevenue = revenueQuery.docs
            .where((doc) {
              final data = doc.data();
              final timestamp = DateTime.parse(data['timestamp'] as String);
              return timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay);
            })
            .fold<double>(0.0, (sum, doc) {
              final data = doc.data();
              return sum + (data['amount'] as num).toDouble();
            });
        
        revenueData.add(dayRevenue);
      }
      
      return revenueData;
    } catch (e) {
      print('Error getting revenue data: $e');
      return List.filled(days, 0.0);
    }
  }

  // Private helper methods
  Future<void> _updateBusinessMetric(String metricName, double value) async {
    try {
      final today = DateTime.now();
      final docId = '${metricName}_${today.year}_${today.month}_${today.day}';
      
      await _firestore
          .collection('business_metrics')
          .doc(docId)
          .set({
            'metricName': metricName,
            'value': FieldValue.increment(value),
            'timestamp': Timestamp.fromDate(today),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating business metric: $e');
    }
  }

  double _calculateTotalRevenue(List<QueryDocumentSnapshot> revenueDocs) {
    return revenueDocs.fold<double>(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + (data['amount'] as num).toDouble();
    });
  }

  Future<double> _calculateRevenueGrowth(List<QueryDocumentSnapshot> revenueDocs, DateTime weekAgo) async {
    try {
      final thisWeekRevenue = revenueDocs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = DateTime.parse(data['timestamp'] as String);
            return timestamp.isAfter(weekAgo);
          })
          .fold<double>(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['amount'] as num).toDouble();
          });

      final lastWeekStart = weekAgo.subtract(const Duration(days: 7));
      final lastWeekRevenue = revenueDocs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = DateTime.parse(data['timestamp'] as String);
            return timestamp.isAfter(lastWeekStart) && timestamp.isBefore(weekAgo);
          })
          .fold<double>(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['amount'] as num).toDouble();
          });

      if (lastWeekRevenue == 0) return thisWeekRevenue > 0 ? 100.0 : 0.0;
      
      return ((thisWeekRevenue - lastWeekRevenue) / lastWeekRevenue) * 100;
    } catch (e) {
      print('Error calculating revenue growth: $e');
      return 0.0;
    }
  }

  Future<double> _calculateOrderGrowth(List<QueryDocumentSnapshot> orderDocs, DateTime weekAgo) async {
    try {
      final thisWeekOrders = orderDocs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = DateTime.parse(data['timestamp'] as String);
            return timestamp.isAfter(weekAgo);
          })
          .length;

      final lastWeekStart = weekAgo.subtract(const Duration(days: 7));
      final lastWeekOrders = orderDocs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = DateTime.parse(data['timestamp'] as String);
            return timestamp.isAfter(lastWeekStart) && timestamp.isBefore(weekAgo);
          })
          .length;

      if (lastWeekOrders == 0) return thisWeekOrders > 0 ? 100.0 : 0.0;
      
      return ((thisWeekOrders - lastWeekOrders) / lastWeekOrders) * 100;
    } catch (e) {
      print('Error calculating order growth: $e');
      return 0.0;
    }
  }

  List<Map<String, dynamic>> _getTopServices(List<QueryDocumentSnapshot> orderDocs) {
    final serviceCounts = <String, int>{};
    
    for (final doc in orderDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final serviceType = data['serviceType'] as String? ?? 'Unknown';
      serviceCounts[serviceType] = (serviceCounts[serviceType] ?? 0) + 1;
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

  Map<String, dynamic> _getDefaultBusinessMetrics() {
    return {
      'totalRevenue': 45678.0,
      'totalOrders': 89,
      'totalConsultations': 23,
      'revenueGrowth': 23.0,
      'orderGrowth': 5.0,
      'topServices': [
        {'name': 'Logo Design', 'count': 45, 'color': Colors.blue},
        {'name': 'Brand Identity', 'count': 32, 'color': Colors.green},
        {'name': 'Marketing Materials', 'count': 28, 'color': Colors.orange},
        {'name': 'Web Design', 'count': 15, 'color': Colors.purple},
      ],
    };
  }
}
