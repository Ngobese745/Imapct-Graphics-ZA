import 'dart:convert';

import 'package:http/http.dart' as http;

class PaystackService {
  static const String _publicKey = 'pk_live_PLACEHOLDER';
  static const String _secretKey = 'sk_live_PLACEHOLDER';
  static const String _baseUrl = 'https://api.paystack.co';

  static PaystackService? _instance;
  static PaystackService get instance => _instance ??= PaystackService._();

  PaystackService._();

  /// Initialize Paystack
  void initialize() {
    // Initialize any required services
  }

  /// Process payment with Paystack
  Future<PaystackResponse> processPayment({
    required String email,
    required int amount,
    required String reference,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? currency = 'ZAR',
  }) async {
    try {
      print('=== PAYSTACK PAYMENT PROCESSING ===');
      print('Email: $email');
      print('Amount: $amount kobo (R${(amount / 100).toStringAsFixed(2)})');
      print('Reference: $reference');

      // Skip test transaction to avoid caching issues
      print('🚀 Proceeding directly with real transaction');

      // Create a real Paystack transaction
      final transaction = await createTransaction(
        email: email,
        amount: amount,
        reference: reference,
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        currency: currency,
      );

      print('=== TRANSACTION RESULT ===');
      print('Transaction result: $transaction');

      if (transaction != null && transaction['status'] == true) {
        var authorizationUrl = transaction['data']['authorization_url'];

        // Add cache-busting parameter to prevent R10 caching issues
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        if (authorizationUrl.contains('?')) {
          authorizationUrl += '&cb=$cacheBuster';
        } else {
          authorizationUrl += '?cb=$cacheBuster';
        }

        print('✅ Real Paystack transaction successful');
        print('Authorization URL: $authorizationUrl');

        return PaystackResponse(
          status: true,
          message: 'Payment initialized successfully',
          reference: reference,
          authorizationUrl: authorizationUrl,
        );
      } else {
        print('❌ Transaction failed or returned null');
        print('Transaction status: ${transaction?['status']}');
        print('Transaction data: ${transaction?['data']}');

        // Test API connection to see if the issue is with connectivity
        final apiTest = await testApiConnection();
        if (!apiTest) {
          print(
            '❌ API connection test failed - this explains why transaction failed',
          );
          throw Exception(
            'Paystack API connection failed. Please check your internet connection and try again.',
          );
        } else {
          print(
            '✅ API connection test passed - transaction failure is due to other reasons',
          );
          throw Exception('Payment initialization failed. Please try again.');
        }
      }
    } catch (e) {
      print('Paystack payment error: $e');
      // Re-throw the error instead of simulating
      rethrow;
    }
  }

  /// Test Paystack account configuration and key validity
  Future<Map<String, dynamic>> testAccountConfiguration() async {
    try {
      print('=== TESTING PAYSTACK ACCOUNT CONFIGURATION ===');

      // Test 1: Basic API connectivity
      final url = Uri.parse('$_baseUrl/balance');
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

      print('Testing API connectivity with balance endpoint...');
      final response = await http.get(url, headers: headers);

      print('Balance endpoint response: ${response.statusCode}');
      print('Balance response body: ${response.body}');

      if (response.statusCode == 200) {
        final balanceData = json.decode(response.body);
        print('✅ API connectivity test passed');

        // Handle the balance response structure - it's an array of currency objects
        if (balanceData['data'] is List && balanceData['data'].isNotEmpty) {
          final firstCurrency = balanceData['data'][0];
          final balance = firstCurrency['balance']?.toString() ?? '0';
          final currency = firstCurrency['currency'] ?? 'Unknown';

          print('✅ Account balance: $balance $currency');

          return {
            'api_connected': true,
            'balance': balance,
            'currency': currency,
            'message': 'Account configuration is valid',
          };
        } else {
          print('⚠️ Unexpected balance data structure: ${balanceData['data']}');
          return {
            'api_connected': true,
            'balance': 'Unknown',
            'currency': 'Unknown',
            'message':
                'Account configuration is valid but balance structure is unexpected',
          };
        }
      } else {
        print('❌ API connectivity test failed: ${response.statusCode}');
        return {
          'api_connected': false,
          'error': 'API connectivity failed: ${response.statusCode}',
          'message': 'Check your API keys and internet connection',
        };
      }
    } catch (e) {
      print('❌ Account configuration test failed: $e');
      return {
        'api_connected': false,
        'error': e.toString(),
        'message': 'Account configuration test failed',
      };
    }
  }

