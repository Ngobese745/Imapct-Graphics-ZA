import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'paystack_service.dart';

class PendingPaymentService {
  static const String _pendingPaymentKey = 'pending_payment_reference';
  static const String _pendingPaymentDataKey = 'pending_payment_data';

  /// Store payment reference before opening Paystack
  static Future<void> storePendingPayment({
    required String reference,
    required String authorizationUrl,
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
    required double paystackAmount,
    required double walletAmount,
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store payment reference
      await prefs.setString(_pendingPaymentKey, reference);

      // Store payment data
      final paymentData = {
        'reference': reference,
        'authorizationUrl': authorizationUrl,
        'cartItems': cartItems,
        'totalAmount': totalAmount,
        'paystackAmount': paystackAmount,
        'walletAmount': walletAmount,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'userPhone': userPhone,
        'customerName': userName, // For webhook processing
        'customerEmail': userEmail, // For webhook processing
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_pendingPaymentDataKey, paymentData.toString());

      // Also store in Firestore for cross-device access
      await FirebaseFirestore.instance
          .collection('pending_payments')
          .doc(reference)
          .set({
            ...paymentData,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ Pending payment stored: $reference');
    } catch (e) {
      print('❌ Error storing pending payment: $e');
    }
  }

  /// Get pending payment data (for payment screen to resume verification)
  static Future<Map<String, dynamic>?> getPendingPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingReference = prefs.getString(_pendingPaymentKey);

      if (pendingReference != null && pendingReference.isNotEmpty) {
        // Get payment data from Firestore
        final paymentDoc = await FirebaseFirestore.instance
            .collection('pending_payments')
            .doc(pendingReference)
            .get();

        if (paymentDoc.exists) {
          return paymentDoc.data();
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting pending payment: $e');
      return null;
    }
  }

  /// Check for pending payments on app start
  static Future<void> checkPendingPayments() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      print('🔍 Checking for pending payments...');

      // Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final pendingReference = prefs.getString(_pendingPaymentKey);

      if (pendingReference != null && pendingReference.isNotEmpty) {
        print('📋 Found pending payment reference: $pendingReference');

        // Check payment age from Firestore
        final paymentDoc = await FirebaseFirestore.instance
            .collection('pending_payments')
            .doc(pendingReference)
            .get();

        if (!paymentDoc.exists) {
          print('⚠️ Pending payment not found in Firestore, clearing...');
          await clearPendingPayment();
          return;
        }

        final paymentData = paymentDoc.data();
        final createdAt = paymentData?['createdAt'] as Timestamp?;

        // Only process recent payments (within 1 hour)
        if (createdAt != null) {
          final age = DateTime.now().difference(createdAt.toDate());
          if (age.inHours > 1) {
            print(
              '⏰ Pending payment expired (${age.inHours} hours old), clearing...',
            );
            await clearPendingPayment();
            await paymentDoc.reference.delete();
            return;
          }
        }

        print('🔄 Attempting to verify pending payment...');

        // Send notification to user that payment is being verified
        await NotificationService.sendNotificationToUser(
          userId: currentUser.uid,
          title: 'Verifying Payment... ⏳',
          body:
              'We detected a pending payment. Verifying with payment provider...',
          type: 'payment_verifying',
          action: 'payment_verification',
        );

        // Try multiple times with delays to account for Paystack processing time
        bool isVerified = false;
        String? transactionStatus;
        for (int attempt = 1; attempt <= 5; attempt++) {
          print('   Verification attempt $attempt/5...');

          final verificationResult = await PaystackService.instance
              .verifyPayment(pendingReference);

          isVerified =
              verificationResult['status'] == true &&
              verificationResult['data']['status'] == 'success';

          // Get the actual transaction status from Paystack
          transactionStatus = verificationResult['data']?['status'] as String?;

          if (isVerified) {
            print('✅ Pending payment verified on attempt $attempt');
            await _completePendingPayment(pendingReference);
            return;
          }

          // Wait before next attempt (exponential backoff)
          if (attempt < 5) {
            final waitTime = attempt * 2; // 2s, 4s, 6s, 8s
            print(
              '   ⏳ Payment not yet verified, waiting ${waitTime}s before retry...',
            );
            await Future.delayed(Duration(seconds: waitTime));
          }
        }

        // After 5 attempts, check if payment is actually failed or ongoing
        if (transactionStatus == 'ongoing' ||
            transactionStatus == 'failed' ||
            transactionStatus == 'abandoned') {
          print(
            '⚠️ Payment status is "$transactionStatus" after 5 attempts - clearing failed payment',
          );
          await clearPendingPayment();
          await paymentDoc.reference.delete();

          // Send failure notification
          await NotificationService.sendNotificationToUser(
            userId: currentUser.uid,
            title: 'Payment Incomplete ⚠️',
            body:
                'Your payment was not completed. Please try again if you wish to proceed.',
            type: 'payment_failed',
            action: 'payment_failed',
          );
          return;
        }

        print(
          '⚠️ Payment still pending after 5 attempts - keeping for later verification',
        );
        // Don't clear it - let webhook or manual verification handle it
      }

      // Also check Firestore for any pending payments for this user
      final pendingPayments = await FirebaseFirestore.instance
          .collection('pending_payments')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in pendingPayments.docs) {
        final paymentData = doc.data();
        final reference = paymentData['reference'] as String;

        // Check if payment is older than 1 hour
        final createdAt = paymentData['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final age = DateTime.now().difference(createdAt.toDate());
          if (age.inHours > 1) {
            // Clear old pending payments
            await doc.reference.delete();
            continue;
          }
        }

        // Verify payment
        final verificationResult = await PaystackService.instance.verifyPayment(
          reference,
        );
        final isVerified =
            verificationResult['status'] == true &&
            verificationResult['data']['status'] == 'success';

        if (isVerified) {
          print('✅ Firestore pending payment verified: $reference');
          await _completePendingPayment(reference);
        }
      }
    } catch (e) {
      print('❌ Error checking pending payments: $e');
    }
  }

  /// Complete a pending payment
  static Future<void> _completePendingPayment(String reference) async {
    try {
      print('🔄 Completing pending payment: $reference');

      // Get payment data from Firestore
      final paymentDoc = await FirebaseFirestore.instance
          .collection('pending_payments')
          .doc(reference)
          .get();

      if (!paymentDoc.exists) {
        print('❌ Payment data not found: $reference');
        return;
      }

      final paymentData = paymentDoc.data();
      if (paymentData == null) {
        print('⚠️ Payment data is null, skipping payment completion');
        return;
      }

      // Check if payment was already completed
      if (paymentData['status'] == 'completed') {
        print('⚠️ Payment already completed: $reference');
        await clearPendingPayment();
        return;
      }

      // Get user profile data
      final userProfile = AuthService.instance?.userProfile;
      final userName = userProfile?['name'] as String?;
      final userEmail = userProfile?['email'] as String?;

      // Create order
      final cartItems = List<Map<String, dynamic>>.from(
        paymentData['cartItems'] ?? [],
      );

      if (cartItems.isNotEmpty) {
        final cartItem = cartItems.first;

        final orderData = {
          'userId': paymentData['userId'],
          'customerName': userName ?? 'Unknown Customer',
          'customerEmail': userEmail ?? paymentData['userEmail'],
          'serviceId': cartItem['id'],
          'serviceName': cartItem['name'],
          'title': cartItem['name'],
          'serviceDescription': cartItem['description'] ?? '',
          'projectDescription': cartItem['description'] ?? '',
          'originalPrice': cartItem['price'],
          'finalPrice': paymentData['totalAmount'],
          'budget': cartItem['budget'],
          'status': 'completed',
          'paymentStatus': 'completed',
          'paymentReference': reference,
          'paidAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final orderId = await FirebaseService.createOrder(orderData);
        print('✅ Order created for pending payment: $orderId');

        // Send notifications
        try {
          await NotificationService.sendNewOrderNotificationToAdmin(
            orderId: orderId,
            customerName: userName ?? 'Customer',
            serviceName: cartItem['name'],
            amount: paymentData['totalAmount'],
          );
        } catch (e) {
          print('⚠️ Error sending admin notification: $e');
        }

        try {
          await NotificationService.sendPaymentSuccessWithWhatsApp(
            userId: paymentData['userId'],
            transactionId: reference,
            amount: paymentData['totalAmount'],
            orderId: orderId,
            serviceName: cartItem['name'],
          );
        } catch (e) {
          print('⚠️ Error sending payment success notification: $e');
        }
      } else {
        print('⚠️ No cart items found, checking for wallet funding...');
        // Handle wallet funding if no cart items
        final totalAmount = paymentData['totalAmount'] as double?;
        final userId = paymentData['userId'] as String?;

        if (totalAmount != null && userId != null) {
          print('💰 Processing wallet funding for $userId: R$totalAmount');
          // This will be handled by WalletService
        }
      }

      // Mark payment as completed
      await paymentDoc.reference.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Clear local pending payment
      await clearPendingPayment();

      print('✅ Pending payment completed successfully: $reference');
    } catch (e) {
      print('❌ Error completing pending payment: $e');
      print('❌ Error details: ${e.toString()}');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Clear pending payment data
  static Future<void> clearPendingPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingPaymentKey);
      await prefs.remove(_pendingPaymentDataKey);
      print('✅ Pending payment data cleared');
    } catch (e) {
      print('❌ Error clearing pending payment: $e');
    }
  }
}
