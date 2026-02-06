import 'package:cloud_firestore/cloud_firestore.dart';

class ChatCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Run cleanup tasks
  static Future<void> runCleanupTasks() async {
    await _closeInactiveChats();
    await _deleteOldCases();
  }

  // Close chats where user hasn't responded for over 10 minutes
  static Future<void> _closeInactiveChats() async {
    try {
      final tenMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 10),
      );

      // Find support requests that are in_progress and haven't had user activity for 10+ minutes
      final inactiveRequests = await _firestore
          .collection('support_requests')
          .where('status', isEqualTo: 'in_progress')
          .where(
            'lastUserActivity',
            isLessThan: Timestamp.fromDate(tenMinutesAgo),
          )
          .get();

      for (final doc in inactiveRequests.docs) {
        await _closeInactiveChat(doc.id);
      }

// print('Closed ${inactiveRequests.docs.length} inactive chats');
    } catch (e) {
// print('Error closing inactive chats: $e');
    }
  }

  // Close a specific inactive chat
  static Future<void> _closeInactiveChat(String supportRequestId) async {
    try {
      // Update support request status to closed
      await _firestore
          .collection('support_requests')
          .doc(supportRequestId)
          .update({
            'status': 'closed',
            'closedAt': FieldValue.serverTimestamp(),
            'closedReason': 'User inactive for 10+ minutes',
          });

      // Add closure message to support chat
      await _firestore
          .collection('support_chats')
          .doc(supportRequestId)
          .collection('messages')
          .add({
            'message':
                'This chat has been automatically closed due to inactivity. Please start a new conversation if you need further assistance.',
            'isFromAdmin': true,
            'senderName': 'System',
            'timestamp': FieldValue.serverTimestamp(),
            'isSystemMessage': true,
          });

// print('Closed inactive chat: $supportRequestId');
    } catch (e) {
// print('Error closing chat $supportRequestId: $e');
    }
  }

  // Delete cases older than 24 hours
  static Future<void> _deleteOldCases() async {
    try {
      final twentyFourHoursAgo = DateTime.now().subtract(
        const Duration(hours: 24),
      );

      // Find support requests that are closed and older than 24 hours
      final oldRequests = await _firestore
          .collection('support_requests')
          .where('status', isEqualTo: 'closed')
          .where('closedAt', isLessThan: Timestamp.fromDate(twentyFourHoursAgo))
          .get();

      for (final doc in oldRequests.docs) {
        await _deleteOldCase(doc.id);
      }

// print('Deleted ${oldRequests.docs.length} old cases');
    } catch (e) {
// print('Error deleting old cases: $e');
    }
  }

  // Delete a specific old case
  static Future<void> _deleteOldCase(String supportRequestId) async {
    try {
      // Delete support chat messages
      final messagesSnapshot = await _firestore
          .collection('support_chats')
          .doc(supportRequestId)
          .collection('messages')
          .get();

      for (final messageDoc in messagesSnapshot.docs) {
        await messageDoc.reference.delete();
      }

      // Delete support chat document
      await _firestore
          .collection('support_chats')
          .doc(supportRequestId)
          .delete();

      // Delete user chat history for this support request
      await _deleteUserChatHistory(supportRequestId);

      // Delete support request
      await _firestore
          .collection('support_requests')
          .doc(supportRequestId)
          .delete();

// print('Deleted old case: $supportRequestId');
    } catch (e) {
// print('Error deleting case $supportRequestId: $e');
    }
  }

  // Delete user chat history for a specific support request
  static Future<void> _deleteUserChatHistory(String supportRequestId) async {
    try {
      // Find all users who had conversations for this support request
      final userChatsSnapshot = await _firestore
          .collection('user_chat_history')
          .get();

      for (final userDoc in userChatsSnapshot.docs) {
        final conversationsSnapshot = await userDoc.reference
            .collection('conversations')
            .where('supportRequestId', isEqualTo: supportRequestId)
            .get();

        for (final conversationDoc in conversationsSnapshot.docs) {
          await conversationDoc.reference.delete();
        }
      }

// print('Deleted user chat history for support request: $supportRequestId');
    } catch (e) {
// print('Error deleting user chat history for $supportRequestId: $e');
    }
  }

  // Update last user activity timestamp
  static Future<void> updateUserActivity(String supportRequestId) async {
    try {
      await _firestore
          .collection('support_requests')
          .doc(supportRequestId)
          .update({'lastUserActivity': FieldValue.serverTimestamp()});
    } catch (e) {
// print('Error updating user activity: $e');
    }
  }

  // Schedule cleanup tasks to run periodically
  static void scheduleCleanupTasks() {
    // Run cleanup every 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      runCleanupTasks().then((_) {
        scheduleCleanupTasks(); // Schedule next cleanup
      });
    });
  }
}