  /// Test Paystack API connectivity and key validity
  Future<bool> testApiConnection() async {
    try {
      print('=== TESTING PAYSTACK API CONNECTION ===');

      final response = await http.get(
        Uri.parse('$_baseUrl/transaction'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      print('API Test Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Paystack API connection successful');
        return true;
      } else if (response.statusCode == 401) {
        print('❌ Paystack API key invalid (401 Unauthorized)');
        return false;
      } else {
        print('❌ Paystack API connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Paystack API connection error: $e');
      return false;
    }
  }

  /// Test Paystack API with a minimal transaction
  Future<Map<String, dynamic>> testMinimalTransaction() async {
    try {
      print('=== TESTING MINIMAL PAYSTACK TRANSACTION ===');

      final testReference = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
      final testAmount = 100; // R1.00 minimum

      final url = Uri.parse('$_baseUrl/transaction/initialize');
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

      final body = {
        'email': 'test@example.com',
        'amount': testAmount,
        'reference': testReference,
        'currency': 'ZAR',
      };

      print('Test URL: $url');
      print('Test Headers: ${headers.keys.join(', ')}');
      print('Test Body: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print('Test Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          print('✅ Minimal transaction test successful');
          return result;
        } else {
          print('❌ Minimal transaction test failed: ${result['message']}');
          return {'status': false, 'message': result['message']};
        }
      } else {
        print('❌ Minimal transaction test failed: ${response.statusCode}');
        return {'status': false, 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Minimal transaction test error: $e');
      return {'status': false, 'message': e.toString()};
    }
  }

  /// Verify payment with Paystack
  Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      print('=== PAYSTACK PAYMENT VERIFICATION ===');
      print('Verifying payment with reference: $reference');

      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      print(
        'Paystack verification response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('=== PAYSTACK VERIFICATION RESPONSE ===');
        print('Full response: $data');

        final status = data['status'];
        final transactionData = data['data'];

        print('Response status: $status');
        print('Transaction data: $transactionData');

        // Check if transaction was not found
        if (status == false || transactionData == null) {
          print('❌ Transaction not found or invalid');
          return {
            'status': 'not_found',
            'verified': false,
            'message': 'Transaction not found or invalid',
          };
        }

        if (status == true && transactionData != null) {
          final transactionStatus = transactionData['status'];
          final amount = transactionData['amount'];
          final currency = transactionData['currency'];
          final reference = transactionData['reference'];

          print('=== TRANSACTION DETAILS ===');
          print('Transaction status: $transactionStatus');
          print('Amount: $amount');
          print('Currency: $currency');
          print('Reference: $reference');

          // Check if payment was successful
          if (transactionStatus == 'success') {
            print('✅ Paystack verification: Transaction status is SUCCESS');
            return {
              'status': 'success',
              'verified': true,
              'transaction': transactionData,
            };
          } else {
            print(
              '❌ Paystack verification: Transaction status is $transactionStatus (not success)',
            );
            return {
              'status': 'failed',
              'verified': false,
              'message':
                  'Transaction not successful (status: $transactionStatus)',
              'transaction': transactionData,
            };
          }
        } else {
          print('❌ Invalid response format from Paystack');
          return {
            'status': 'failed',
            'verified': false,
            'message': 'Invalid response from Paystack',
          };
        }
      } else if (response.statusCode == 404) {
        print('Transaction not found (404)');
        return {
          'status': 'not_found',
          'verified': false,
          'message': 'Transaction not found',
        };
      } else {
        print('Paystack verification failed: ${response.statusCode}');
        return {
          'status': 'error',
          'verified': false,
          'message': 'Verification request failed',
        };
      }
    } catch (e) {
      print('Payment verification error: $e');
      return {
        'status': 'error',
        'verified': false,
        'message': 'Verification error: ${e.toString()}',
      };
    }
  }

  /// Generate a unique reference for payment
  String generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'IGZ_$timestamp$random';
  }

  /// Format amount for display
  String formatAmount(int amount) {
    return 'R${(amount / 100).toStringAsFixed(2)}';
  }

