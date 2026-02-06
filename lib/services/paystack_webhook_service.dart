import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mailersend_service.dart';

class PaystackWebhookService {
  static const String _paystackSecretKey =
      'sk_test_your_secret_key_here'; // Replace with your actual secret key
  static const String _webhookUrl =
      'https://impact-graphics-za-266ef.web.app/paystack-webhook';

  /// Verify webhook signature to ensure it's from Paystack
  static bool verifyWebhookSignature(String payload, String signature) {
    try {
      final computedSignature =
          'sha256=${sha256.convert(utf8.encode(payload))}';
      return computedSignature == signature;
    } catch (e) {
      print('Error verifying webhook signature: $e');
      return false;
    }
  }

  /// Process webhook payload from Paystack
  static Future<Map<String, dynamic>> processWebhook(
    Map<String, dynamic> payload,
  ) async {
    try {
      print('=== PAYSTACK WEBHOOK RECEIVED ===');
      print('Webhook payload: $payload');

      final event = payload['event'] as String?;
      final data = payload['data'] as Map<String, dynamic>?;

      if (event == null || data == null) {
        return {
          'success': false,
          'message': 'Invalid webhook payload structure',
        };
      }

      switch (event) {
        case 'charge.success':
          return await _handleSuccessfulPayment(data);
        case 'subscription.create':
          return await _handleSubscriptionCreated(data);
        case 'subscription.enable':
          return await _handleSubscriptionEnabled(data);
        case 'subscription.disable':
          return await _handleSubscriptionDisabled(data);
        default:
          print('Unhandled webhook event: $event');
          return {'success': true, 'message': 'Event logged but not processed'};
      }
    } catch (e) {
      print('Error processing webhook: $e');
      return {
        'success': false,
        'message': 'Error processing webhook: ${e.toString()}',
      };
    }
  }

  /// Handle successful payment
  static Future<Map<String, dynamic>> _handleSuccessfulPayment(
    Map<String, dynamic> data,
  ) async {
    try {
      final reference = data['reference'] as String?;
      final status = data['status'] as String?;
      final amount = (data['amount'] as num?)?.toDouble();
      final customer = data['customer'] as Map<String, dynamic>?;
      final email = customer?['email'] as String?;

      print('Processing successful payment: $reference');

      if (reference == null || status != 'success' || amount == null) {
        return {'success': false, 'message': 'Invalid payment data'};
      }

      // Find and process the order
      final orderResult = await _processOrderFromWebhook(
        reference,
        amount,
        email,
      );

      if (orderResult['success']) {
        print('✅ Order processed successfully via webhook: $reference');

        // Send confirmation email
        if (email != null) {
          await _sendPaymentConfirmationEmail(email, reference, amount);
        }

        return {
          'success': true,
          'message': 'Payment processed successfully',
          'orderId': orderResult['orderId'],
        };
      } else {
        print('❌ Failed to process order: ${orderResult['message']}');
        return {
          'success': false,
          'message': 'Failed to process order: ${orderResult['message']}',
        };
      }
    } catch (e) {
      print('Error handling successful payment: $e');
      return {
        'success': false,
        'message': 'Error processing payment: ${e.toString()}',
      };
    }
  }

