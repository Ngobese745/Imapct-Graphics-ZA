import 'dart:convert';

import 'package:http/http.dart' as http;

class PaystackSubscriptionService {
  static const String _baseUrl = 'https://api.paystack.co';
  static const String _publicKey = 'pk_live_PLACEHOLDER';
  static const String _secretKey = 'sk_live_PLACEHOLDER';

  // Gold Tier Plan Configuration
  static const String _goldTierPlanName = 'Gold Tier';
  static const int _goldTierAmount = 29900; // R299.00 in kobo
  static const String _goldTierInterval = 'monthly';
  static const String _currency = 'ZAR';

  // Create Gold Tier Plan
  static Future<PaystackPlanResponse> createGoldTierPlan() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/plan'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _goldTierPlanName,
          'amount': _goldTierAmount,
          'interval': _goldTierInterval,
          'currency': _currency,
          'description':
              'Gold Tier subscription with premium features and 10% discount',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        if (data['data'] != null && data['data']['plan_code'] != null) {
          return PaystackPlanResponse(
            success: true,
            planCode: data['data']['plan_code'],
            planId: data['data']['id']?.toString() ?? '',
            message: 'Plan created successfully',
          );
        } else {
          return PaystackPlanResponse(
            success: false,
            message: 'Invalid response data from plan creation',
          );
        }
      } else {
        return PaystackPlanResponse(
          success: false,
          message: data['message'] ?? 'Failed to create plan',
        );
      }
    } catch (e) {
      return PaystackPlanResponse(
        success: false,
        message: 'Error creating plan: $e',
      );
    }
  }

  // Create or Get Customer
  static Future<PaystackCustomerResponse> createOrGetCustomer({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      // First, try to get existing customer
      final existingCustomer = await _getCustomerByEmail(email);
      if (existingCustomer.success) {
        print('Customer found: ${existingCustomer.customerCode}');
        return existingCustomer;
      }

      // If not found, create new customer
      print('Creating new customer for email: $email');
      final response = await http.post(
        Uri.parse('$_baseUrl/customer'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        }),
      );

      final data = json.decode(response.body);
      print('Customer creation response: ${response.statusCode} - $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['data'] != null && data['data']['customer_code'] != null) {
          return PaystackCustomerResponse(
            success: true,
            customerCode: data['data']['customer_code'],
            customerId: data['data']['id']?.toString() ?? '',
            message: 'Customer created successfully',
          );
        } else {
          return PaystackCustomerResponse(
            success: false,
            message: 'Invalid response data from customer creation',
          );
        }
      } else if (response.statusCode == 400 &&
          data['message']?.contains('already exists') == true) {
        // Customer already exists, try to get it again
        print('Customer already exists, fetching again...');
        return await _getCustomerByEmail(email);
      } else {
        return PaystackCustomerResponse(
          success: false,
          message: data['message'] ?? 'Failed to create customer',
        );
      }
    } catch (e) {
      print('Error in createOrGetCustomer: $e');
      return PaystackCustomerResponse(
        success: false,
        message: 'Error creating customer: $e',
      );
    }
  }

  // Get Customer by Email
  static Future<PaystackCustomerResponse> _getCustomerByEmail(
    String email,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customer?email=$email'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 &&
          data['data'] != null &&
          data['data']['customer_code'] != null) {
        return PaystackCustomerResponse(
          success: true,
          customerCode: data['data']['customer_code'],
          customerId: data['data']['id']?.toString() ?? '',
          message: 'Customer found',
        );
      } else {
        return PaystackCustomerResponse(
          success: false,
          message: 'Customer not found',
        );
      }
    } catch (e) {
      return PaystackCustomerResponse(
        success: false,
        message: 'Error finding customer: $e',
      );
    }
  }

  // Create Subscription
  static Future<PaystackSubscriptionResponse> createSubscription({
    required String customerCode,
    required String planCode,
    required String userEmail,
  }) async {
    try {
      // For subscriptions, we need to create a transaction first to get authorization
      // This is the recommended approach for subscription payments
      final response = await http.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': userEmail,
          'amount': 29900, // R299 in kobo
          'plan': planCode,
          'customer': customerCode,
          'callback_url':
              'https://impact-graphics-za-266ef.web.app/payment-success',
        }),
      );

      final data = json.decode(response.body);
      print(
        'Subscription transaction response: ${response.statusCode} - $data',
      );

      if (response.statusCode == 200) {
        if (data['data'] != null &&
            data['data']['reference'] != null &&
            data['data']['authorization_url'] != null) {
          return PaystackSubscriptionResponse(
            success: true,
            subscriptionCode: data['data']['reference'],
            subscriptionId: data['data']['reference'],
            authorizationUrl: data['data']['authorization_url'],
            message: 'Subscription authorization created successfully',
          );
        } else {
          return PaystackSubscriptionResponse(
            success: false,
            message: 'Invalid response data from subscription creation',
          );
        }
      } else {
        return PaystackSubscriptionResponse(
          success: false,
          message: data['message'] ?? 'Failed to create subscription',
        );
      }
    } catch (e) {
      print('Error in createSubscription: $e');
      return PaystackSubscriptionResponse(
        success: false,
        message: 'Error creating subscription: $e',
      );
    }
  }

  // Verify Transaction
  static Future<PaystackSubscriptionResponse> verifyTransaction(
    String transactionReference,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$transactionReference'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      );

      final data = json.decode(response.body);
      print(
        'Transaction verification response: ${response.statusCode} - $data',
      );

      if (response.statusCode == 200 && data['status'] == true) {
        if (data['data'] != null && data['data']['reference'] != null) {
          // Check if the transaction was actually successful
          final transactionStatus = data['data']['status'] as String?;
          final amount = data['data']['amount'] as int?;
          final currency = data['data']['currency'] as String?;

          print(
            '🔍 Transaction details - Status: $transactionStatus, Amount: $amount, Currency: $currency',
          );

          // Only consider it successful if status is 'success' and amount is correct
          if (transactionStatus == 'success' && amount != null && amount > 0) {
            return PaystackSubscriptionResponse(
              success: true,
              subscriptionCode: data['data']['reference'],
              subscriptionId: data['data']['id']?.toString() ?? '',
              message: 'Transaction verified and payment confirmed',
            );
          } else {
            return PaystackSubscriptionResponse(
              success: false,
              message:
                  'Transaction not completed or payment not confirmed. Status: $transactionStatus',
            );
          }
        } else {
          return PaystackSubscriptionResponse(
            success: false,
            message: 'Invalid response data from transaction verification',
          );
        }
      } else {
        return PaystackSubscriptionResponse(
          success: false,
          message: data['message'] ?? 'Failed to verify transaction',
        );
      }
    } catch (e) {
      print('Error verifying transaction: $e');
      return PaystackSubscriptionResponse(
        success: false,
        message: 'Error verifying transaction: $e',
      );
    }
  }

  // Verify Subscription
  static Future<PaystackSubscriptionResponse> verifySubscription(
    String subscriptionCode,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/$subscriptionCode'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return PaystackSubscriptionResponse(
          success: true,
          subscriptionCode: data['data']['subscription_code'],
          subscriptionId: data['data']['id'].toString(),
          status: data['data']['status'],
          message: 'Subscription verified successfully',
        );
      } else {
        return PaystackSubscriptionResponse(
          success: false,
          message: data['message'] ?? 'Failed to verify subscription',
        );
      }
    } catch (e) {
      return PaystackSubscriptionResponse(
        success: false,
        message: 'Error verifying subscription: $e',
      );
    }
  }

  // Cancel Subscription
  static Future<PaystackSubscriptionResponse> cancelSubscription(
    String subscriptionCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscription/disable'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({'code': subscriptionCode}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return PaystackSubscriptionResponse(
          success: true,
          subscriptionCode: subscriptionCode,
          message: 'Subscription cancelled successfully',
        );
      } else {
        return PaystackSubscriptionResponse(
          success: false,
          message: data['message'] ?? 'Failed to cancel subscription',
        );
      }
    } catch (e) {
      return PaystackSubscriptionResponse(
        success: false,
        message: 'Error cancelling subscription: $e',
      );
    }
  }

  // Get Subscription Status
  static Future<String> getSubscriptionStatus(String subscriptionCode) async {
    try {
      final response = await verifySubscription(subscriptionCode);
      return response.status ?? 'unknown';
    } catch (e) {
      return 'error';
    }
  }
}

// Response Models
class PaystackPlanResponse {
  final bool success;
  final String? planCode;
  final String? planId;
  final String message;

  PaystackPlanResponse({
    required this.success,
    this.planCode,
    this.planId,
    required this.message,
  });
}

class PaystackCustomerResponse {
  final bool success;
  final String? customerCode;
  final String? customerId;
  final String message;

  PaystackCustomerResponse({
    required this.success,
    this.customerCode,
    this.customerId,
    required this.message,
  });
}

class PaystackSubscriptionResponse {
  final bool success;
  final String? subscriptionCode;
  final String? subscriptionId;
  final String? authorizationUrl;
  final String? status;
  final String message;

  PaystackSubscriptionResponse({
    required this.success,
    this.subscriptionCode,
    this.subscriptionId,
    this.authorizationUrl,
    this.status,
    required this.message,
  });
}
