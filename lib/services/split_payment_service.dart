import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'mailersend_service.dart';

class SplitPaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Payment result model
  static const String _secretKey = 'sk_live_PLACEHOLDER';
  static const String _baseUrl = 'https://api.paystack.co';

  /// Process split payment: wallet first, then Paystack for remaining
  static Future<SplitPaymentResult> processSplitPayment({
    required double totalAmount,
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required List<dynamic> cartItems,
  }) async {
    try {
      print('=== SPLIT PAYMENT PROCESSING ===');
      print('Total Amount: R$totalAmount');
      print('User ID: $userId');

      // Get current wallet balance
      final walletBalance = await _getWalletBalance(userId);
      print('Current Wallet Balance: R$walletBalance');

      // Calculate payment split
      final walletAmount = walletBalance >= totalAmount
          ? totalAmount
          : walletBalance;
      final paystackAmount = totalAmount - walletAmount;

      print('Wallet Payment: R$walletAmount');
      print('Paystack Payment: R$paystackAmount');

      // Process wallet payment if needed
      if (walletAmount > 0) {
        await _processWalletPayment(userId, walletAmount, cartItems);
        print('Wallet payment processed successfully');
      }

      // Process Paystack payment if needed
      String? paystackReference;
      String? paystackAuthorizationUrl;

      if (paystackAmount > 0) {
        final paystackResult = await _processPaystackPayment(
          amount: paystackAmount,
          userEmail: userEmail,
          userName: userName,
          userPhone: userPhone,
        );

        paystackReference = paystackResult['reference'];
        paystackAuthorizationUrl = paystackResult['authorization_url'];
        print('Paystack payment initialized: $paystackReference');
      }

      return SplitPaymentResult(
        success: true,
        totalAmount: totalAmount,
        walletAmount: walletAmount,
        paystackAmount: paystackAmount,
        paystackReference: paystackReference,
        paystackAuthorizationUrl: paystackAuthorizationUrl,
        message: _getPaymentMessage(walletAmount, paystackAmount),
      );
    } catch (e) {
      print('Split payment error: $e');
      return SplitPaymentResult(
        success: false,
        totalAmount: totalAmount,
        walletAmount: 0,
        paystackAmount: 0,
        error: 'Payment processing failed: $e',
        message: 'Payment failed',
      );
    }
  }

  /// Get current wallet balance
  static Future<double> _getWalletBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return (userData['walletBalance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }

  /// Process wallet payment
  static Future<void> _processWalletPayment(
    String userId,
    double amount,
    List<dynamic> cartItems,
  ) async {
    try {
      // Deduct from wallet
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create wallet transaction record
      final transactionRef = await _firestore
          .collection('walletTransactions')
          .add({
            'userId': userId,
            'type': 'debit',
            'amount': amount,
            'description': 'Payment for ${cartItems.length} item(s)',
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
            'orderItems': cartItems
                .map(
                  (item) => {
                    'id': item.id,
                    'name': item.name,
                    'price': item.price,
                    'quantity': item.quantity,
                  },
                )
                .toList(),
          });

      print('Wallet payment completed: R$amount deducted');

      // Send payment confirmation email for cart payments
      try {
        print('📧 Cart Payment: Sending payment confirmation email...');
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userEmail = userData['email'] as String?;
          final userName = userData['name'] as String?;

          if (userEmail != null) {
            // Get service name from cart items
            final serviceName = cartItems.isNotEmpty
                ? cartItems.length > 1
                      ? '${cartItems.length} Services'
                      : cartItems.first.name
                : 'Service Payment';

            // Get order number from first cart item if available
            String? orderNumber;
            if (cartItems.isNotEmpty && cartItems.first.orderId != null) {
              try {
                final orderDoc = await _firestore
                    .collection('orders')
                    .doc(cartItems.first.orderId)
                    .get();
                if (orderDoc.exists) {
                  final orderData = orderDoc.data() as Map<String, dynamic>;
                  orderNumber = orderData['orderNumber']?.toString();
                  print('📧 Cart Payment: Order number fetched: $orderNumber');
                }
              } catch (e) {
                print('📧 Cart Payment: Error fetching order number: $e');
              }
            }

            await MailerSendService.sendPaymentConfirmation(
              toEmail: userEmail,
              toName: userName ?? 'Customer',
              transactionId: 'CART-${transactionRef.id}',
              amount: amount,
              serviceName: serviceName,
              orderNumber: orderNumber ?? 'N/A',
              paymentMethod: 'Wallet',
            );
            print('📧 ✅ Cart Payment: Email sent successfully');
          }
        }
      } catch (e) {
        print('📧 ❌ Cart Payment: Error sending email: $e');
        // Don't throw - email failure shouldn't fail the payment
      }
    } catch (e) {
      print('Error processing wallet payment: $e');
      throw Exception('Wallet payment failed: $e');
    }
  }

  /// Process Paystack payment
  static Future<Map<String, dynamic>> _processPaystackPayment({
    required double amount,
    required String userEmail,
    required String userName,
    required String userPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': userEmail,
          'amount': (amount * 100).round(), // Convert to kobo
          'currency': 'ZAR',
          'reference': 'SPLIT_${DateTime.now().millisecondsSinceEpoch}',
          'metadata': {
            'user_name': userName,
            'user_phone': userPhone,
            'payment_type': 'split_payment',
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return {
            'reference': data['data']['reference'],
            'authorization_url': data['data']['authorization_url'],
          };
        } else {
          throw Exception(data['message'] ?? 'Paystack payment failed');
        }
      } else {
        throw Exception('Paystack API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error processing Paystack payment: $e');
      throw Exception('Paystack payment failed: $e');
    }
  }

  /// Get payment message based on split
  static String _getPaymentMessage(double walletAmount, double paystackAmount) {
    if (walletAmount > 0 && paystackAmount > 0) {
      return 'Split payment: R${walletAmount.toStringAsFixed(2)} from wallet, R${paystackAmount.toStringAsFixed(2)} via Paystack';
    } else if (walletAmount > 0) {
      return 'Payment completed using wallet funds';
    } else {
      return 'Proceeding to Paystack payment';
    }
  }

  /// Verify Paystack payment completion
  static Future<bool> verifyPaystackPayment(String reference) async {
    try {
      print(
        'Split Payment Service - Verifying payment with reference: $reference',
      );
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      );

      print(
        'Split Payment Service - Verification response status: ${response.statusCode}',
      );
      print(
        'Split Payment Service - Verification response body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isSuccess =
            data['status'] == true && data['data']['status'] == 'success';
        print('Split Payment Service - Verification result: $isSuccess');
        return isSuccess;
      }
      print(
        'Split Payment Service - Verification failed with status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      print('Error verifying Paystack payment: $e');
      return false;
    }
  }

  /// Refund wallet payment if card payment fails
  static Future<bool> refundWalletPayment({
    required String userId,
    required double amount,
    required String reason,
    required List<dynamic> cartItems,
  }) async {
    try {
      print('=== SPLIT PAYMENT WALLET REFUND PROCESSING ===');
      print('User ID: $userId');
      print('Refund Amount: R$amount');
      print('Reason: $reason');

      // Add back to wallet immediately
      print(
        '💰 SPLIT PAYMENT: Processing split payment refund: Adding R$amount to wallet',
      );
      print('💰 SPLIT PAYMENT: User ID: $userId');
      print('💰 SPLIT PAYMENT: Reason: $reason');

      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ SPLIT PAYMENT: Users collection updated successfully');

      // Also update wallets collection for consistency
      await _firestore.collection('wallets').doc(userId).set({
        'balance': FieldValue.increment(amount),
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ SPLIT PAYMENT: Wallets collection updated successfully');

      // Create refund transaction record
      await _firestore.collection('walletTransactions').add({
        'userId': userId,
        'type': 'credit',
        'amount': amount,
        'description': 'Refund: $reason',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'refundReason': reason,
        'originalOrderItems': cartItems
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
              },
            )
            .toList(),
      });

      print('✅ Split payment refund completed successfully: R$amount refunded');
      return true;
    } catch (e) {
      print('❌ Error processing wallet refund: $e');
      return false;
    }
  }

  /// Process complete payment failure - refund wallet and clear cart
  static Future<void> handlePaymentFailure({
    required String userId,
    required double walletAmount,
    required String failureReason,
    required List<dynamic> cartItems,
  }) async {
    try {
      print('🚨🚨🚨 HANDLING PAYMENT FAILURE 🚨🚨🚨');
      print('=== HANDLING PAYMENT FAILURE ===');
      print('User ID: $userId');
      print('Wallet Amount to Refund: R$walletAmount');
      print('Failure Reason: $failureReason');
      print('🚨🚨🚨 PAYMENT FAILURE PROCESSING 🚨🚨🚨');

      // Refund wallet if amount was deducted
      if (walletAmount > 0) {
        final refundSuccess = await refundWalletPayment(
          userId: userId,
          amount: walletAmount,
          reason: failureReason,
          cartItems: cartItems,
        );

        if (refundSuccess) {
          print('Wallet refunded successfully');
        } else {
          print('Failed to refund wallet - manual intervention required');
        }
      }

      // Send failure notification
      await _sendPaymentFailureNotification(
        userId: userId,
        walletAmount: walletAmount,
        reason: failureReason,
      );
    } catch (e) {
      print('Error handling payment failure: $e');
    }
  }

  /// Send payment failure notification
  static Future<void> _sendPaymentFailureNotification({
    required String userId,
    required double walletAmount,
    required String reason,
  }) async {
    try {
      // This would need to be imported from notification service
      // For now, we'll just log it
      print('Payment failure notification should be sent to user: $userId');
      print('Amount refunded: R$walletAmount');
      print('Reason: $reason');
    } catch (e) {
      print('Error sending payment failure notification: $e');
    }
  }
}

class SplitPaymentResult {
  final bool success;
  final double totalAmount;
  final double walletAmount;
  final double paystackAmount;
  final String? paystackReference;
  final String? paystackAuthorizationUrl;
  final String? error;
  final String message;

  SplitPaymentResult({
    required this.success,
    required this.totalAmount,
    required this.walletAmount,
    required this.paystackAmount,
    this.paystackReference,
    this.paystackAuthorizationUrl,
    this.error,
    required this.message,
  });

  bool get isWalletOnly => paystackAmount == 0;
  bool get isPaystackOnly => walletAmount == 0;
  bool get isSplitPayment => walletAmount > 0 && paystackAmount > 0;
}
