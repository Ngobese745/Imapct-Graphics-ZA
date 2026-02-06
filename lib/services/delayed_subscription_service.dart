import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'monthly_credit_service.dart';

class DelayedSubscriptionService {
  static const String _secretKey = 'sk_live_PLACEHOLDER';
  static const String _baseUrl = 'https://api.paystack.co';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a delayed subscription (setup fee paid now, monthly starts in 30 days)
  static Future<Map<String, dynamic>> createDelayedSubscription({
    required String userId,
    required String userEmail,
    required String userName,
    required String packageName,
    required double monthlyAmount,
    required double setupFee,
    required String setupFeeReference,
  }) async {
    try {
      print('=== CREATING DELAYED SUBSCRIPTION ===');
      print('User: $userEmail');
      print('Package: $packageName');
      print('Monthly Amount: R${monthlyAmount.toStringAsFixed(2)}');
      print('Setup Fee: R${setupFee.toStringAsFixed(2)}');

      // Step 1: Create Paystack customer
      final customerResult = await _createPaystackCustomer(
        email: userEmail,
        firstName: userName.split(' ').first,
        lastName: userName.split(' ').length > 1
            ? userName.split(' ').sublist(1).join(' ')
            : 'Name',
      );

      if (customerResult == null || customerResult['status'] != true) {
        return {
          'success': false,
          'message':
              'Failed to create customer: ${customerResult?['message'] ?? 'Unknown error'}',
        };
      }

      final customerId = customerResult['data']['customer_code'];
      print('Customer created: $customerId');

      // Step 2: Create Paystack plan
      final planResult = await _createPaystackPlan(
        name: '$packageName Subscription',
        description: 'Monthly subscription for $packageName package',
        amount: (monthlyAmount * 100).round(), // Convert to kobo
        interval: 'monthly',
      );

      if (planResult == null || planResult['status'] != true) {
        return {
          'success': false,
          'message':
              'Failed to create plan: ${planResult?['message'] ?? 'Unknown error'}',
        };
      }

      final planId = planResult['data']['plan_code'];
      print('Plan created: $planId');

      // Step 3: Store delayed subscription in Firestore
      final subscriptionData = {
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'packageName': packageName,
        'customerId': customerId,
        'planId': planId,
        'monthlyAmount': monthlyAmount,
        'setupFee': setupFee,
        'setupFeeReference': setupFeeReference,
        'status': 'pending_activation', // Will be activated after 30 days
        'activationDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('delayed_subscriptions')
          .add(subscriptionData);

      print('Delayed subscription stored: ${docRef.id}');

      return {
        'success': true,
        'message': 'Delayed subscription created successfully',
        'subscriptionId': docRef.id,
        'customerId': customerId,
        'planId': planId,
        'activationDate': subscriptionData['activationDate'],
      };
    } catch (e) {
      print('Error creating delayed subscription: $e');
      return {
        'success': false,
        'message': 'Failed to create delayed subscription: ${e.toString()}',
      };
    }
  }

  /// Activate a delayed subscription (called after 30 days)
  static Future<Map<String, dynamic>> activateDelayedSubscription(
    String subscriptionId,
  ) async {
    try {
      print('=== ACTIVATING DELAYED SUBSCRIPTION ===');
      print('Subscription ID: $subscriptionId');

      // Get subscription data
      final doc = await _firestore
          .collection('delayed_subscriptions')
          .doc(subscriptionId)
          .get();

      if (!doc.exists) {
        return {'success': false, 'message': 'Subscription not found'};
      }

      final data = doc.data();
      if (data == null) {
        return {'success': false, 'message': 'Subscription data is null'};
      }

      final customerId = data['customerId'] as String?;
      final planId = data['planId'] as String?;
      final userEmail = data['userEmail'] as String?;

      if (customerId == null || planId == null || userEmail == null) {
        return {
          'success': false,
          'message': 'Missing required subscription data',
        };
      }

      // Create the actual Paystack subscription
      final subscriptionResult = await _createPaystackSubscription(
        customerId: customerId,
        planId: planId,
        userEmail: userEmail,
      );

      if (subscriptionResult == null || subscriptionResult['status'] != true) {
        return {
          'success': false,
          'message':
              'Failed to activate subscription: ${subscriptionResult?['message'] ?? 'Unknown error'}',
        };
      }

      // Update subscription status
      final subscriptionCode =
          subscriptionResult['data']?['subscription_code'] as String?;
      final userId = data['userId'] as String?;
      final packageName = data['packageName'] as String?;

      if (subscriptionCode == null || userId == null || packageName == null) {
        return {
          'success': false,
          'message': 'Missing required subscription data for activation',
        };
      }

      await _firestore
          .collection('delayed_subscriptions')
          .doc(subscriptionId)
          .update({
            'status': 'active',
            'paystackSubscriptionId': subscriptionCode,
            'activatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update user profile with active package
      await _firestore.collection('users').doc(userId).update({
        'activePackage': packageName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Subscription activated successfully');

      // Process initial monthly credit for the first month
      print('Processing initial monthly credit for $packageName');
      final creditResult = await MonthlyCreditService.processMonthlyCredit(
        userId: userId,
        packageName: packageName,
        transactionReference:
            'INITIAL_${DateTime.now().millisecondsSinceEpoch}',
        paymentAmount: data['monthlyAmount'] as double? ?? 0.0,
      );

      if (creditResult['success']) {
        print(
          'Initial monthly credit processed: R${creditResult['creditAmount']}',
        );
      } else {
        print(
          'Failed to process initial monthly credit: ${creditResult['message']}',
        );
      }

      return {
        'success': true,
        'message': 'Subscription activated successfully',
        'paystackSubscriptionId':
            subscriptionResult['data']['subscription_code'],
      };
    } catch (e) {
      print('Error activating delayed subscription: $e');
      return {
        'success': false,
        'message': 'Failed to activate subscription: ${e.toString()}',
      };
    }
  }

  /// Check and activate pending subscriptions (call this periodically)
  static Future<void> checkAndActivatePendingSubscriptions() async {
    try {
      print('=== CHECKING PENDING SUBSCRIPTIONS ===');

      final now = DateTime.now();
      final pendingSubs = await _firestore
          .collection('delayed_subscriptions')
          .where('status', isEqualTo: 'pending_activation')
          .where('activationDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      print('Found ${pendingSubs.docs.length} pending subscriptions');

      for (final doc in pendingSubs.docs) {
        final result = await activateDelayedSubscription(doc.id);
        if (result['success']) {
          print('Activated subscription: ${doc.id}');
        } else {
          print(
            'Failed to activate subscription ${doc.id}: ${result['message']}',
          );
        }
      }
    } catch (e) {
      print('Error checking pending subscriptions: $e');
    }
  }

  /// Create Paystack customer
  static Future<Map<String, dynamic>?> _createPaystackCustomer({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/customer');
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

      final body = {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print(
          'Customer creation error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error creating customer: $e');
      return null;
    }
  }

  /// Create Paystack plan
  static Future<Map<String, dynamic>?> _createPaystackPlan({
    required String name,
    required String description,
    required int amount,
    required String interval,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/plan');
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

      final body = {
        'name': name,
        'description': description,
        'amount': amount,
        'interval': interval,
        'currency': 'ZAR',
        'send_invoices': true,
        'send_sms': true,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Plan creation error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating plan: $e');
      return null;
    }
  }

  /// Create Paystack subscription
  static Future<Map<String, dynamic>?> _createPaystackSubscription({
    required String customerId,
    required String planId,
    required String userEmail,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/subscription');
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

      final body = {
        'customer': customerId,
        'plan': planId,
        'authorization': {
          'authorization_code': 'AUTH_${DateTime.now().millisecondsSinceEpoch}',
          'email': userEmail,
          'amount': 0, // Will be charged according to plan
        },
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print(
          'Subscription creation error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }
}