  /// Convert amount to kobo (Paystack expects amount in kobo)
  int convertToKobo(double amount) {
    return (amount * 100).round();
  }

  /// Create a Paystack transaction (for real implementation)
  Future<Map<String, dynamic>?> createTransaction({
    required String email,
    required int amount,
    required String reference,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? currency = 'ZAR',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/transaction/initialize');
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

      final body = {
        'email': email,
        'amount': amount,
        'reference': reference,
        'currency': currency,
        'callback_url':
            'https://impact-graphics-za-266ef.web.app/payment-success',
        'metadata': {
          'phone_number': phoneNumber,
          'first_name': firstName,
          'last_name': lastName,
          'custom_fields': [
            {
              'display_name': 'Payment Source',
              'variable_name': 'payment_source',
              'value': 'mobile_app',
            },
          ],
        },
      };

      print('=== PAYSTACK API REQUEST ===');
      print('URL: $url');
      print(
        'Headers: ${headers.keys.join(', ')} (secret key: ${_secretKey.substring(0, 10)}...)',
      );
      print('Body: ${json.encode(body)}');

      // Validate parameters before sending
      if (amount <= 0) {
        throw Exception('Invalid amount: $amount (must be greater than 0)');
      }
      if (amount < 100) {
        throw Exception(
          'Amount too small: $amount kobo (minimum is 100 kobo = R1.00)',
        );
      }
      if (email.isEmpty) {
        throw Exception('Email is required');
      }
      if (reference.isEmpty) {
        throw Exception('Reference is required');
      }
      print('✅ All parameters validated successfully');
      print('Amount in kobo: $amount (R${(amount / 100).toStringAsFixed(2)})');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print('=== PAYSTACK API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Paystack API call successful');

        // Check if Paystack returned an error in the response
        if (result['status'] == false) {
          print('❌ Paystack returned error in response: ${result['message']}');
          print('❌ Full error response: ${json.encode(result)}');
          throw Exception('Paystack error: ${result['message']}');
        }

        // Additional validation for successful response
        if (result['data'] == null) {
          print('❌ Paystack response missing data field');
          print('❌ Full response: ${json.encode(result)}');
          throw Exception('Invalid Paystack response: missing data field');
        }

        if (result['data']['authorization_url'] == null) {
          print('❌ Paystack response missing authorization_url');
          print('❌ Data field: ${json.encode(result['data'])}');
          throw Exception(
            'Invalid Paystack response: missing authorization_url',
          );
        }

        print('✅ Paystack transaction created successfully');
        print('✅ Authorization URL: ${result['data']['authorization_url']}');
        print('✅ Access Code: ${result['data']['access_code']}');
        print('✅ Reference: ${result['data']['reference']}');

        return result;
      } else {
        print(
          '❌ Paystack API error: ${response.statusCode} - ${response.body}',
        );

        // Try to parse error response from Paystack
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            print('❌ Paystack error message: ${errorData['message']}');
            throw Exception('Paystack API error: ${errorData['message']}');
          }
        } catch (e) {
          print('❌ Could not parse error response: $e');
        }

