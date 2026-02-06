import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class LoyaltyRewardService {
  static const int LOYALTY_REWARD_THRESHOLD = 2000;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user has reached 2000 loyalty points and process reward
  static Future<Map<String, dynamic>> checkAndProcessLoyaltyReward(
    String userId,
  ) async {
    try {
      print('=== CHECKING LOYALTY REWARD ELIGIBILITY ===');
      print('User ID: $userId');

      // Get current loyalty points
      final currentPoints = await FirebaseService.getLoyaltyPoints(userId);
      print('Current loyalty points: $currentPoints');

      if (currentPoints >= LOYALTY_REWARD_THRESHOLD) {
        print('✅ User is eligible for loyalty reward!');

        // Process the loyalty reward
        final rewardResult = await _processLoyaltyReward(userId, currentPoints);

        if (rewardResult['success']) {
          // Reset loyalty points to 0
          await _resetLoyaltyPoints(userId);

          // Send notification
          await _sendLoyaltyRewardNotification(userId, rewardResult);

          return {
            'success': true,
            'message': 'Loyalty reward processed: R500 credited to wallet',
            'rewardAmount': rewardResult['rewardAmount'],
            'newBalance': rewardResult['newBalance'],
            'previousPoints': currentPoints,
            'newPoints': 0,
          };
        } else {
          return {
            'success': false,
            'message':
                'Failed to process loyalty reward: ${rewardResult['message']}',
          };
        }
      } else {
        print(
          'User needs ${LOYALTY_REWARD_THRESHOLD - currentPoints} more points for reward',
        );
        return {
          'success': false,
          'message': 'Not enough loyalty points',
          'currentPoints': currentPoints,
          'neededPoints': LOYALTY_REWARD_THRESHOLD - currentPoints,
        };
      }
    } catch (e) {
      print('Error checking loyalty reward: $e');
      return {
        'success': false,
        'message': 'Error checking loyalty reward: ${e.toString()}',
      };
    }
  }

  /// Process the loyalty reward by crediting R500 to user wallet
  static Future<Map<String, dynamic>> _processLoyaltyReward(
    String userId,
    int currentPoints,
  ) async {
    try {
      print('=== PROCESSING LOYALTY REWARD ===');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found'};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();
      final newBalance = currentBalance + 500.0;

      print('Crediting R500 to wallet for 2000 loyalty points');
      print('Current balance: R$currentBalance');
      print('New balance: R$newBalance');

      // Update wallet balance
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create transaction record for loyalty reward
      await _firestore.collection('walletTransactions').add({
        'userId': userId,
        'amount': 500.0,
        'type': 'credit',
        'description': 'Loyalty reward - 2000 points redeemed for R500',
        'balance': newBalance,
        'createdAt': FieldValue.serverTimestamp(),
        'loyaltyPointsUsed': currentPoints,
      });

      print('✅ R500 credited to wallet for loyalty reward');

      return {
        'success': true,
        'message': 'Loyalty reward processed successfully',
        'rewardAmount': 500.0,
        'newBalance': newBalance,
        'pointsRedeemed': currentPoints,
      };
    } catch (e) {
      print('Error processing loyalty reward: $e');
      return {
        'success': false,
        'message': 'Failed to process loyalty reward: ${e.toString()}',
      };
    }
  }

  /// Reset user's loyalty points to 0
  static Future<void> _resetLoyaltyPoints(String userId) async {
    try {
      print('=== RESETTING LOYALTY POINTS ===');

      await _firestore.collection('users').doc(userId).update({
        'loyaltyPoints': 0,
        'lastLoyaltyReward': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Loyalty points reset to 0');
    } catch (e) {
      print('Error resetting loyalty points: $e');
      rethrow;
    }
  }

  /// Send notification about the loyalty reward
  static Future<void> _sendLoyaltyRewardNotification(
    String userId,
    Map<String, dynamic> rewardResult,
  ) async {
    try {
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: '🎉 Loyalty Reward Unlocked!',
        body:
            'Congratulations! R500 has been credited to your wallet for reaching 2000 loyalty points! Your points have been reset to 0.',
        type: 'loyalty_reward',
        action: 'view_wallet',
        data: {
          'rewardAmount': rewardResult['rewardAmount'],
          'pointsRedeemed': rewardResult['pointsRedeemed'],
          'newBalance': rewardResult['newBalance'],
        },
      );

      print('✅ Loyalty reward notification sent to user: $userId');
    } catch (e) {
      print('Error sending loyalty reward notification: $e');
    }
  }

  /// Check if user is close to reaching the loyalty reward threshold
  static Future<Map<String, dynamic>> getLoyaltyRewardProgress(
    String userId,
  ) async {
    try {
      final currentPoints = await FirebaseService.getLoyaltyPoints(userId);
      final pointsNeeded = LOYALTY_REWARD_THRESHOLD - currentPoints;
      final progressPercentage =
          (currentPoints / LOYALTY_REWARD_THRESHOLD * 100).clamp(0.0, 100.0);

      return {
        'currentPoints': currentPoints,
        'threshold': LOYALTY_REWARD_THRESHOLD,
        'pointsNeeded': pointsNeeded,
        'progressPercentage': progressPercentage,
        'isEligible': currentPoints >= LOYALTY_REWARD_THRESHOLD,
        'isClose': pointsNeeded <= 100, // Close if within 100 points
      };
    } catch (e) {
      print('Error getting loyalty reward progress: $e');
      return {
        'currentPoints': 0,
        'threshold': LOYALTY_REWARD_THRESHOLD,
        'pointsNeeded': LOYALTY_REWARD_THRESHOLD,
        'progressPercentage': 0.0,
        'isEligible': false,
        'isClose': false,
      };
    }
  }
}