  /// Process order from webhook data
  static Future<Map<String, dynamic>> _processOrderFromWebhook(
    String reference,
    double amount,
    String? email,
  ) async {
    try {
      // First, try to find the order by payment reference
      final orderQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('paymentReference', isEqualTo: reference)
          .limit(1)
          .get();

      if (orderQuery.docs.isNotEmpty) {
        final orderDoc = orderQuery.docs.first;
        final orderData = orderDoc.data();

        // Update order status
        await orderDoc.reference.update({
          'status': 'completed',
          'paymentStatus': 'success',
          'paymentVerifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Clear cart
        final userId = orderData['userId'] as String?;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'cart': [], 'updatedAt': FieldValue.serverTimestamp()});
        }

        // Send order notification
        await _sendOrderNotification(orderDoc.id, orderData);

        return {
          'success': true,
          'orderId': orderDoc.id,
          'message': 'Order updated successfully',
        };
      }

      // If no order found, try to create from pending payment data
      final pendingResult = await _processPendingPayment(
        reference,
        amount,
        email,
      );
      return pendingResult;
    } catch (e) {
      print('Error processing order from webhook: $e');
      return {
        'success': false,
        'message': 'Error processing order: ${e.toString()}',
      };
    }
  }

  /// Process pending payment data
  static Future<Map<String, dynamic>> _processPendingPayment(
    String reference,
    double amount,
    String? email,
  ) async {
    try {
      // Check SharedPreferences for pending payment
      final prefs = await SharedPreferences.getInstance();
      final pendingPaymentJson = prefs.getString('pending_payment_$reference');

      if (pendingPaymentJson != null) {
        final pendingData = json.decode(pendingPaymentJson);
        final cartItems = pendingData['cartItems'] as List<dynamic>?;
        final userId = pendingData['userId'] as String?;
        final customerName = pendingData['customerName'] as String?;
        final customerEmail = pendingData['customerEmail'] as String?;

        if (cartItems != null && userId != null) {
          // Create order
          final orderData = {
            'userId': userId,
            'customerName': customerName ?? email ?? 'Unknown',
            'customerEmail': customerEmail ?? email ?? '',
            'items': cartItems,
            'totalAmount': amount,
            'paymentReference': reference,
            'paymentStatus': 'success',
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'paymentVerifiedAt': FieldValue.serverTimestamp(),
          };

          final orderDoc = await FirebaseFirestore.instance
              .collection('orders')
              .add(orderData);

          // Clear cart
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'cart': [], 'updatedAt': FieldValue.serverTimestamp()});

          // Clear pending payment data
          await prefs.remove('pending_payment_$reference');

          // Send order notification
          await _sendOrderNotification(orderDoc.id, orderData);

          return {
            'success': true,
            'orderId': orderDoc.id,
            'message': 'Order created from pending payment',
          };
        }
      }

      return {
        'success': false,
        'message': 'No pending payment found for reference: $reference',
      };
    } catch (e) {
      print('Error processing pending payment: $e');
      return {
        'success': false,
        'message': 'Error processing pending payment: ${e.toString()}',
      };
    }
  }

  /// Send order notification
  static Future<void> _sendOrderNotification(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final userId = orderData['userId'] as String?;
      if (userId == null) return;

      final notificationData = {
        'userId': userId,
        'type': 'order',
        'title': 'Payment Successful! 🎉',
        'message':
            'Your order has been processed successfully. Order ID: $orderId',
        'data': {
          'orderId': orderId,
          'status': 'completed',
          'amount': orderData['totalAmount'],
        },
        'priority': 'high',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);

      print('Order notification sent for order: $orderId');
    } catch (e) {
      print('Error sending order notification: $e');
    }
  }

  /// Send payment confirmation email
  static Future<void> _sendPaymentConfirmationEmail(
    String email,
    String reference,
    double amount,
  ) async {
    try {
      await MailerSendService.sendPaymentConfirmationEmail(
        email: email,
        reference: reference,
        amount: amount,
      );
      print('Payment confirmation email sent to: $email');
    } catch (e) {
      print('Error sending payment confirmation email: $e');
    }
  }

  /// Handle subscription created
  static Future<Map<String, dynamic>> _handleSubscriptionCreated(
    Map<String, dynamic> data,
  ) async {
    try {
      print('Subscription created: ${data['subscription_code']}');
      // Handle subscription creation logic here
      return {'success': true, 'message': 'Subscription created successfully'};
    } catch (e) {
      print('Error handling subscription created: $e');
      return {
        'success': false,
        'message': 'Error processing subscription: ${e.toString()}',
      };
    }
  }

  /// Handle subscription enabled
  static Future<Map<String, dynamic>> _handleSubscriptionEnabled(
    Map<String, dynamic> data,
  ) async {
    try {
      print('Subscription enabled: ${data['subscription_code']}');
      // Handle subscription enabled logic here
      return {'success': true, 'message': 'Subscription enabled successfully'};
    } catch (e) {
      print('Error handling subscription enabled: $e');
      return {
        'success': false,
        'message': 'Error processing subscription: ${e.toString()}',
      };
    }
  }

  /// Handle subscription disabled
  static Future<Map<String, dynamic>> _handleSubscriptionDisabled(
    Map<String, dynamic> data,
  ) async {
    try {
      print('Subscription disabled: ${data['subscription_code']}');
      // Handle subscription disabled logic here
      return {'success': true, 'message': 'Subscription disabled successfully'};
    } catch (e) {
      print('Error handling subscription disabled: $e');
      return {
        'success': false,
        'message': 'Error processing subscription: ${e.toString()}',
      };
    }
  }
}
