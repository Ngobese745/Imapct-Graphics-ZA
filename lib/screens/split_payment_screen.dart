import 'dart:async';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main.dart'; // Import CartService from main.dart
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/firebase_service.dart';
import '../services/loyalty_reward_service.dart';
import '../services/mailersend_service.dart';
import '../services/notification_service.dart';
import '../services/pending_payment_service.dart';
import '../services/split_payment_service.dart';

class SplitPaymentScreen extends StatefulWidget {
  final String paystackAuthorizationUrl;
  final String paystackReference;
  final double paystackAmount;
  final double walletAmount;
  final double totalAmount;
  final String userId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final List<dynamic> cartItems;

  const SplitPaymentScreen({
    super.key,
    required this.paystackAuthorizationUrl,
    required this.paystackReference,
    required this.paystackAmount,
    required this.walletAmount,
    required this.totalAmount,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.cartItems,
  });

  @override
  State<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends State<SplitPaymentScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _paymentCompleted = false;
  bool _paymentOpened = false;
  Timer? _timeoutTimer;
  Timer? _webhookPollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startTimeoutTimer();
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

  @override
  void dispose() {
    print('🛑 Split Payment Screen - Disposing and cancelling timers');
    _timeoutTimer?.cancel();
    _webhookPollingTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    // Set a 10-minute timeout for payment completion
    _timeoutTimer = Timer(const Duration(minutes: 10), () async {
      if (!_paymentCompleted) {
        print('⏰ Split Payment - 10-minute timeout triggered');
        _handlePaymentFailure(
          'Payment timeout - no response from payment gateway',
        );
      }
    });

    // Remove auto-success detection timer - this was causing false success notifications
    // Timer(const Duration(seconds: 30), () {
    //   if (!_paymentCompleted) {
    //     // print('Split Payment - Auto-detecting success after 30 seconds');
    //     _handlePaymentSuccess();
    //   }
    // });
  }

