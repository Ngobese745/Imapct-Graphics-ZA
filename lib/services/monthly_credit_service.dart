import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyCreditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Credit amounts for each package
  static const Map<String, double> _creditAmounts = {
    'Starter': 750.0,
    'Growth': 1500.0,
    'Premium': 2500.0,
  };

  /// Process monthly wallet credit for successful subscription payment
  static Future<Map<String, dynamic>> processMonthlyCredit({
    required String userId,
    required String packageName,
    required String transactionReference,
    required double paymentAmount,
  }) async {
    try {
      // print('=== PROCESSING MONTHLY WALLET CREDIT ===');
      // print('User ID: $userId');
      // print('Package: $packageName');
      // print('Transaction Reference: $transactionReference');
      // print('Payment Amount: R${paymentAmount.toStringAsFixed(2)}');

      // Get credit amount for the package
      final creditAmount = _creditAmounts[packageName] ?? 0.0;

      if (creditAmount <= 0) {
        return {
          'success': false,
          'message': 'No credit amount defined for package: $packageName',
        };
      }

      // print('Credit Amount: R${creditAmount.toStringAsFixed(2)}');

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found'};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();
      final newBalance = currentBalance + creditAmount;

      // Update wallet balance
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print(
      //        'Wallet balance updated: R${currentBalance.toStringAsFixed(2)} -> R${newBalance.toStringAsFixed(2)}',
      //      );

      // Create transaction record
      final transactionData = {
        'userId': userId,
        'type': 'monthly_credit',
        'amount': creditAmount,
        'description': 'Monthly credit for $packageName subscription',
        'packageName': packageName,
        'transactionReference': transactionReference,
        'paymentAmount': paymentAmount,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final transactionRef = await _firestore
          .collection('wallet_transactions')
          .add(transactionData);

      // print('Transaction record created: ${transactionRef.id}');

      // Send notification to user
      await _sendCreditNotification(userId, packageName, creditAmount);

      return {
        'success': true,
        'message': 'Monthly credit processed successfully',
        'creditAmount': creditAmount,
        'newBalance': newBalance,
        'transactionId': transactionRef.id,
      };
    } catch (e) {
      // print('Error processing monthly credit: $e');
      return {
        'success': false,
        'message': 'Failed to process monthly credit: ${e.toString()}',
      };
    }
  }

  /// Send notification to user about monthly credit
  static Future<void> _sendCreditNotification(
    String userId,
    String packageName,
    double creditAmount,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Monthly Credit Added! 💰',
        'message':
            'R${creditAmount.toStringAsFixed(2)} has been credited to your wallet for your $packageName subscription.',
        'type': 'wallet_credit',
        'action': 'monthly_credit',
        'amount': creditAmount,
        'packageName': packageName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // print('Credit notification sent to user: $userId');
    } catch (e) {
      // print('Error sending credit notification: $e');
    }
  }

  /// Get credit amount for a package
  static double getCreditAmount(String packageName) {
    return _creditAmounts[packageName] ?? 0.0;
  }

  /// Get all available credit amounts
  static Map<String, double> getAllCreditAmounts() {
    return Map.from(_creditAmounts);
  }

  /// Process webhook from Paystack for successful subscription payment
  static Future<Map<String, dynamic>> processPaystackWebhook(
    Map<String, dynamic> webhookData,
  ) async {
    try {
      // print('=== PROCESSING PAYSTACK WEBHOOK ===');
      // print('Webhook data: $webhookData');

      // Extract webhook data
      final event = webhookData['event'] as String?;
      final data = webhookData['data'] as Map<String, dynamic>?;

      if (event != 'subscription.charge.success' || data == null) {
        return {
          'success': false,
          'message': 'Not a subscription charge success event',
        };
      }

      // Extract subscription and customer data
      final subscription = data['subscription'] as Map<String, dynamic>?;
      final customer = data['customer'] as Map<String, dynamic>?;
      final authorization = data['authorization'] as Map<String, dynamic>?;

      if (subscription == null || customer == null || authorization == null) {
        return {'success': false, 'message': 'Missing required webhook data'};
      }

      final customerEmail = customer['email'] as String?;
      final amount = (data['amount'] ?? 0) / 100.0; // Convert from kobo
      final reference = data['reference'] as String?;

      if (customerEmail == null || reference == null) {
        return {
          'success': false,
          'message': 'Missing customer email or reference',
        };
      }

      // Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: customerEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'User not found with email: $customerEmail',
        };
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;

      // Find active subscription for this user
      final subscriptionQuery = await _firestore
          .collection('delayed_subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No active subscription found for user: $userId',
        };
      }

      final subscriptionDoc = subscriptionQuery.docs.first;
      final subscriptionData = subscriptionDoc.data();
      final packageName = subscriptionData['packageName'] as String?;

      if (packageName == null) {
        return {
          'success': false,
          'message': 'Package name not found in subscription',
        };
      }

      // Process monthly credit
      final result = await processMonthlyCredit(
        userId: userId,
        packageName: packageName,
        transactionReference: reference,
        paymentAmount: amount,
      );

      return result;
    } catch (e) {
      // print('Error processing Paystack webhook: $e');
      return {
        'success': false,
        'message': 'Failed to process webhook: ${e.toString()}',
      };
    }
  }

  /// Create a test monthly credit (for testing purposes)
  static Future<Map<String, dynamic>> createTestMonthlyCredit({
    required String userId,
    required String packageName,
  }) async {
    try {
      // print('=== CREATING TEST MONTHLY CREDIT ===');
      // print('User ID: $userId');
      // print('Package: $packageName');

      final result = await processMonthlyCredit(
        userId: userId,
        packageName: packageName,
        transactionReference: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        paymentAmount: 500.0, // Test payment amount
      );

      return result;
    } catch (e) {
      // print('Error creating test monthly credit: $e');
      return {
        'success': false,
        'message': 'Failed to create test credit: ${e.toString()}',
      };
    }
  }
}
