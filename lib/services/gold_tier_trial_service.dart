import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'mailersend_service.dart';
import 'notification_service.dart';

class GoldTierTrialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check and expire gold tier trials that have ended
  static Future<void> checkAndExpireTrials() async {
    try {
      print('=== CHECKING GOLD TIER TRIALS ===');

      final now = DateTime.now();
      final expiredTrials = await _firestore
          .collection('users')
          .where('goldTierStatus', isEqualTo: 'trial')
          .where(
            'goldTierTrialEndDate',
            isLessThanOrEqualTo: Timestamp.fromDate(now),
          )
          .get();

      print('Found ${expiredTrials.docs.length} expired trials');

      for (final doc in expiredTrials.docs) {
        await _expireUserTrial(doc.id, doc.data());
      }
    } catch (e) {
      print('Error checking gold tier trials: $e');
    }
  }

  /// Expire a specific user's trial
  static Future<void> _expireUserTrial(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      print('Expiring trial for user: $userId');

      // Update user to Silver Tier
      await _firestore.collection('users').doc(userId).update({
        'isGoldTier': false,
        'goldTierActive': false,
        'goldTierStatus': 'expired',
        'accountStatus': 'Silver Tier user',
        'goldTierTrialEndDate': null,
        'goldTierTrialStartDate': null,
        'goldTierExpirationDate': FieldValue.serverTimestamp(),
        'hasHadGoldTierTrial': true, // Mark that user has had a trial
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send expiration notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Trial Expired',
        body:
            'Your 7-day Gold Tier trial has ended. Upgrade to continue enjoying premium features and 10% discount!',
        type: 'trial_expired',
        action: 'upgrade_to_gold',
      );

      print('Trial expired successfully for user: $userId');
    } catch (e) {
      print('Error expiring trial for user $userId: $e');
    }
  }

  /// Get trial status for current user
  static Future<Map<String, dynamic>?> getTrialStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      if (userData == null) return null;
      final goldTierStatus = userData['goldTierStatus'] as String?;
      final trialEndDate = userData['goldTierTrialEndDate'] as Timestamp?;

      if (goldTierStatus != 'trial' || trialEndDate == null) {
        return null;
      }

      final now = DateTime.now();
      final trialEnd = trialEndDate.toDate();
      final timeRemaining = trialEnd.difference(now);

      return {
        'isOnTrial': true,
        'trialEndDate': trialEnd,
        'timeRemaining': timeRemaining,
        'daysRemaining': timeRemaining.inDays,
        'hoursRemaining': timeRemaining.inHours,
        'isExpired': now.isAfter(trialEnd),
      };
    } catch (e) {
      print('Error getting trial status: $e');
      return null;
    }
  }

  /// Check if user can start a trial (haven't had one before)
  static Future<bool> canStartTrial(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return true;

      final userData = userDoc.data();
      if (userData == null) return true;
      final goldTierStatus = userData['goldTierStatus'] as String?;
      final hasHadTrial = userData['hasHadGoldTierTrial'] as bool? ?? false;

      // Can start trial if:
      // 1. Never had a trial before, OR
      // 2. Current status is not 'trial' and not 'expired'
      return !hasHadTrial ||
          (goldTierStatus != 'trial' && goldTierStatus != 'expired');
    } catch (e) {
      print('Error checking trial eligibility: $e');
      return false;
    }
  }

  /// Start a new trial for user
  static Future<bool> startTrial(String userId) async {
    try {
      // Check if user can start trial
      final canStart = await canStartTrial(userId);
      if (!canStart) {
        print('User $userId cannot start a new trial');
        return false;
      }

      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 7));

      await _firestore.collection('users').doc(userId).update({
        'isGoldTier': true,
        'goldTierActive': true,
        'goldTierStatus': 'trial',
        'accountStatus': 'Gold Tier user (Trial)',
        'goldTierTrialStartDate': FieldValue.serverTimestamp(),
        'goldTierTrialEndDate': Timestamp.fromDate(trialEndDate),
        'hasHadGoldTierTrial': true,
        'goldTierActivationDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send trial started notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Trial Started! 🏆',
        body:
            'Your 7-day Gold Tier trial has begun! Enjoy premium features and 10% discount on all services.',
        type: 'trial_started',
        action: 'gold_tier_trial_started',
      );

      print('Trial started successfully for user: $userId');

      // Refresh AuthService user profile to update dashboard
      final authService = AuthService.instance;
      if (authService != null) {
        await authService.refreshUserProfile();
        print('✅ AuthService user profile refreshed after trial start');
      }

      return true;
    } catch (e) {
      print('Error starting trial for user $userId: $e');
      return false;
    }
  }

  /// Convert trial to active subscription
  static Future<bool> convertTrialToActive(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;
      final goldTierStatus = userData['goldTierStatus'] as String?;

      if (goldTierStatus != 'trial') {
        print('User $userId is not on trial, cannot convert');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'goldTierStatus': 'active',
        'accountStatus': 'Gold Tier user',
        'goldTierActivationDate': FieldValue.serverTimestamp(),
        'goldTierTrialStartDate': null,
        'goldTierTrialEndDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send upgrade notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Activated! 🏆',
        body:
            'Welcome to Gold Tier! You now have unlimited access to premium features and 10% discount on all services.',
        type: 'upgrade',
        action: 'gold_tier_activated',
      );

      print('Trial converted to active subscription for user: $userId');
      return true;
    } catch (e) {
      print('Error converting trial to active for user $userId: $e');
      return false;
    }
  }

  /// Cancel trial (user chooses to end it early)
  static Future<bool> cancelTrial(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;
      final goldTierStatus = userData['goldTierStatus'] as String?;

      if (goldTierStatus != 'trial') {
        print('User $userId is not on trial, cannot cancel');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'isGoldTier': false,
        'goldTierActive': false,
        'goldTierStatus': 'cancelled',
        'accountStatus': 'Silver Tier user',
        'goldTierTrialStartDate': null,
        'goldTierTrialEndDate': null,
        'goldTierCancellationDate': FieldValue.serverTimestamp(),
        'hasHadGoldTierTrial': true, // Mark that user has had a trial
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send cancellation notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Trial Cancelled',
        body:
            'Your Gold Tier trial has been cancelled. You can upgrade anytime to enjoy premium features!',
        type: 'trial_cancelled',
        action: 'upgrade_to_gold',
      );

      print('Trial cancelled successfully for user: $userId');

      // Refresh AuthService user profile to update dashboard
      final authService = AuthService.instance;
      if (authService != null) {
        await authService.refreshUserProfile();
        print('✅ AuthService user profile refreshed after trial cancellation');
      }

      return true;
    } catch (e) {
      print('Error cancelling trial for user $userId: $e');
      return false;
    }
  }

  /// Cancel active subscription
  static Future<bool> cancelSubscription(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;
      final goldTierStatus = userData['goldTierStatus'] as String?;

      if (goldTierStatus != 'active') {
        print('User $userId is not on active subscription, cannot cancel');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'isGoldTier': false,
        'goldTierActive': false,
        'goldTierStatus': 'cancelled',
        'accountStatus': 'Silver Tier user',
        'goldTierActivationDate': null,
        'goldTierCancellationDate': FieldValue.serverTimestamp(),
        'hasHadGoldTierTrial': true, // Mark that user has had Gold Tier
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send cancellation notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Subscription Cancelled',
        body:
            'Your Gold Tier subscription has been cancelled. You will retain access until the end of your current billing period.',
        type: 'subscription_cancelled',
        action: 'upgrade_to_gold',
      );

      // Send cancellation email
      await _sendCancellationEmail(userId, userData);

      print('Subscription cancelled successfully for user: $userId');
      return true;
    } catch (e) {
      print('Error cancelling subscription for user $userId: $e');
      return false;
    }
  }

  /// Start new trial for new users (7-day free trial)
  static Future<bool> startNewUserTrial(String userId) async {
    try {
      // Check if user can start trial
      final canStart = await canStartTrial(userId);
      if (!canStart) {
        print('User $userId cannot start a new trial');
        return false;
      }

      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 7));

      await _firestore.collection('users').doc(userId).update({
        'isGoldTier': true,
        'goldTierActive': true,
        'goldTierStatus': 'trial',
        'accountStatus': 'Gold Tier user (Trial)',
        'goldTierTrialStartDate': FieldValue.serverTimestamp(),
        'goldTierTrialEndDate': Timestamp.fromDate(trialEndDate),
        'hasHadGoldTierTrial': true,
        'goldTierActivationDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send trial started notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Trial Started! 🏆',
        body:
            'Your 7-day Gold Tier trial has begun! Enjoy premium features and 10% discount on all services.',
        type: 'trial_started',
        action: 'gold_tier_trial_started',
      );

      print('New user trial started successfully for user: $userId');

      // Refresh AuthService user profile to update dashboard
      final authService = AuthService.instance;
      if (authService != null) {
        await authService.refreshUserProfile();
        print(
          '✅ AuthService user profile refreshed after new user trial start',
        );
      }

      return true;
    } catch (e) {
      print('Error starting new user trial for user $userId: $e');
      return false;
    }
  }

  /// Convert trial to active subscription (only on successful payment)
  static Future<bool> convertTrialToActiveOnPayment(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;
      final goldTierStatus = userData['goldTierStatus'] as String?;

      if (goldTierStatus != 'trial') {
        print('User $userId is not on trial, cannot convert');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'goldTierStatus': 'active',
        'accountStatus': 'Gold Tier user',
        'goldTierActivationDate': FieldValue.serverTimestamp(),
        'goldTierTrialStartDate': null,
        'goldTierTrialEndDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send upgrade notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Activated! 🏆',
        body:
            'Welcome to Gold Tier! You now have unlimited access to premium features and 10% discount on all services.',
        type: 'upgrade',
        action: 'gold_tier_activated',
      );

      // Send activation email
      await _sendActivationEmail(userId, userData);

      print('Trial converted to active subscription for user: $userId');
      return true;
    } catch (e) {
      print('Error converting trial to active for user $userId: $e');
      return false;
    }
  }

  /// Upgrade expired trial to active subscription (only on successful payment)
  static Future<bool> upgradeExpiredTrialToActive(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;
      final goldTierStatus = userData['goldTierStatus'] as String?;

      if (goldTierStatus != 'expired') {
        print('User $userId is not on expired trial, cannot upgrade');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'isGoldTier': true,
        'goldTierActive': true,
        'goldTierStatus': 'active',
        'accountStatus': 'Gold Tier user',
        'goldTierActivationDate': FieldValue.serverTimestamp(),
        'goldTierTrialStartDate': null,
        'goldTierTrialEndDate': null,
        'goldTierExpirationDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send upgrade notification
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Gold Tier Activated! 🏆',
        body:
            'Welcome to Gold Tier! You now have unlimited access to premium features and 10% discount on all services.',
        type: 'upgrade',
        action: 'gold_tier_activated',
      );

      // Send activation email
      await _sendActivationEmail(userId, userData);

      print('Expired trial upgraded to active subscription for user: $userId');
      return true;
    } catch (e) {
      print('Error upgrading expired trial for user $userId: $e');
      return false;
    }
  }

  /// Send cancellation email
  static Future<void> _sendCancellationEmail(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final userEmail = userData['email'] as String?;
      final userName =
          userData['name'] as String? ??
          userData['username'] as String? ??
          'Valued Client';

      if (userEmail != null && userEmail.isNotEmpty) {
        final emailResult =
            await MailerSendService.sendGoldTierCancellationEmail(
              toEmail: userEmail,
              toName: userName,
              accessUntilDate: DateTime.now()
                  .add(const Duration(days: 30))
                  .toString(),
            );

        if (emailResult.success) {
          print('✅ Gold Tier cancellation email sent successfully!');
        } else {
          print(
            '❌ Failed to send Gold Tier cancellation email: ${emailResult.message}',
          );
        }
      }
    } catch (e) {
      print('❌ Error sending Gold Tier cancellation email: $e');
    }
  }

  /// Send activation email
  static Future<void> _sendActivationEmail(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final userEmail = userData['email'] as String?;
      final userName =
          userData['name'] as String? ??
          userData['username'] as String? ??
          'Valued Client';

      if (userEmail != null && userEmail.isNotEmpty) {
        final emailResult = await MailerSendService.sendGoldTierActivationEmail(
          toEmail: userEmail,
          toName: userName,
          monthlyAmount: 'R299.00',
        );

        if (emailResult.success) {
          print('✅ Gold Tier activation email sent successfully!');
        } else {
          print(
            '❌ Failed to send Gold Tier activation email: ${emailResult.message}',
          );
        }
      }
    } catch (e) {
      print('❌ Error sending Gold Tier activation email: $e');
    }
  }
}