  void _initializeWebView() {
    // Skip WebView initialization on web platforms
    if (kIsWeb) {
      print(
        '🌐 Split Payment - Skipping WebView initialization on web platform',
      );
      // Automatically open payment on web
      _handleWebPayment();
      return;
    }

    // Initialize WebViewController for mobile platforms only
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // print('Split Payment - Navigation request: ${request.url}');

            // Check for payment success URLs - be more strict to prevent false positives
            final url = request.url.toLowerCase();
            if (url.contains('paystack.com/success') ||
                url.contains('paystack.com/callback') ||
                url.contains('status=success') ||
                url.contains('status=completed')) {
              print('Split Payment - Success URL detected: ${request.url}');
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Inject JavaScript to detect payment success
            _injectSuccessDetection();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paystackAuthorizationUrl));
  }

  /// Handle web payment by opening Paystack in new tab/window
  Future<void> _handleWebPayment() async {
    try {
      print('🌐 Split Payment - Opening payment in new tab');
      print('🌐 Authorization URL: ${widget.paystackAuthorizationUrl}');

      // Store pending payment before opening Paystack
      await PendingPaymentService.storePendingPayment(
        reference: widget.paystackReference,
        authorizationUrl: widget.paystackAuthorizationUrl,
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
        paystackAmount: widget.paystackAmount,
        walletAmount: widget.walletAmount,
        userId: widget.userId,
        userEmail: widget.userEmail,
        userName: widget.userName,
        userPhone: widget.userPhone,
      );
      print('💾 Pending payment stored: ${widget.paystackReference}');

      final uri = Uri.parse(widget.paystackAuthorizationUrl);

      // Try to open Paystack payment
      bool launched = false;

      try {
        print('🌐 Attempting to open URL with platformDefault mode...');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
        print('✅ Paystack payment window opened: $launched');
      } catch (e) {
        print('⚠️ Popup mode failed: $e, trying external application mode');
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
          _isLoading = false;
        });
      }

      // Listen for payment success message from popup
      if (kIsWeb) {
        // Set up message listener for payment success from popup
        _setupPaymentMessageListener();

        // Start webhook polling for payment verification
        _startWebhookPolling();
      }
    } catch (e) {
      print('Error handling web payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open payment page: ${e.toString()}'),
            backgroundColor: const Color(0xFF8B0000),
          ),
        );
      }
    }
  }

  void _injectSuccessDetection() {
    // Disable aggressive JavaScript detection to prevent false positives
    // Only rely on URL detection and manual button for payment completion
    print('JavaScript success detection disabled to prevent false positives');
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
              '🎉 Split Payment - Received payment success message from popup',
            );
            print('🎉 Payment reference: ${data['reference']}');

            // Trigger immediate payment verification
            _handlePaymentSuccess();
          }
        }
      });
      print('✅ Split Payment - Message listener set up for payment success');
    }
  }

  /// Start webhook polling to check for payment completion
  void _startWebhookPolling() {
    print('🔄 Split Payment - Starting webhook polling...');
    _webhookPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkWebhookCompletion(timer);
    });
  }

  /// Check if webhook has completed the payment
  Future<void> _checkWebhookCompletion(Timer timer) async {
    try {
      if (_paymentCompleted) {
        timer.cancel();
        return;
      }

      print('🔍 Split Payment - Checking webhook completion...');

      // Check if transaction exists in Firestore with 'completed' status
      final transactionQuery = await FirebaseFirestore.instance
          .collection('transactions')
          .where('transactionId', isEqualTo: widget.paystackReference)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (transactionQuery.docs.isNotEmpty) {
        print('✅ Split Payment - Payment completed via webhook!');
        timer.cancel();

        if (mounted) {
          setState(() {
            _paymentOpened = false;
            _isLoading = false;
          });
        }

        await _handleWebhookSuccess();
      } else {
        print('⏳ Split Payment - Still waiting for webhook...');

        // Timeout after 5 minutes (150 ticks * 2 seconds = 300 seconds)
        if (timer.tick > 150) {
          print('⏰ Split Payment - Webhook timeout - stopping polling');
          timer.cancel();
          _showTimeoutMessage();
        }
      }
    } catch (e) {
      print('❌ Split Payment - Error checking webhook completion: $e');
    }
  }

  /// Handle successful webhook payment
  Future<void> _handleWebhookSuccess() async {
    try {
      print('🎉 Split Payment - Payment completed via webhook!');

      // Clear pending payment
      await PendingPaymentService.clearPendingPayment();

      // Refresh user profile to get updated wallet balance
      final authService = AuthService.instance;
      if (authService != null) {
        await authService.refreshUserProfile();
        print('✅ Split Payment - User profile refreshed after webhook payment');
      }

      // Clear wallet cache to force refresh
      try {
        final cacheService = CacheService();
        final currentUser = auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          cacheService.clearCache('wallet_${currentUser.uid}');
          cacheService.clearCache('transactions_${currentUser.uid}');
          print('✅ Split Payment - Wallet cache cleared after webhook payment');
        }
      } catch (e) {
        print('⚠️ Split Payment - Error clearing wallet cache: $e');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment successful! Ref: ${widget.paystackReference}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Wait a moment then close
        await Future.delayed(const Duration(milliseconds: 1000));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ Split Payment - Error handling webhook success: $e');
    }
  }

  /// Show timeout message when webhook doesn't complete
  void _showTimeoutMessage() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Processing'),
          content: const Text(
            'Your payment is being processed. You will receive a notification once it\'s completed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (_paymentCompleted) return;

    setState(() {
      _paymentCompleted = true;
    });

    // Cancel timers since payment completed
    _timeoutTimer?.cancel();
    _webhookPollingTimer?.cancel();

    try {
      // Verify Paystack payment
      print(
        'Split Payment - Verifying payment with reference: ${widget.paystackReference}',
      );
      final isVerified = await SplitPaymentService.verifyPaystackPayment(
        widget.paystackReference,
      );
      print('Split Payment - Verification result: $isVerified');

      // Only create order if payment is verified
      if (isVerified) {
        print('Split Payment - Payment verified successfully');

        String? orderId;
        try {
          final currentUser = auth.FirebaseAuth.instance.currentUser;
          if (currentUser != null && widget.cartItems.isNotEmpty) {
            final cartItem = widget.cartItems.first;

            // Get user profile data for proper customer name
            final userProfile = AuthService.instance?.userProfile;
            final userName = userProfile?['name'] as String?;
            final userEmail = userProfile?['email'] as String?;

            // Check if cart item has an existing orderId (from add to cart flow)
            if (cartItem.orderId != null && cartItem.orderId!.isNotEmpty) {
              // Update existing order instead of creating new one
              print('Updating existing order: ${cartItem.orderId}');
              orderId = cartItem.orderId;

              await FirebaseService.updateOrder(orderId!, {
                'status': 'completed', // Mark as completed/paid immediately
                'paymentStatus': 'completed',
                'transactionId':
                    'SPLIT-${DateTime.now().millisecondsSinceEpoch}',
                'paidAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('Existing order updated with payment status: $orderId');
            } else {
              // Create new order (for direct Pay Now flow)
              print('Creating new order for direct Pay Now flow');
              final orderData = {
                'userId': currentUser.uid,
                'customerName':
                    userName ?? currentUser.displayName ?? 'Unknown Customer',
                'customerEmail': userEmail ?? currentUser.email ?? 'No email',
                'serviceId': cartItem.id,
                'serviceName': cartItem.name,
                'title': cartItem.name, // Add title field for order display
                'serviceDescription': cartItem.description ?? '',
                'projectDescription': cartItem.description ?? '',
                'originalPrice': cartItem.price,
                'finalPrice': widget.totalAmount,
                'budget': cartItem.budget,
                'status': 'completed', // Mark as completed/paid immediately
                'paymentStatus': 'completed', // Payment is verified
                'transactionId':
                    'SPLIT-${DateTime.now().millisecondsSinceEpoch}',
                'paidAt': FieldValue.serverTimestamp(),
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              orderId = await FirebaseService.createOrder(orderData);
              print('New order created in Firestore with ID: $orderId');
            }

            // Clear cart
            await _clearCart();

            // Only send "new order" notification if we created a new order
            if (cartItem.orderId == null || cartItem.orderId!.isEmpty) {
              // Send notification to admin about new order
              await NotificationService.sendNewOrderNotificationToAdmin(
                orderId: orderId,
                customerName: currentUser.displayName ?? 'Customer',
                serviceName: cartItem.name,
                amount: widget.totalAmount,
              );
            } else {
              // Send payment completion notification for existing order
              await NotificationService.sendOrderStatusNotification(
                userId: currentUser.uid,
                orderId: orderId,
                status: 'payment_completed',
                serviceName: cartItem.name,
              );
            }

            // Create transaction for the order
            await FirebaseService.createTransaction(
              userId: currentUser.uid,
              type: 'debit',
              amount: widget.totalAmount,
              description: 'Payment for ${cartItem.name}',
              orderId: orderId,
              transactionId: 'SPLIT-${DateTime.now().millisecondsSinceEpoch}',
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

            // Create update notification for admin (only for new orders)
            if (cartItem.orderId == null || cartItem.orderId!.isEmpty) {
              await FirebaseService.createUpdate(
                title: 'New Order Created',
                message:
                    '${cartItem.name} order created with price: R${widget.totalAmount.toStringAsFixed(2)}',
                type: 'order_created',
                userId: currentUser.uid,
                orderId: orderId,
              );
            } else {
              await FirebaseService.createUpdate(
                title: 'Payment Completed',
                message:
                    'Payment completed for ${cartItem.name} order: R${widget.totalAmount.toStringAsFixed(2)}',
                type: 'payment_completed',
                userId: currentUser.uid,
                orderId: orderId,
              );
            }

            // Send success notification
            await NotificationService.sendPaymentNotification(
              userId: widget.userId,
              transactionId: widget.paystackReference,
              status: 'successful',
              amount: widget.totalAmount,
            );

            // Send payment confirmation email
            try {
              print('📧 Split Payment: Sending payment confirmation email...');
              final currentUser = auth.FirebaseAuth.instance.currentUser;
              if (currentUser != null && currentUser.email != null) {
                // Fetch the order number from the created order
                String? orderNumber;
                try {
                  final orderDoc = await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .get();
                  if (orderDoc.exists) {
                    final orderData = orderDoc.data() as Map<String, dynamic>;
                    orderNumber = orderData['orderNumber']?.toString();
                    print(
                      '📧 Split Payment: Order number fetched: $orderNumber',
                    );
                  }
                } catch (e) {
                  print('📧 Split Payment: Error fetching order number: $e');
                }

                await MailerSendService.sendPaymentConfirmation(
                  toEmail: currentUser.email!,
                  toName: currentUser.displayName ?? 'Customer',
                  transactionId: widget.paystackReference,
                  amount: widget.totalAmount,
                  serviceName: cartItem.name,
                  orderNumber: orderNumber ?? 'N/A',
                  paymentMethod: 'Paystack (Split Payment)',
                );
                print(
                  '📧 ✅ Split Payment: Payment confirmation email sent successfully',
                );
              }
            } catch (e) {
              print(
                '📧 ❌ Split Payment: Error sending payment confirmation email: $e',
              );
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

            // Show success dialog
            _showSuccessDialog();
          }
        } catch (e) {
          print('Error creating order: $e');
          // If order creation fails, still handle payment failure
          await _handlePaymentFailure(
            'Order creation failed: $e. Wallet amount will be refunded.',
          );
        }
      } else {
        // Payment verification failed - refund wallet and handle failure
        print('Split Payment - Payment verification failed, refunding wallet');
        await _handlePaymentFailure(
          'Card payment verification failed. Wallet amount will be refunded.',
        );
      }
    } catch (e) {
      print('Error handling payment success: $e');
      // Payment processing error - refund wallet
      await _handlePaymentFailure(
        'Payment processing error: $e. Wallet amount will be refunded.',
      );
    }
  }

  Future<void> _handlePaymentFailure(String reason) async {
    try {
      // Handle payment failure - refund wallet
      await SplitPaymentService.handlePaymentFailure(
        userId: widget.userId,
        walletAmount: widget.walletAmount,
        failureReason: reason,
        cartItems: widget.cartItems,
      );

      // Send failure notification
      await NotificationService.sendNotificationToUser(
        userId: widget.userId,
        title: 'Payment Failed - Refund Processed',
        body:
            'Your card payment failed. R${widget.walletAmount.toStringAsFixed(2)} has been refunded to your wallet.',
        type: 'payment',
        action: 'payment_failed',
      );

      // Show error dialog with refund info
      _showRefundDialog(reason);
    } catch (e) {
      // print('Error handling payment failure: $e');
      _showErrorDialog('Payment failed and refund processing error: $e');
    }
  }

  Future<void> _clearCart() async {
    try {
      for (final item in widget.cartItems) {
        await FirebaseFirestore.instance
            .collection('carts')
            .doc(widget.userId)
            .collection('items')
            .doc(item.id)
            .delete();
      }
      // print('Cart cleared successfully');
    } catch (e) {
      // print('Error clearing cart: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment Successful!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your payment has been processed successfully.',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (widget.walletAmount > 0) ...[
                Text(
                  'Wallet Payment: R${widget.walletAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
              if (widget.paystackAmount > 0) ...[
                Text(
                  'Card Payment: R${widget.paystackAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Total: R${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(
                  context,
                ).pop(true); // Return to main screen with success
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showRefundDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, color: Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment Failed - Refunded',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your card payment failed, but we\'ve processed a refund for you.',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (widget.walletAmount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Refund Details',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount Refunded: R${widget.walletAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Reason: $reason',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'You can try the payment again or contact support if you need assistance.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(false); // Return to main screen
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Exit Payment?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to exit the payment process?',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (widget.walletAmount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Important',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'R${widget.walletAmount.toStringAsFixed(2)} has already been deducted from your wallet. If you exit now, this amount will be refunded automatically.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Continue Payment'),
            ),
            TextButton(
              onPressed: () async {
                print(
                  '🛑 Split Payment Screen - User exited payment process, cancelling timeout timer',
                );
                _timeoutTimer?.cancel();
                Navigator.of(context).pop(); // Close dialog
                // Handle payment failure and refund
                await _handlePaymentFailure('User exited payment process');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Exit & Refund'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Payment Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebPaymentScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  if (widget.walletAmount > 0) ...[
                    Text(
                      'Wallet: R${widget.walletAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Card Payment: R${widget.paystackAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF8B0000),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: R${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                    '2. Payment will be verified automatically via webhook\n'
                    '3. You will be notified when payment is successful',
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

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      try {
                        await launchUrl(
                          Uri.parse(widget.paystackAuthorizationUrl),
                          mode: LaunchMode.platformDefault,
                          webOnlyWindowName: '_blank',
                        );
                      } catch (e) {
                        print('Error reopening payment: $e');
                      }
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    label: const Text(
                      'Reopen Payment',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B0000).withOpacity(0.3),
                      ),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF8B0000),
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Waiting for webhook verification...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Complete Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print(
              '🛑 Split Payment Screen - User pressed back button, cancelling timers',
            );
            _timeoutTimer?.cancel();
            _webhookPollingTimer?.cancel();
            _showExitConfirmationDialog();
          },
        ),
      ),
      body: Column(
        children: [
          // Payment summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              border: Border(
                bottom: BorderSide(color: Color(0xFF333333), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.walletAmount > 0) ...[
                  Text(
                    'Wallet: R${widget.walletAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
                Text(
                  'Card Payment: R${widget.paystackAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: R${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // WebView or Web Payment Screen
          Expanded(
            child: kIsWeb
                ? _buildWebPaymentScreen()
                : Stack(
                    children: [
                      WebViewWidget(controller: _webViewController),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B0000),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
