import 'dart:async';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main.dart'; // Import CartItem from main.dart
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/firebase_service.dart';
import '../services/loyalty_reward_service.dart';
import '../services/mailersend_service.dart';
import '../services/notification_service.dart';
import '../services/paystack_customer_service.dart';
import '../services/paystack_service.dart';
import '../services/pending_payment_service.dart';
import '../services/referral_service.dart';
import '../services/wallet_service.dart';
import 'manage_saved_cards_screen.dart';

class PaystackPaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final String userEmail;
  final String? userName;
  final String? userPhone;
  final String? userId;
  final String? paymentType; // 'cart', 'subscription', 'wallet_funding'

  const PaystackPaymentScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.userEmail,
    this.userName,
    this.userPhone,
    this.userId,
    this.paymentType,
  });

  @override
  State<PaystackPaymentScreen> createState() => _PaystackPaymentScreenState();
}

class _PaystackPaymentScreenState extends State<PaystackPaymentScreen> {
  bool _isInitializing = false;
  String? _authorizationUrl;
  String? _reference;
  late WebViewController _webViewController;
  bool _showWebView = false;
  bool _paymentOpened = false;
  final PaystackCustomerService _customerService =
      PaystackCustomerService.instance;

  @override
  void initState() {
    super.initState();
    print('=== PAYSTACK PAYMENT SCREEN INITSTATE ===');
    print('Widget Total Amount: R${widget.totalAmount}');
    print('Widget User Email: ${widget.userEmail}');
    print('Widget Payment Type: ${widget.paymentType}');
    print('Widget Cart Items: ${widget.cartItems.length}');
    _initializeWebView();

    // Clear any old pending payments first to prevent R10 hardcoded issue
    PendingPaymentService.clearPendingPayment().then((_) {
      print('🧹 Cleared old pending payments');
      // Always initialize a fresh payment
      _initializePayment();
    });
  }