        throw Exception(
          'Paystack API request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating Paystack transaction: $e');
      rethrow; // Re-throw the error instead of simulating
    }
  }

  /// Create a Paystack plan for subscription
  Future<Map<String, dynamic>?> createPlan({
    required String name,
    required String description,
    required int amount,
    required String interval,
    String? currency = 'ZAR',
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
        'currency': currency,
        'send_invoices': true,
        'send_sms': true,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Paystack plan created successfully: $responseData');
        return responseData;
      } else {
        final errorBody = response.body;
        print(
          'Paystack plan creation error: ${response.statusCode} - $errorBody',
        );
        return {
          'status': false,
          'message':
              'Failed to create plan: ${response.statusCode} - $errorBody',
        };
      }
    } catch (e) {
      print('Error creating Paystack plan: $e');
      return null;
    }
  }

  /// Create a Paystack customer
  Future<Map<String, dynamic>?> createCustomer({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
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
        if (phone != null) 'phone': phone,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Paystack customer created successfully: $responseData');
        return responseData;
      } else {
        final errorBody = response.body;
        print(
          'Paystack customer creation error: ${response.statusCode} - $errorBody',
        );
        return {
          'status': false,
          'message':
              'Failed to create customer: ${response.statusCode} - $errorBody',
        };
      }
    } catch (e) {
      print('Error creating Paystack customer: $e');
      return null;
    }
  }

  /// Create a Paystack subscription
  Future<Map<String, dynamic>?> createSubscription({
    required String customerId,
    required String planId,
    required String authorizationCode,
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
        'authorization': authorizationCode,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
          'Paystack subscription creation error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error creating Paystack subscription: $e');
      return null;
    }
  }

  /// Process subscription payment with setup fee
  Future<PaystackSubscriptionResponse> processSubscriptionPayment({
    required String email,
    required String firstName,
    required String lastName,
    required String packageName,
    required int monthlyAmount,
    required int setupFee,
    String? phone,
  }) async {
    try {
      print('=== STARTING SUBSCRIPTION PAYMENT PROCESS ===');
      print('Email: $email');
      print('Package: $packageName');
      print('Monthly Amount: ${monthlyAmount / 100} ZAR');
      print('Setup Fee: ${setupFee / 100} ZAR');

      // Step 1: Create customer
      print('Step 1: Creating customer...');
      final customerResult = await createCustomer(
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      if (customerResult == null || customerResult['status'] != true) {
        final errorMessage =
            customerResult?['message'] ?? 'Failed to create customer';
        print('Customer creation failed: $errorMessage');
        return PaystackSubscriptionResponse(
          status: false,
          message: errorMessage,
        );
      }

      final customerId = customerResult['data']['customer_code'];
      print('Customer created successfully: $customerId');

      // Step 2: Create plan
      print('Step 2: Creating plan...');
      final planResult = await createPlan(
        name: '$packageName Subscription',
        description: 'Monthly subscription for $packageName package',
        amount: monthlyAmount,
        interval: 'monthly',
      );

      if (planResult == null || planResult['status'] != true) {
        final errorMessage =
            planResult?['message'] ?? 'Failed to create subscription plan';
        print('Plan creation failed: $errorMessage');
        return PaystackSubscriptionResponse(
          status: false,
          message: errorMessage,
        );
      }

      final planId = planResult['data']['plan_code'];
      print('Plan created successfully: $planId');

      // Step 3: Process setup fee payment
      print('Step 3: Creating setup fee transaction...');
      final setupFeeReference = generateReference();
      final setupFeeTransaction = await createTransaction(
        email: email,
        amount: setupFee,
        reference: setupFeeReference,
        phoneNumber: phone,
        firstName: firstName,
        lastName: lastName,
      );

      if (setupFeeTransaction == null ||
          setupFeeTransaction['status'] != true) {
        print('Setup fee transaction failed');
        return PaystackSubscriptionResponse(
          status: false,
          message: 'Failed to process setup fee payment',
        );
      }

      print('Setup fee transaction created successfully');
      print(
        'Authorization URL: ${setupFeeTransaction['data']['authorization_url']}',
      );

      return PaystackSubscriptionResponse(
        status: true,
        message: 'Subscription setup initiated successfully',
        customerId: customerId,
        planId: planId,
        setupFeeReference: setupFeeReference,
        authorizationUrl: setupFeeTransaction['data']['authorization_url'],
      );
    } catch (e) {
      print('Subscription payment error: $e');
      return PaystackSubscriptionResponse(
        status: false,
        message: 'Subscription setup failed: ${e.toString()}',
      );
    }
  }
}

/// Payment response model
class PaystackResponse {
  final bool status;
  final String message;
  final String reference;
  final String? authorizationUrl;

  PaystackResponse({
    required this.status,
    required this.message,
    required this.reference,
    this.authorizationUrl,
  });
}

/// Payment request model
class PaystackRequest {
  final int amount;
  final String email;
  final String reference;
  final String currency;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;

  PaystackRequest({
    required this.amount,
    required this.email,
    required this.reference,
    required this.currency,
    this.phoneNumber,
    this.firstName,
    this.lastName,
  });
}

/// Subscription response model
class PaystackSubscriptionResponse {
  final bool status;
  final String message;
  final String? customerId;
  final String? planId;
  final String? setupFeeReference;
  final String? authorizationUrl;

  PaystackSubscriptionResponse({
    required this.status,
    required this.message,
    this.customerId,
    this.planId,
    this.setupFeeReference,
    this.authorizationUrl,
  });
}
