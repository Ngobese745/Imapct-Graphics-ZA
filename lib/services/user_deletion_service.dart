import 'package:cloud_firestore/cloud_firestore.dart';

class UserDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Comprehensive user deletion - removes ALL user data from Firebase
  static Future<Map<String, dynamic>> deleteUserCompletely(
    String userId,
  ) async {
    final deletionResults = <String, dynamic>{};
    final errors = <String>[];

    try {
      // print('🗑️ Starting comprehensive user deletion for: $userId');

      // 1. Delete user profile from users collection
      await _deleteUserProfile(userId, deletionResults, errors);

      // 2. Delete user's cart and cart items
      await _deleteUserCart(userId, deletionResults, errors);

      // 3. Delete user's orders
      await _deleteUserOrders(userId, deletionResults, errors);

      // 4. Delete user's wallet and wallet transactions
      await _deleteUserWallet(userId, deletionResults, errors);

      // 5. Delete user's transactions
      await _deleteUserTransactions(userId, deletionResults, errors);

      // 6. Delete user's delayed subscriptions
      await _deleteUserDelayedSubscriptions(userId, deletionResults, errors);

      // 7. Delete user's support requests and chat history
      await _deleteUserSupportData(userId, deletionResults, errors);

      // 8. Delete user's notifications
      await _deleteUserNotifications(userId, deletionResults, errors);

      // 9. Delete user's referral data
      await _deleteUserReferralData(userId, deletionResults, errors);

      // 10. Delete user's monthly credit data
      await _deleteUserMonthlyCreditData(userId, deletionResults, errors);

      // 11. Delete user from clients collection if they exist there
      await _deleteUserFromClients(userId, deletionResults, errors);

      // 12. Delete Firebase Auth user (if possible)
      await _deleteFirebaseAuthUser(userId, deletionResults, errors);

      // 13. Delete any other user-related data
      await _deleteMiscUserData(userId, deletionResults, errors);

      // print('✅ User deletion completed for: $userId');
      // print('📊 Deletion summary: $deletionResults');

      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? 'User deleted successfully'
            : 'User deleted with some errors: ${errors.join(', ')}',
        'deletionResults': deletionResults,
        'errors': errors,
      };
    } catch (e) {
      // print('❌ Error during user deletion: $e');
      return {
        'success': false,
        'message': 'Failed to delete user: $e',
        'deletionResults': deletionResults,
        'errors': [...errors, e.toString()],
      };
    }
  }

  /// Delete user profile from users collection
  static Future<void> _deleteUserProfile(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      results['userProfile'] = 'deleted';
      // print('✅ Deleted user profile: $userId');
    } catch (e) {
      errors.add('Failed to delete user profile: $e');
      // print('❌ Error deleting user profile: $e');
    }
  }

  /// Delete user's cart and all cart items
  static Future<void> _deleteUserCart(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      // Delete cart items first
      final cartItemsSnapshot = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      final batch = _firestore.batch();
      for (final doc in cartItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete cart document
      await _firestore.collection('carts').doc(userId).delete();

      results['cart'] = 'deleted';
      results['cartItems'] = cartItemsSnapshot.docs.length;
      // print('✅ Deleted user cart and ${cartItemsSnapshot.docs.length} items');
    } catch (e) {
      errors.add('Failed to delete user cart: $e');
      // print('❌ Error deleting user cart: $e');
    }
  }

  /// Delete user's orders
  static Future<void> _deleteUserOrders(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in ordersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['orders'] = ordersSnapshot.docs.length;
      // print('✅ Deleted ${ordersSnapshot.docs.length} user orders');
    } catch (e) {
      errors.add('Failed to delete user orders: $e');
      // print('❌ Error deleting user orders: $e');
    }
  }

  /// Delete user's wallet and wallet transactions
  static Future<void> _deleteUserWallet(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      // Delete wallet document
      await _firestore.collection('wallets').doc(userId).delete();
      results['wallet'] = 'deleted';

      // Delete wallet transactions
      final walletTransactionsSnapshot = await _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in walletTransactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['walletTransactions'] = walletTransactionsSnapshot.docs.length;
      // print(
      //        '✅ Deleted user wallet and ${walletTransactionsSnapshot.docs.length} transactions',
      //      );
    } catch (e) {
      errors.add('Failed to delete user wallet: $e');
      // print('❌ Error deleting user wallet: $e');
    }
  }

  /// Delete user's transactions
  static Future<void> _deleteUserTransactions(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['transactions'] = transactionsSnapshot.docs.length;
      // print('✅ Deleted ${transactionsSnapshot.docs.length} user transactions');
    } catch (e) {
      errors.add('Failed to delete user transactions: $e');
      // print('❌ Error deleting user transactions: $e');
    }
  }

  /// Delete user's delayed subscriptions
  static Future<void> _deleteUserDelayedSubscriptions(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      final subscriptionsSnapshot = await _firestore
          .collection('delayed_subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in subscriptionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['delayedSubscriptions'] = subscriptionsSnapshot.docs.length;
      // print(
      //        '✅ Deleted ${subscriptionsSnapshot.docs.length} delayed subscriptions',
      //      );
    } catch (e) {
      errors.add('Failed to delete delayed subscriptions: $e');
      // print('❌ Error deleting delayed subscriptions: $e');
    }
  }

  /// Delete user's support requests and chat history
  static Future<void> _deleteUserSupportData(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      // Delete support requests
      final supportRequestsSnapshot = await _firestore
          .collection('support_requests')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in supportRequestsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete support chat messages for each support request
      for (final doc in supportRequestsSnapshot.docs) {
        final messagesSnapshot = await _firestore
            .collection('support_chats')
            .doc(doc.id)
            .collection('messages')
            .get();

        final messageBatch = _firestore.batch();
        for (final messageDoc in messagesSnapshot.docs) {
          messageBatch.delete(messageDoc.reference);
        }
        await messageBatch.commit();

        // Delete support chat document
        await _firestore.collection('support_chats').doc(doc.id).delete();
      }

      // Delete user chat history
      final userChatHistorySnapshot = await _firestore
          .collection('user_chat_history')
          .doc(userId)
          .collection('conversations')
          .get();

      final chatBatch = _firestore.batch();
      for (final doc in userChatHistorySnapshot.docs) {
        chatBatch.delete(doc.reference);
      }
      await chatBatch.commit();

      // Delete user chat history document
      await _firestore.collection('user_chat_history').doc(userId).delete();

      results['supportRequests'] = supportRequestsSnapshot.docs.length;
      results['userChatHistory'] = userChatHistorySnapshot.docs.length;
      // print(
      //        '✅ Deleted ${supportRequestsSnapshot.docs.length} support requests and chat history',
      //      );
    } catch (e) {
      errors.add('Failed to delete support data: $e');
      // print('❌ Error deleting support data: $e');
    }
  }

  /// Delete user's notifications
  static Future<void> _deleteUserNotifications(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['notifications'] = notificationsSnapshot.docs.length;
      // print('✅ Deleted ${notificationsSnapshot.docs.length} notifications');
    } catch (e) {
      errors.add('Failed to delete notifications: $e');
      // print('❌ Error deleting notifications: $e');
    }
  }

  /// Delete user's referral data
  static Future<void> _deleteUserReferralData(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      // Delete referrals where user is the referrer
      final referralsSnapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in referralsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete referrals where user is the referred
      final referredSnapshot = await _firestore
          .collection('referrals')
          .where('referredId', isEqualTo: userId)
          .get();

      for (final doc in referredSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['referrals'] =
          referralsSnapshot.docs.length + referredSnapshot.docs.length;
      // print(
      //        '✅ Deleted ${referralsSnapshot.docs.length + referredSnapshot.docs.length} referral records',
      //      );
    } catch (e) {
      errors.add('Failed to delete referral data: $e');
      // print('❌ Error deleting referral data: $e');
    }
  }

  /// Delete user's monthly credit data
  static Future<void> _deleteUserMonthlyCreditData(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      final monthlyCreditsSnapshot = await _firestore
          .collection('monthly_credits')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in monthlyCreditsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['monthlyCredits'] = monthlyCreditsSnapshot.docs.length;
      // print(
      //        '✅ Deleted ${monthlyCreditsSnapshot.docs.length} monthly credit records',
      //      );
    } catch (e) {
      errors.add('Failed to delete monthly credit data: $e');
      // print('❌ Error deleting monthly credit data: $e');
    }
  }

  /// Delete user from clients collection if they exist there
  static Future<void> _deleteUserFromClients(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      final clientsSnapshot = await _firestore
          .collection('clients')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in clientsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      results['clients'] = clientsSnapshot.docs.length;
      // print('✅ Deleted ${clientsSnapshot.docs.length} client records');
    } catch (e) {
      errors.add('Failed to delete client records: $e');
      // print('❌ Error deleting client records: $e');
    }
  }

  /// Delete Firebase Auth user (if possible)
  static Future<void> _deleteFirebaseAuthUser(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      // Note: This requires admin privileges and should be done server-side
      // For now, we'll just mark it as attempted
      results['firebaseAuth'] = 'requires_admin_action';
      // print('⚠️ Firebase Auth user deletion requires admin action');
    } catch (e) {
      errors.add('Failed to delete Firebase Auth user: $e');
      // print('❌ Error deleting Firebase Auth user: $e');
    }
  }

  /// Delete any other miscellaneous user data
  static Future<void> _deleteMiscUserData(
    String userId,
    Map<String, dynamic> results,
    List<String> errors,
  ) async {
    try {
      // Delete any other collections that might contain user data
      final collectionsToCheck = [
        'user_preferences',
        'user_settings',
        'user_activity',
        'user_sessions',
        'user_feedback',
        'user_analytics',
      ];

      int totalMiscDeleted = 0;
      for (final collection in collectionsToCheck) {
        try {
          final snapshot = await _firestore
              .collection(collection)
              .where('userId', isEqualTo: userId)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final batch = _firestore.batch();
            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            totalMiscDeleted += snapshot.docs.length;
            // print('✅ Deleted ${snapshot.docs.length} records from $collection');
          }
        } catch (e) {
          // Collection might not exist, which is fine
          // print('ℹ️ Collection $collection not found or accessible');
        }
      }

      results['miscData'] = totalMiscDeleted;
      // print('✅ Deleted $totalMiscDeleted miscellaneous records');
    } catch (e) {
      errors.add('Failed to delete miscellaneous data: $e');
      // print('❌ Error deleting miscellaneous data: $e');
    }
  }

  /// Get user data summary before deletion (for confirmation)
  static Future<Map<String, dynamic>> getUserDataSummary(String userId) async {
    final summary = <String, dynamic>{};

    try {
      // Count user's data across all collections
      final userProfile = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      summary['hasUserProfile'] = userProfile.exists;

      final cartItems = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();
      summary['cartItems'] = cartItems.docs.length;

      final orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      summary['orders'] = orders.docs.length;

      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();
      summary['transactions'] = transactions.docs.length;

      final supportRequests = await _firestore
          .collection('support_requests')
          .where('userId', isEqualTo: userId)
          .get();
      summary['supportRequests'] = supportRequests.docs.length;

      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      summary['notifications'] = notifications.docs.length;

      return summary;
    } catch (e) {
      // print('Error getting user data summary: $e');
      return {'error': e.toString()};
    }
  }
}