  void _initializeWebView() {
    // Skip WebView initialization on web platforms
    if (kIsWeb) {
      print('🌐 Skipping WebView initialization on web platform');
      return;
    }

    // Initialize WebViewController for mobile platforms only
    _webViewController = WebViewController();
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          print('WebView navigating to: ${request.url}');

          // Check for Paystack failure URLs first
          if (request.url.contains('paystack.com/failed') ||
              request.url.contains('paystack.com/error') ||
              request.url.contains('paystack.com/cancel') ||
              request.url.contains('transaction-not-found') ||
              request.url.contains('payment-failed') ||
              request.url.contains('not-found')) {
            // Payment failed - show error message
            print('Payment failure detected from URL: ${request.url}');
            _handlePaymentFailure('Payment failed or was cancelled');
            return NavigationDecision.prevent;
          }

          // Check for Paystack success URLs - be more specific
          if (request.url.contains('paystack.com/success') ||
              (request.url.contains('paystack.com/callback') &&
                  request.url.contains('status=success')) ||
              (request.url.contains('paystack.com/complete') &&
                  request.url.contains('status=success')) ||
              // Check for Paystack callback URLs with reference parameters (successful payments)
              (request.url.contains('paystack.com/callback') &&
                  (request.url.contains('trxref=') ||
                      request.url.contains('reference=')))) {
            // Payment completed successfully - extract reference from URL and verify
            print('Payment success detected from URL: ${request.url}');
            _extractReferenceAndVerifyPayment(request.url);
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        },
      ),
    );
  }

  /// Handle web payment by opening Paystack in new tab/window
  Future<void> _handleWebPayment() async {
    try {
      print('🌐 _handleWebPayment() called');
      print('🌐 Authorization URL: $_authorizationUrl');

      if (_authorizationUrl == null) {
        print('❌ Authorization URL is null!');
        throw Exception('Authorization URL is null');
      }

      // Store pending payment before opening Paystack
      if (_reference != null) {
        await PendingPaymentService.storePendingPayment(
          reference: _reference!,
          authorizationUrl: _authorizationUrl!,
          cartItems: widget.cartItems
              .map(
                (item) => {
                  'id': item.id,
                  'name': item.name,
                  'description': item.description,
                  'price': item.price,
                  'budget': item.budget,
                },
              )
              .toList(),
          totalAmount: widget.totalAmount,
          paystackAmount:
              widget.totalAmount, // Full amount for regular payments
          walletAmount: 0.0, // No wallet amount for regular payments
          userId: widget.userId ?? '',
          userEmail: widget.userEmail,
          userName: widget.userName ?? '',
          userPhone: widget.userPhone ?? '',
        );
        print('💾 Pending payment stored: $_reference');
      }

      final uri = Uri.parse(_authorizationUrl!);
      print('🌐 Parsed URI: $uri');

      // Try to open Paystack payment - use platformDefault for better browser compatibility
      bool launched = false;

      try {
        print('🌐 Attempting to open URL with platformDefault mode...');
        // Try popup mode first (better for web)
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
        print('✅ Paystack payment window opened successfully: $launched');
      } catch (e) {
        print('⚠️ Popup mode failed: $e, trying external application mode');
        // Fallback to external application mode
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ External application mode result: $launched');
      }

      if (!launched) {
        throw Exception(
          'Cannot open payment URL. Please check your browser settings.',
        );
      }

      // Update state to show payment opened screen
      if (mounted) {
        setState(() {
          _paymentOpened = true;
        });
      }

      // Listen for payment success message from popup
      if (kIsWeb) {
        // Set up message listener for payment success from popup
        _setupPaymentMessageListener();

        // Start webhook polling instead of direct verification
        _startWebhookPolling();
      }
    } catch (e) {
      print('Error handling web payment: $e');
      _showErrorDialog(
        'Failed to open payment page. Please ensure popups are allowed in your browser and try again.\n\nError: ${e.toString()}',
      );
    }
  }

  /// Verify web payment after user completes it (with webhook support)
  Future<void> _verifyWebPayment() async {
    if (_reference == null) {
      _showErrorDialog('Payment reference not found. Please try again.');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF8B0000)),
                SizedBox(height: 16),
                Text(
                  'Verifying payment...',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'This may take a moment as we process your payment',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      // First, check if payment was already processed by webhook
      final orderQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('paymentReference', isEqualTo: _reference)
          .limit(1)
          .get();

      if (orderQuery.docs.isNotEmpty) {
        final orderDoc = orderQuery.docs.first;
        final orderData = orderDoc.data();

        if (orderData['paymentStatus'] == 'success') {
          // Payment already processed by webhook
          Navigator.of(context).pop(); // Close loading dialog
          _handlePaymentSuccess();
          return;
        }
      }

      // If not processed by webhook, try manual verification
      print('Payment not found in orders, attempting manual verification...');

      // Add a delay to allow Paystack to process the transaction
      await Future.delayed(const Duration(seconds: 3));

      // Test API connection and account configuration first
      final accountTest = await PaystackService.instance
          .testAccountConfiguration();

      if (!accountTest['api_connected']) {
        if (mounted) Navigator.of(context).pop();
        _showErrorDialog(
          'Payment service configuration error: ${accountTest['message']}',
        );
        return;
      }

      print('✅ Paystack account configuration verified');
      print('✅ Account balance: ${accountTest['balance']}');
      print('✅ Currency: ${accountTest['currency']}');

      // Verify payment with Paystack API
      final verificationResult = await PaystackService.instance.verifyPayment(
        _reference!,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      print('=== WEB PAYMENT VERIFICATION RESULT ===');
      print('Status: ${verificationResult['status']}');
      print('Verified: ${verificationResult['verified']}');
      print('Message: ${verificationResult['message']}');

      if (verificationResult['status'] == true &&
          verificationResult['data']['status'] == 'success') {
        print(
          '✅ Web payment verification successful - proceeding with wallet funding',
        );
        await _handlePaymentSuccess();
      } else if (verificationResult['status'] == false) {
        _showErrorDialog('Payment was not completed. Please try again.');
      } else {
        _showErrorDialog(
          'Payment verification failed. Please contact support if you have been charged.',
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Payment verification error: ${e.toString()}');
    }
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      print('=== PAYMENT SCREEN INITIALIZATION ===');
      print('Total Amount: R${widget.totalAmount}');
      print('User Email: ${widget.userEmail}');
      print('Payment Type: ${widget.paymentType}');

      // Generate reference and convert amount
      _reference = PaystackService.instance.generateReference();
      final amountInKobo = PaystackService.instance.convertToKobo(
        widget.totalAmount,
      );

      print('Generated Reference: $_reference');
      print('Amount in Kobo: $amountInKobo');

      print('🚀 Calling PaystackService.processPayment...');

      // Process payment with Paystack to get authorization URL
      final response = await PaystackService.instance.processPayment(
        email: widget.userEmail,
        amount: amountInKobo,
        reference: _reference!,
        phoneNumber: widget.userPhone,
        firstName: widget.userName?.split(' ').first,
        lastName: (widget.userName?.split(' ').length ?? 0) > 1
            ? widget.userName!.split(' ').last
            : null,
      );

      print('=== PAYSTACK RESPONSE RECEIVED ===');
      print('Response Status: ${response.status}');
      print('Response Message: ${response.message}');
      print('Authorization URL: ${response.authorizationUrl}');

      if (response.status && response.authorizationUrl != null) {
        _authorizationUrl = response.authorizationUrl;
        print('✅ Payment initialization successful');
        setState(() {
          _isInitializing = false;
          // Only show WebView on non-web platforms
          _showWebView = !kIsWeb;
        });
        // Load the payment URL in WebView
        print('🌐 Platform check: kIsWeb = $kIsWeb');
        if (!kIsWeb) {
          print('📱 Mobile platform - loading WebView');
          _webViewController.loadRequest(Uri.parse(_authorizationUrl!));
        } else {
          // For web platform, automatically open payment in new tab
          print('🌐 Web platform detected - opening payment in new tab');
          print('🌐 Authorization URL: $_authorizationUrl');
          // Keep loading state while opening payment
          _handleWebPayment();
        }

        // Payment initialized successfully - wait for user to complete payment
      } else {
        _showErrorDialog(response.message);
      }
    } catch (e) {
      _showErrorDialog('Payment initialization failed: ${e.toString()}');
    }
  }

  /// Handle payment failure
  void _handlePaymentFailure(String message) {
    setState(() {
      _showWebView = false;
    });

    // Send failure notification to user
    _sendPaymentFailureNotification(message);

    _showErrorDialog(message);
  }

  /// Send payment failure notification
  Future<void> _sendPaymentFailureNotification(String message) async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await NotificationService.sendNotificationToUser(
          userId: currentUser.uid,
          title: 'Payment Failed ❌',
          body: 'Your wallet funding payment failed. Please try again.',
          type: 'payment_failed',
          action: 'payment_failed',
        );
      }
    } catch (e) {
      print('Error sending payment failure notification: $e');
    }
  }

  /// Extract reference from Paystack callback URL and verify payment
  Future<void> _extractReferenceAndVerifyPayment(String url) async {
    try {
      // Parse the URL to extract query parameters
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      // Try to extract reference from various possible parameters
      String? actualReference =
          queryParams['reference'] ??
          queryParams['trxref'] ??
          queryParams['ref'];

      print('=== EXTRACTING REFERENCE FROM URL ===');
      print('URL: $url');
      print('Query params: $queryParams');
      print('Extracted reference: $actualReference');
      print('Original reference: $_reference');

      // Use the extracted reference if available, otherwise fall back to original
      final referenceToUse = actualReference ?? _reference;

      if (referenceToUse == null) {
        _showErrorDialog(
          'Payment reference not found in callback. Please try again.',
        );
        return;
      }

      // Update the reference to the actual one from Paystack
      _reference = referenceToUse;

      // Now verify the payment with the correct reference
      await _verifyAndHandlePaymentSuccess();
    } catch (e) {
      print('Error extracting reference from URL: $e');
      // Fall back to original verification method
      await _verifyAndHandlePaymentSuccess();
    }
  }

  /// Verify payment with Paystack API before handling success
  Future<void> _verifyAndHandlePaymentSuccess() async {
    if (_reference == null) {
      _showErrorDialog('Payment reference not found. Please try again.');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF8B0000)),
                SizedBox(height: 16),
                Text(
                  'Verifying payment...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );

      // Test API connection and account configuration first
      print('🔍 Testing Paystack API connection and account configuration...');
      final accountTest = await PaystackService.instance
          .testAccountConfiguration();

      if (!accountTest['api_connected']) {
        print('❌ Paystack account configuration test failed');
        print('❌ Error: ${accountTest['error']}');
        await _sendPaymentFailureNotification(
          'Payment service configuration error. Please contact support.',
        );
        _showErrorDialog(
          'Payment service configuration error: ${accountTest['message']}',
        );
        return;
      }

      print('✅ Paystack account configuration test passed');
      print('✅ Account balance: ${accountTest['balance']}');
      print('✅ Currency: ${accountTest['currency']}');

      print(
        '✅ Paystack API connection successful - proceeding with verification',
      );

      // Verify payment with Paystack API with retry mechanism
      Map<String, dynamic> verificationResult;
      int retryCount = 0;
      const maxRetries = 3;

      do {
        // Add delay before verification (increases with each retry)
        if (retryCount > 0) {
          final delaySeconds = 2 + (retryCount * 2); // 2s, 4s, 6s
          print('⏳ Waiting $delaySeconds seconds before retry $retryCount...');
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          print('⏳ Waiting 3 seconds for Paystack to process transaction...');
          await Future.delayed(const Duration(seconds: 3));
        }

        verificationResult = await PaystackService.instance.verifyPayment(
          _reference!,
        );

        retryCount++;
        print(
          'Verification attempt $retryCount: ${verificationResult['status']}',
        );

        // If verification is successful, break out of retry loop
        if (verificationResult['status'] == true &&
            verificationResult['data']['status'] == 'success') {
          break;
        }

        // If transaction not found, don't retry
        if (verificationResult['status'] == false) {
          break;
        }
      } while (retryCount < maxRetries &&
          !(verificationResult['status'] == true &&
              verificationResult['data']['status'] == 'success'));

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      print('=== PAYMENT VERIFICATION RESULT ===');
      print('Status: ${verificationResult['status']}');
      print('Verified: ${verificationResult['verified']}');
      print('Message: ${verificationResult['message']}');

      if (verificationResult['status'] == true &&
          verificationResult['data']['status'] == 'success') {
        // Payment is verified - set flag and proceed with success handling
        print(
          '✅ Payment verification successful - proceeding with wallet funding',
        );
        await _handlePaymentSuccess();
      } else if (verificationResult['status'] == false) {
        // Transaction not found - payment was not completed
        await _sendPaymentFailureNotification(
          'Payment was not completed. Please try again.',
        );
        _showErrorDialog(
          'Payment was not completed. No charges were made to your account.',
        );
      } else {
        // Payment verification failed after retries
        final errorMessage = retryCount >= maxRetries
            ? 'Payment verification failed after $maxRetries attempts. This may be a temporary issue. Please contact support if you have been charged.'
            : 'Payment verification failed. Please contact support if you have been charged.';

        await _sendPaymentFailureNotification(
          'Payment verification failed. Please try again.',
        );
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Payment verification error: ${e.toString()}');
    }
  }

  /// Set up message listener for payment success from popup window
  void _setupPaymentMessageListener() {
    if (kIsWeb) {
      // Listen for messages from the payment popup window
      html.window.addEventListener('message', (html.Event event) {
        final messageEvent = event as html.MessageEvent;
        if (messageEvent.data != null && messageEvent.data is Map) {
          final data = messageEvent.data as Map<String, dynamic>;
          if (data['type'] == 'payment_success') {
            print(
              '🎉 Paystack Payment - Received payment success message from popup',
            );
            print('🎉 Payment reference: ${data['reference']}');

            // Trigger immediate payment verification
            _handlePaymentSuccess();
          }
        }
      });
      print('✅ Paystack Payment - Message listener set up for payment success');
    }
  }

  // Removed old payment verification methods - now using webhook approach

  /// Check for pending payments (webhook-based approach)
  Future<void> _checkForPendingPayments() async {
    try {
      print('🔍 Checking for pending payments...');

      final pendingPayment = await PendingPaymentService.getPendingPayment();

      if (pendingPayment != null) {
        print('✅ Found pending payment: ${pendingPayment['reference']}');

        setState(() {
          _reference = pendingPayment['reference'] as String?;
          _authorizationUrl = pendingPayment['authorizationUrl'] as String?;
          _paymentOpened = true; // Mark payment as opened
          _isInitializing = false; // Ensure loading state is cleared
        });

        // Show payment opened screen and wait for webhook
        print('⏳ Waiting for webhook verification...');
        _startWebhookPolling();
      } else {
        print('ℹ️ No pending payments found');
      }
    } catch (e) {
      print('❌ Error checking pending payments: $e');
    }
  }

  /// Start polling for webhook completion
  void _startWebhookPolling() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkWebhookCompletion(timer);
    });
  }

  /// Check if payment was completed via webhook
  Future<void> _checkWebhookCompletion(Timer timer) async {
    try {
      if (_reference == null) {
        timer.cancel();
        return;
      }

      // Check if payment was processed by looking for transaction record
      final transactionQuery = await FirebaseFirestore.instance
          .collection('transactions')
          .where('transactionId', isEqualTo: _reference)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (transactionQuery.docs.isNotEmpty) {
        print('✅ Payment completed via webhook!');
        timer.cancel();

        if (mounted) {
          setState(() {
            _showWebView = false;
            _isInitializing = false;
            _paymentOpened = false;
          });
        }

        await _handleWebhookSuccess();
      } else {
        print('⏳ Still waiting for webhook...');

        // Stop polling after 5 minutes
        if (timer.tick > 150) {
          print('⏰ Webhook timeout - stopping polling');
          timer.cancel();
          _showTimeoutMessage();
        }
      }
    } catch (e) {
      print('❌ Error checking webhook completion: $e');
    }
  }

  /// Handle successful payment via webhook
  Future<void> _handleWebhookSuccess() async {
    try {
      print('🎉 Payment completed via webhook!');

      // Clear pending payment
      await PendingPaymentService.clearPendingPayment();

      // Refresh user profile to get updated wallet balance
      final authService = AuthService.instance;
      if (authService != null) {
        await authService.refreshUserProfile();
        print('✅ User profile refreshed after webhook payment');
      }

      // Clear wallet cache to force refresh
      try {
        final cacheService = CacheService();
        final currentUser = auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          cacheService.clearCache('wallet_${currentUser.uid}');
          cacheService.clearCache('transactions_${currentUser.uid}');
          print('✅ Wallet cache cleared after webhook payment');
        }
      } catch (e) {
        print('⚠️ Error clearing wallet cache: $e');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Ref: $_reference'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Wait a moment then close
        await Future.delayed(const Duration(milliseconds: 1000));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ Error handling webhook success: $e');
    }
  }

  /// Show timeout message if webhook doesn't arrive
  void _showTimeoutMessage() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Row(
              children: [
                Icon(Icons.timer, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text(
                  'Payment Processing',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: const Text(
              'Your payment is being processed. You will receive a notification once it\'s completed. You can close this window and check back later.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(true); // Close payment screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _handlePaymentSuccess() async {
    // print('Payment success detected, showing success dialog');
    setState(() {
      _showWebView = false;
      _isInitializing = false; // Ensure loading state is cleared
      _paymentOpened = false; // Reset payment opened state
    });

    // Handle payment success - either cart items or package subscription
    String? orderId;
    String? orderNumber;
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get user profile data for proper customer name
        final userProfile = AuthService.instance?.userProfile;
        final userName = userProfile?['name'] as String?;
        final userEmail = userProfile?['email'] as String?;

        if (widget.cartItems.isNotEmpty) {
          // Handle cart items payment
          final cartItem = widget.cartItems.first;
          final orderData = {
            'userId': currentUser.uid,
            'customerName':
                userName ?? currentUser.displayName ?? 'Unknown Customer',
            'customerEmail': userEmail ?? currentUser.email ?? 'No email',
            'serviceId': cartItem.id,
            'serviceName': cartItem.name,
            'title': cartItem.name, // Add title field for order display
            'serviceDescription': cartItem.description,
            'projectDescription': cartItem.description,
            'originalPrice': cartItem.price,
            'finalPrice': widget.totalAmount,
            'budget': cartItem.budget,
            'status':
                'completed', // Mark as completed/paid immediately since payment is successful
            'paymentStatus':
                'completed', // Track that payment is already completed
            'transactionId':
                _reference ??
                'PAYSTACK-${DateTime.now().millisecondsSinceEpoch}',
            'paidAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          orderId = await FirebaseService.createOrder(orderData);
          // print('Order created in Firestore with ID: $orderId');

          // Fetch the order number from the created order
          try {
            final orderDoc = await FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .get();
            if (orderDoc.exists) {
              final orderData = orderDoc.data() as Map<String, dynamic>;
              orderNumber = orderData['orderNumber']?.toString();
              // print('Order number: $orderNumber');
            }
          } catch (e) {
            // print('Error fetching order number: $e');
          }

          // Send notification to admin about new order
          await NotificationService.sendNewOrderNotificationToAdmin(
            orderId: orderId,
            customerName: currentUser.displayName ?? 'Customer',
            serviceName: cartItem.name,
            amount: widget.totalAmount,
          );

          // Create transaction for the order
          await FirebaseService.createTransaction(
            userId: currentUser.uid,
            type: 'debit',
            amount: widget.totalAmount,
            description: 'Payment for ${cartItem.name}',
            orderId: orderId,
            orderNumber: orderNumber, // Pass the order number
            transactionId:
                _reference ??
                'PAYSTACK-${DateTime.now().millisecondsSinceEpoch}',
          );

          // Add loyalty points for the purchase (10 points per purchase)
          await FirebaseService.addLoyaltyPoints(currentUser.uid, 10);

          // Check for loyalty reward after adding points
          await _checkLoyaltyReward(currentUser.uid);

          // Send loyalty points notification
          await NotificationService.sendLoyaltyPointsNotification(
            userId: currentUser.uid,
            pointsEarned: 10,
            totalPoints: 110, // This would be fetched from user profile
          );

          // Create update notification for admin
          await FirebaseService.createUpdate(
            title: 'New Order Created',
            message:
                '${cartItem.name} order created with price: R${widget.totalAmount.toStringAsFixed(2)}',
            type: 'order_created',
            userId: currentUser.uid,
            orderId: orderId,
          );
        } else {
          // Handle empty cart scenarios - check payment type
          if (widget.paymentType == 'wallet_funding') {
            // Handle wallet funding payment
            await _handleWalletFundingPayment(currentUser);
          } else {
            // Handle package subscription payment
            await _handlePackageSubscriptionPayment(currentUser);
          }
        }
      }
    } catch (e) {
      print('❌ PaystackPaymentScreen: Error handling payment success: $e');
      print('❌ PaystackPaymentScreen: Error details: ${e.toString()}');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment processed but there was an error: ${e.toString()}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    // Send enhanced payment success notification with WhatsApp functionality
    if (widget.userId != null) {
      // Get service name for notification
      String? serviceName;
      if (widget.cartItems.isNotEmpty) {
        serviceName = widget.cartItems.first.name;
      } else if (widget.paymentType == 'package_subscription') {
        serviceName = 'Package Subscription';
      } else if (widget.paymentType == 'wallet_funding') {
        serviceName = 'Wallet Funding';
      }

      print('📧 PaystackPaymentScreen: About to send notification...');
      try {
        await NotificationService.sendPaymentSuccessWithWhatsApp(
          userId: widget.userId!,
          transactionId:
              _reference ?? 'PAYSTACK-${DateTime.now().millisecondsSinceEpoch}',
          amount: widget.totalAmount,
          orderId:
              orderNumber ??
              orderId, // Use order number if available, fallback to orderId
          serviceName: serviceName,
        );
        print('📧 PaystackPaymentScreen: Notification sent successfully');
      } catch (e) {
        print('❌ PaystackPaymentScreen: Error sending notification: $e');
        print('❌ PaystackPaymentScreen: Error details: ${e.toString()}');
      }

      // Send payment confirmation email
      print('📧 PaystackPaymentScreen: Reached email code block');
      try {
        final currentUser = auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.email != null) {
          print(
            '📧 PaystackPaymentScreen: About to call MailerSend service...',
          );
          print('📧 PaystackPaymentScreen: User email: ${currentUser.email}');
          print(
            '📧 PaystackPaymentScreen: User name: ${currentUser.displayName}',
          );
          print('📧 PaystackPaymentScreen: Transaction ID: $_reference');
          print('📧 PaystackPaymentScreen: Amount: ${widget.totalAmount}');
          print('📧 PaystackPaymentScreen: Service name: $serviceName');

          final result = await MailerSendService.sendPaymentConfirmation(
            toEmail: currentUser.email!,
            toName: currentUser.displayName ?? 'Customer',
            transactionId:
                _reference ??
                'PAYSTACK-${DateTime.now().millisecondsSinceEpoch}',
            amount: widget.totalAmount,
            serviceName: serviceName ?? 'Service Payment',
            orderNumber: orderNumber,
            paymentMethod: 'Paystack',
          );

          print(
            '📧 PaystackPaymentScreen: MailerSend result: ${result.success}',
          );
          print(
            '📧 PaystackPaymentScreen: MailerSend message: ${result.message}',
          );
          print('📧 Payment confirmation email sent successfully');
        } else {
          print('📧 PaystackPaymentScreen: No current user or email found');
        }
      } catch (e) {
        print(
          '📧 PaystackPaymentScreen: Error sending payment confirmation email: $e',
        );
        print('📧 PaystackPaymentScreen: Error details: ${e.toString()}');
      }

      // Process referral earnings
      await ReferralService.processReferralPurchase(
        referredUserId: widget.userId!,
        purchaseAmount: widget.totalAmount,
      );
    }

    // Create wallet transaction record
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('walletTransactions').add({
          'userId': currentUser.uid,
          'amount': widget.totalAmount,
          'type': 'credit',
          'description':
              'Payment received - ${widget.cartItems.isNotEmpty ? widget.cartItems.first.name : 'Service Payment'}',
          'transactionId':
              _reference ?? 'PAYSTACK-${DateTime.now().millisecondsSinceEpoch}',
          'status': 'completed',
          'balance': 0.0, // Will be updated by wallet service
          'createdAt': FieldValue.serverTimestamp(),
        });
        print(
          '✅ Wallet transaction created for payment: R${widget.totalAmount}',
        );
      }
    } catch (e) {
      print('❌ Error creating wallet transaction: $e');
    }

    // Clear pending payment since payment was successful
    await PendingPaymentService.clearPendingPayment();
    print('✅ Pending payment cleared after successful payment');

    // Clear the cart after successful payment
    if (widget.cartItems.isNotEmpty) {
      try {
        final currentUser = auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await CartService.clearCart(currentUser.uid);
          print('✅ Cart cleared after successful payment');
        }
      } catch (e) {
        print('❌ Error clearing cart after payment: $e');
      }
    }

    // Show success dialog - simplified approach
    print('🎉 Payment success - showing success dialog');
    _showSuccessDialog(_reference ?? 'Unknown', orderNumber);
  }

  /// Check if user is eligible for loyalty reward
  Future<void> _checkLoyaltyReward(String userId) async {
    try {
      final rewardResult =
          await LoyaltyRewardService.checkAndProcessLoyaltyReward(userId);

      if (rewardResult['success']) {
        print('🎉 Loyalty reward processed: ${rewardResult['rewardService']}');

        // Show success message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Congratulations! You\'ve earned a free ${rewardResult['rewardService']} for reaching 2000 loyalty points!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking loyalty reward: $e');
    }
  }

  /// Handle package subscription payment success
  Future<void> _handlePackageSubscriptionPayment(auth.User currentUser) async {
    try {
      // print('=== HANDLING PACKAGE SUBSCRIPTION PAYMENT ===');

      // Find the user's pending subscription
      final subscriptionQuery = await FirebaseFirestore.instance
          .collection('delayed_subscriptions')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending_activation')
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) {
        // print('No pending subscription found for user');
        return;
      }

      final subscriptionDoc = subscriptionQuery.docs.first;
      final subscriptionData = subscriptionDoc.data();
      final packageName = subscriptionData['packageName'] as String?;
      final setupFee = subscriptionData['setupFee'] as double? ?? 0.0;

      // print('Found pending subscription: $packageName, Setup Fee: R$setupFee');

      // Update subscription status to active
      await subscriptionDoc.reference.update({
        'status': 'active',
        'activatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'setupFeePaid': true,
        'setupFeePaymentDate': FieldValue.serverTimestamp(),
      });

      // print('Package subscription activated successfully');

      // Send notification to user
      await NotificationService.sendNotificationToUser(
        userId: currentUser.uid,
        title: 'Package Activated! 🎉',
        body: 'Your $packageName package has been activated successfully!',
        type: 'package_activated',
        action: 'package_activated',
      );

      // Create transaction record
      await FirebaseService.createTransaction(
        userId: currentUser.uid,
        type: 'debit',
        amount: setupFee,
        description: 'Setup fee payment for $packageName package',
        orderId: subscriptionDoc.id,
      );

      // print('Package subscription payment handling completed');
    } catch (e) {
      // print('Error handling package subscription payment: $e');
    }
  }

  /// Show saved cards option for payment
  Future<void> _showSavedCardsOption() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get user's saved cards
    final savedCards = await _customerService.getSavedCards(currentUser.uid);

    if (savedCards.isEmpty) {
      // No saved cards - show option to add one
      final shouldAddCard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'No Saved Cards',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'You don\'t have any saved cards. Would you like to add one for faster checkout?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Add Card',
                style: TextStyle(color: Color(0xFF8B0000)),
              ),
            ),
          ],
        ),
      );

      if (shouldAddCard == true) {
        // Navigate to add card screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ManageSavedCardsScreen(),
          ),
        );
      }
      return;
    }

    // Show saved cards selection
    final selectedCard = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Select Saved Card',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: savedCards.length,
            itemBuilder: (context, index) {
              final card = savedCards[index];
              final isDefault = card['isDefault'] ?? false;
              final cardType = card['cardType'] ?? 'Unknown';
              final lastFour = card['lastFourDigits'] ?? '****';
              final expiryDate = card['expiryDate'] ?? '**/**';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.grey[800],
                child: ListTile(
                  leading: Icon(
                    Icons.credit_card,
                    color: _getCardTypeColor(cardType),
                  ),
                  title: Text(
                    '$cardType •••• $lastFour',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Expires $expiryDate${isDefault ? ' • Default' : ''}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: isDefault
                      ? const Icon(Icons.star, color: Colors.amber, size: 20)
                      : null,
                  onTap: () => Navigator.pop(context, card),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageSavedCardsScreen(),
                ),
              );
            },
            child: const Text(
              'Manage Cards',
              style: TextStyle(color: Color(0xFF8B0000)),
            ),
          ),
        ],
      ),
    );

    if (selectedCard != null) {
      // Use selected card for payment
      await _processPaymentWithSavedCard(selectedCard);
    }
  }

  /// Process payment using saved card
  Future<void> _processPaymentWithSavedCard(Map<String, dynamic> card) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF8B0000)),
              SizedBox(width: 16),
              Text(
                'Processing payment with saved card...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Get card details
      final cardDetails = await _customerService.getCardDetails(card['id']);
      if (cardDetails == null) {
        Navigator.pop(context); // Close loading
        _showErrorDialog('Failed to retrieve card details');
        return;
      }

      // Initialize Paystack customer if needed
      await _customerService.initializeCustomer();

      // Generate reference and convert amount
      _reference = PaystackService.instance.generateReference();
      final amountInKobo = PaystackService.instance.convertToKobo(
        widget.totalAmount,
      );

      // Process payment with Paystack
      final response = await PaystackService.instance.processPayment(
        email: widget.userEmail,
        amount: amountInKobo,
        reference: _reference!,
        phoneNumber: widget.userPhone,
        firstName: widget.userName?.split(' ').first,
        lastName: (widget.userName?.split(' ').length ?? 0) > 1
            ? widget.userName!.split(' ').last
            : null,
      );

      Navigator.pop(context); // Close loading

      if (response.status) {
        // Payment initialized successfully
        setState(() {
          _authorizationUrl = response.authorizationUrl;
          // Only show WebView on non-web platforms
          _showWebView = !kIsWeb;
        });

        // Load the payment URL in WebView
        print('🌐 Platform check (wallet funding): kIsWeb = $kIsWeb');
        if (!kIsWeb) {
          print('📱 Mobile platform (wallet funding) - loading WebView');
          _webViewController.loadRequest(Uri.parse(_authorizationUrl!));
        } else {
          print(
            '🌐 Web platform detected (wallet funding) - opening payment in new tab',
          );
          print('🌐 Authorization URL: $_authorizationUrl');
          _handleWebPayment();
        }
      } else {
        _showErrorDialog(response.message);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorDialog('Payment with saved card failed: ${e.toString()}');
    }
  }

  /// Get card type color
  Color _getCardTypeColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'american express':
        return Colors.green;
      case 'discover':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Handle wallet funding payment success
  Future<void> _handleWalletFundingPayment(auth.User currentUser) async {
    try {
      print('=== HANDLING WALLET FUNDING PAYMENT ===');
      print('User ID: ${currentUser.uid}');
      print('Amount: R${widget.totalAmount.toStringAsFixed(2)}');
      print('Payment Type: ${widget.paymentType}');
      print('Reference: $_reference');

      // Payment has already been verified in _verifyAndHandlePaymentSuccess
      // No need to verify again here to avoid double verification issues
      print('✅ Payment already verified - proceeding with wallet funding');

      // Use WalletService to add funds (this will update both users and wallets collections)
      print('Adding funds using WalletService...');
      final addFundsSuccess = await WalletService.addFunds(
        currentUser.uid,
        widget.totalAmount,
        'Wallet funding via Paystack - Reference: $_reference',
      );

      if (!addFundsSuccess) {
        print('❌ Failed to add funds to wallet');
        throw Exception('Failed to add funds to wallet');
      }

      print('✅ Wallet funding completed successfully');

      // Send wallet funding notification
      await NotificationService.sendWalletFundingNotification(
        userId: currentUser.uid,
        amount: widget.totalAmount,
      );

      print('✅ Wallet funding notification sent');
    } catch (e) {
      print('❌ Error handling wallet funding payment: $e');
      rethrow; // Re-throw to be handled by the calling method
    }
  }

  void _showSuccessDialog(String reference, String? orderNumber) async {
    print('🎉 Showing success dialog for payment: $reference');

    try {
      // Create transaction record in Firebase (background task)
      _createTransactionRecord(reference);

      // Show immediate success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Ref: $reference'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Wait a moment then show simple success dialog
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Payment Successful!',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your payment has been processed successfully.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B0000).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Reference: $reference',
                          style: const TextStyle(
                            color: Color(0xFF8B0000),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Amount: R${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Close payment screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('❌ Error showing success dialog: $e');
      // Fallback: just show success message and close
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Ref: $reference'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Wait a moment then close
        await Future.delayed(const Duration(milliseconds: 1000));
        Navigator.of(context).pop(true);
      }
    }
  }

  // Background task to create transaction record
  void _createTransactionRecord(String reference) async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('transactions').add({
          'userId': currentUser.uid,
          'amount': widget.totalAmount,
          'transactionId': reference,
          'status': 'completed',
          'type': 'payment',
          'description': widget.cartItems.isNotEmpty
              ? 'Payment for ${widget.cartItems.first.name}'
              : 'Service Payment',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Transaction record created successfully');
      }
    } catch (e) {
      print('❌ Error creating transaction record: $e');
    }
  }

  void _showErrorDialog(String message) async {
    // Send payment failure notification
    if (widget.userId != null) {
      await NotificationService.sendNotificationToUser(
        userId: widget.userId!,
        title: 'Payment Failed ❌',
        body:
            'Your payment of R${widget.totalAmount.toStringAsFixed(2)} failed. $message',
        type: 'payment',
        action: 'payment_failed',
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Payment'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isInitializing
          ? _buildLoadingScreen()
          : _showWebView
          ? _buildWebViewScreen()
          : _paymentOpened
          ? _buildPaymentOpenedScreen()
          : _buildErrorScreen(),
    );
  }

  Widget _buildWebViewScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF2A2A2A),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Paystack Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Payment completion is handled automatically by Paystack verification
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: _webViewController)),
      ],
    );
  }

  Widget _buildWebPaymentScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20), // Add top spacing
          // Payment icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.payment,
              size: 64,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Ready to Pay',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Instructions
          const Text(
            'Click the button below to open the Paystack payment page in a new tab.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Warning about popup blockers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'If the payment window didn\'t open, check your popup blocker settings.',
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Open payment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleWebPayment(),
              icon: const Icon(Icons.payment),
              label: const Text('Open Payment Page'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Back button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(
            height: 40,
          ), // Add bottom spacing for better accessibility
        ],
      ),
    );
  }

  Widget _buildPaymentOpenedScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20), // Add top spacing
          // Payment icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.payment,
              size: 64,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Payment Window Opened',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Payment details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B0000).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Amount: R${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Payment Type: ${widget.paymentType}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 Instructions:',
                  style: TextStyle(
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Complete your payment in the popup window\n'
                  '2. Return to this page after payment\n'
                  '3. We will automatically verify your payment via webhook',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Warning about popup blockers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'If the payment window didn\'t open, check your popup blocker settings.',
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Webhook status indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B0000).withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8B0000),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Waiting for payment verification via webhook...',
                    style: TextStyle(
                      color: Color(0xFF8B0000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reopen payment button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                if (_authorizationUrl != null) {
                  try {
                    await launchUrl(
                      Uri.parse(_authorizationUrl!),
                      mode: LaunchMode.platformDefault,
                      webOnlyWindowName: '_blank',
                    );
                  } catch (e) {
                    print('Error reopening payment: $e');
                  }
                }
              },
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label: const Text(
                'Reopen Payment',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(
            height: 40,
          ), // Add bottom spacing for better accessibility
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
          ),
          SizedBox(height: 20),
          Text(
            'Initializing Payment...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we set up your payment',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated error icon with glow effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.payment_outlined,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),

              // Error title with better typography
              const Text(
                'Payment Setup Issue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Error description with better styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'We\'re having trouble connecting to our payment processor. This usually resolves quickly.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons with better design
              Column(
                children: [
                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Retry payment initialization
                        _initializePayment();
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(
                          0xFF8B0000,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saved Cards option
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSavedCardsOption(),
                      icon: const Icon(Icons.credit_card, size: 20),
                      label: const Text(
                        'Use Saved Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B0000),
                        side: const BorderSide(color: Color(0xFF8B0000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Go back button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white70.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Help text
              Text(
                'Need help? Contact our support team',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
