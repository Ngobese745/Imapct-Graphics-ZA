import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a unique referral code for a user
  static Future<String> generateReferralCode(String userId) async {
    try {
      // Check if user already has a referral code
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final existingCode = userData['referralCode'] as String?;

        if (existingCode != null && existingCode.isNotEmpty) {
          return existingCode;
        }
      }

      // Generate new referral code
      String newCode = _generateCode();
      bool isUnique = false;
      int attempts = 0;

      while (!isUnique && attempts < 10) {
        // Check if code is unique
        final existingCodes = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: newCode)
            .get();

        if (existingCodes.docs.isEmpty) {
          isUnique = true;
        } else {
          attempts++;
          newCode = _generateCode(); // Generate new code for next attempt
        }
      }

      if (!isUnique) {
        // Fallback to timestamp-based code
        newCode =
            'IMPACT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      }

      // Save to Firebase
      await _firestore.collection('users').doc(userId).update({
        'referralCode': newCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newCode;
    } catch (e) {
      print('Error generating referral code: $e');
      // Fallback code
      return 'IMPACT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  /// Generate a random referral code
  static String _generateCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'IMPACT$random';
  }

  /// Find referrer by referral code
  static Future<String?> findReferrerByCode(String referralCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error finding referrer: $e');
      return null;
    }
  }

  /// Create a referral record
  static Future<Map<String, dynamic>> createReferral({
    required String referrerId,
    required String referredUserId,
    required String referredUserName,
    required String referredUserEmail,
    String status = 'pending',
    double earnings = 0.0,
  }) async {
    try {
      // Check if referral already exists
      final existingReferral = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: referrerId)
          .where('referredUserId', isEqualTo: referredUserId)
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Referral already exists',
          'referralId': existingReferral.docs.first.id,
        };
      }

      // Create referral record
      final referralData = {
        'referrerId': referrerId,
        'referredUserId': referredUserId,
        'referredUserName': referredUserName,
        'referredUserEmail': referredUserEmail,
        'status': status,
        'earnings': earnings,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('referrals').add(referralData);

      return {
        'success': true,
        'message': 'Referral created successfully',
        'referralId': docRef.id,
      };
    } catch (e) {
      print('Error creating referral: $e');
      return {'success': false, 'message': 'Error creating referral: $e'};
    }
  }

  /// Update referral status
  static Future<bool> updateReferralStatus({
    required String referralId,
    required String status,
    double? earnings,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (earnings != null) {
        updateData['earnings'] = earnings;
      }

      await _firestore
          .collection('referrals')
          .doc(referralId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating referral status: $e');
      return false;
    }
  }

  /// Get referrals for a user
  static Stream<QuerySnapshot> getUserReferrals(String userId) {
    return _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .snapshots();
  }

  /// Get completed referrals for earnings calculation
  static Stream<QuerySnapshot> getCompletedReferrals(String userId) {
    return _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  /// Process referral when user makes a purchase
  static Future<void> processReferralPurchase({
    required String referredUserId,
    required double purchaseAmount,
  }) async {
    try {
      // Find the referral record
      final referralQuery = await _firestore
          .collection('referrals')
          .where('referredUserId', isEqualTo: referredUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (referralQuery.docs.isEmpty) {
        print('No pending referral found for user: $referredUserId');
        return;
      }

      final referralDoc = referralQuery.docs.first;
      final referralData = referralDoc.data();
      final referrerId = referralData['referrerId'] as String;

      // Calculate earnings (15% of purchase amount)
      final earnings = purchaseAmount * 0.15;

      // Update referral status to completed
      await updateReferralStatus(
        referralId: referralDoc.id,
        status: 'completed',
        earnings: earnings,
      );

      // Add earnings to referrer's wallet
      await _addEarningsToWallet(referrerId, earnings);

      print('Referral processed: $earnings earned for referrer: $referrerId');
    } catch (e) {
      print('Error processing referral purchase: $e');
    }
  }

  /// Add earnings to referrer's pending earnings and credit to wallet if >= R100
  static Future<void> _addEarningsToWallet(
    String referrerId,
    double earnings,
  ) async {
    try {
      // Get current user data
      final userDoc = await _firestore
          .collection('users')
          .doc(referrerId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();
      final pendingEarnings = (userData['pendingReferralEarnings'] ?? 0.0)
          .toDouble();

      // Add new earnings to pending
      final newPendingEarnings = pendingEarnings + earnings;

      print(
        'Referrer $referrerId - Pending earnings: R$pendingEarnings + R$earnings = R$newPendingEarnings',
      );

      // Check if pending earnings >= R100 threshold
      if (newPendingEarnings >= 100.0) {
        // Credit the full pending amount to wallet
        await _firestore.collection('users').doc(referrerId).update({
          'walletBalance': currentBalance + newPendingEarnings,
          'pendingReferralEarnings': 0.0, // Reset pending earnings
          'lastReferralPayout': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create transaction record for wallet credit
        await _firestore.collection('transactions').add({
          'userId': referrerId,
          'amount': newPendingEarnings,
          'transactionId':
              'REFERRAL_PAYOUT_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'completed',
          'type': 'referral_payout',
          'description':
              'Referral earnings payout - R${newPendingEarnings.toStringAsFixed(2)}',
          'createdAt': FieldValue.serverTimestamp(),
        });

        print(
          '✅ Referral payout: R${newPendingEarnings.toStringAsFixed(2)} credited to wallet for referrer: $referrerId',
        );

        // Send notification about wallet credit
        await _sendPayoutNotification(referrerId, newPendingEarnings);
      } else {
        // Just update pending earnings (not enough to payout yet)
        await _firestore.collection('users').doc(referrerId).update({
          'pendingReferralEarnings': newPendingEarnings,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final remaining = 100.0 - newPendingEarnings;
        print(
          '⏳ Pending earnings updated: R${newPendingEarnings.toStringAsFixed(2)} (R${remaining.toStringAsFixed(2)} more needed for payout)',
        );
      }
    } catch (e) {
      print('Error adding earnings to wallet: $e');
    }
  }

  /// Send notification to referrer about wallet payout
  static Future<void> _sendPayoutNotification(
    String referrerId,
    double amount,
  ) async {
    try {
      // This would integrate with your notification service
      print(
        '💰 Payout Notification: R${amount.toStringAsFixed(2)} has been credited to your wallet!',
      );
    } catch (e) {
      print('Error sending payout notification: $e');
    }
  }

  /// Check if user was referred and process referral
  static Future<void> checkAndProcessReferral({
    required String userId,
    required String userName,
    required String userEmail,
    String? referralCode,
  }) async {
    if (referralCode == null || referralCode.isEmpty) return;

    try {
      // Find referrer
      final referrerId = await findReferrerByCode(referralCode);
      if (referrerId == null) {
        print('Referral code not found: $referralCode');
        return;
      }

      // Prevent self-referral
      if (referrerId == userId) {
        print('Cannot refer yourself');
        return;
      }

      // Create referral record
      final referralResult = await createReferral(
        referrerId: referrerId,
        referredUserId: userId,
        referredUserName: userName,
        referredUserEmail: userEmail,
        status: 'completed',
        earnings: 0.0, // No immediate earnings - reward after 20 referrals
      );

      if (referralResult['success']) {
        // Check if referrer has reached 20 referrals
        await _checkAndRewardReferralMilestone(referrerId);

        // Send notification to referrer
        await _sendReferralNotification(referrerId, userName, 0.0);

        print(
          'Referral recorded for referrer: $referrerId from new user: $userId',
        );
      }

      print('Referral created for user: $userId with code: $referralCode');
    } catch (e) {
      print('Error checking and processing referral: $e');
    }
  }

  /// Check if referrer has reached 20 referrals and add to pending earnings
  /// TERMS: All referral rewards can only be used to purchase services in the app
  /// Pending earnings are credited to wallet when they reach R100
  static Future<void> _checkAndRewardReferralMilestone(
    String referrerId,
  ) async {
    try {
      // Get all completed referrals for this user
      final referralsQuery = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: referrerId)
          .where('status', isEqualTo: 'completed')
          .get();

      final totalReferrals = referralsQuery.docs.length;
      print('Referrer $referrerId has $totalReferrals total referrals');

      // Get user data to check pending earnings
      final userDoc = await _firestore
          .collection('users')
          .doc(referrerId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();
      final pendingReferralEarnings =
          (userData['pendingReferralEarnings'] ?? 0.0).toDouble();
      final referralMilestonesReached =
          userData['referralMilestonesReached'] as List<dynamic>? ?? [];

      // Check if user reached 20 referrals milestone and hasn't been credited yet
      if (totalReferrals >= 20 && !referralMilestonesReached.contains(20)) {
        // Add R10 to pending earnings (not wallet yet)
        final newPendingEarnings = pendingReferralEarnings + 10.0;

        print(
          'Adding R10 to pending referral earnings: R$pendingReferralEarnings -> R$newPendingEarnings',
        );

        // Mark milestone as reached
        await _firestore.collection('users').doc(referrerId).update({
          'pendingReferralEarnings': newPendingEarnings,
          'referralMilestonesReached': FieldValue.arrayUnion([20]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print(
          '✅ Referral milestone reached! R10 added to pending earnings (Total pending: R$newPendingEarnings)',
        );

        // Check if pending earnings >= R100, then credit to wallet
        if (newPendingEarnings >= 100.0) {
          final newBalance = currentBalance + newPendingEarnings;

          await _firestore.collection('users').doc(referrerId).update({
            'walletBalance': newBalance,
            'pendingReferralEarnings': 0.0, // Reset pending
            'lastReferralPayout': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Create transaction record
          await _firestore.collection('walletTransactions').add({
            'userId': referrerId,
            'amount': newPendingEarnings,
            'type': 'credit',
            'description':
                'Referral earnings payout - R${newPendingEarnings.toStringAsFixed(2)} (for purchasing services only)',
            'balance': newBalance,
            'createdAt': FieldValue.serverTimestamp(),
          });

          print(
            '🎉 REFERRAL PAYOUT! R${newPendingEarnings.toStringAsFixed(2)} credited to wallet for referrer: $referrerId',
          );

          // Send payout notification
          await _sendPayoutNotification(referrerId, newPendingEarnings);
        } else {
          // Send milestone notification showing pending amount
          final remaining = 100.0 - newPendingEarnings;
          print(
            'Pending earnings: R${newPendingEarnings.toStringAsFixed(2)} (R${remaining.toStringAsFixed(2)} more needed for payout)',
          );
          await _sendMilestoneNotification(referrerId, 20, newPendingEarnings);
        }
      }
    } catch (e) {
      print('Error checking referral milestone: $e');
    }
  }

  /// Send notification about milestone achievement
  static Future<void> _sendMilestoneNotification(
    String referrerId,
    int milestone,
    double pendingAmount,
  ) async {
    try {
      final remaining = 100.0 - pendingAmount;
      print(
        '🎉 Milestone Notification: You\'ve reached $milestone referrals! R10 added to pending earnings. Total pending: R${pendingAmount.toStringAsFixed(2)} (R${remaining.toStringAsFixed(2)} more needed for payout). Reward funds can only be used to purchase services.',
      );
    } catch (e) {
      print('Error sending milestone notification: $e');
    }
  }

  /// Send notification to referrer about new referral
  static Future<void> _sendReferralNotification(
    String referrerId,
    String referredUserName,
    double earnings,
  ) async {
    try {
      // Get total referrals count
      final referralsQuery = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: referrerId)
          .where('status', isEqualTo: 'completed')
          .get();

      final totalReferrals = referralsQuery.docs.length;
      final remaining = 20 - totalReferrals;

      if (remaining > 0) {
        print(
          'Notification: $referredUserName registered using your referral code! ($totalReferrals/20 referrals - $remaining more to earn R10)',
        );
      } else {
        print(
          'Notification: $referredUserName registered using your referral code! You\'ve reached 20 referrals!',
        );
      }
    } catch (e) {
      print('Error sending referral notification: $e');
    }
  }

  /// Get pending referral earnings for a user
  static Future<double> getPendingEarnings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;

      final userData = userDoc.data() as Map<String, dynamic>;
      return (userData['pendingReferralEarnings'] ?? 0.0).toDouble();
    } catch (e) {
      print('Error getting pending earnings: $e');
      return 0.0;
    }
  }

  /// Get total lifetime referral earnings for a user
  static Future<Map<String, double>> getReferralEarningsSummary(
    String userId,
  ) async {
    try {
      // Get pending earnings
      final pendingEarnings = await getPendingEarnings(userId);

      // Get total paid earnings from transactions
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'referral_payout')
          .get();

      double totalPaid = 0.0;
      for (var doc in transactionsQuery.docs) {
        final data = doc.data();
        totalPaid += (data['amount'] ?? 0.0).toDouble();
      }

      return {
        'pending': pendingEarnings,
        'paid': totalPaid,
        'total': pendingEarnings + totalPaid,
      };
    } catch (e) {
      print('Error getting earnings summary: $e');
      return {'pending': 0.0, 'paid': 0.0, 'total': 0.0};
    }
  }

  /// Manual payout - Admin can trigger payout even if below R100 threshold
  /// Use this with caution - typically only for special cases or user requests
  static Future<Map<String, dynamic>> manualPayout({
    required String userId,
    String? adminId,
    String? reason,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found'};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final pendingEarnings = (userData['pendingReferralEarnings'] ?? 0.0)
          .toDouble();
      final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();

      if (pendingEarnings <= 0) {
        return {'success': false, 'message': 'No pending earnings to payout'};
      }

      // Credit pending earnings to wallet
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': currentBalance + pendingEarnings,
        'pendingReferralEarnings': 0.0,
        'lastReferralPayout': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create transaction record
      await _firestore.collection('transactions').add({
        'userId': userId,
        'amount': pendingEarnings,
        'transactionId':
            'MANUAL_REFERRAL_PAYOUT_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'completed',
        'type': 'referral_payout',
        'description':
            reason ??
            'Manual referral payout - R${pendingEarnings.toStringAsFixed(2)}',
        'adminId': adminId,
        'isManualPayout': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(
        'Manual payout completed: R${pendingEarnings.toStringAsFixed(2)} credited to user: $userId',
      );

      return {
        'success': true,
        'message': 'Payout successful',
        'amount': pendingEarnings,
      };
    } catch (e) {
      print('Error processing manual payout: $e');
      return {'success': false, 'message': 'Error processing payout: $e'};
    }
  }
}
