import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/whatsapp_models.dart';

class WhatsAppService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Get stream of all conversations, ordered by last message time
  Stream<List<WhatsAppConversation>> getConversations() {
    return _firestore
        .collection('whatsapp_conversations')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WhatsAppConversation.fromSnapshot(doc))
          .toList();
    });
  }

  // Get stream of messages for a specific conversation
  Stream<List<WhatsAppMessage>> getMessages(String phoneNumber) {
    return _firestore
        .collection('whatsapp_conversations')
        .doc(phoneNumber)
        .collection('messages')
        .orderBy('timestamp', descending: true) // UI will reverse this
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WhatsAppMessage.fromSnapshot(doc))
          .toList();
    });
  }

  // Send a message via Cloud Function
  Future<void> sendMessage(String phoneNumber, String text) async {
    try {
      final callable = _functions.httpsCallable('sendWhatsAppMessage');
      await callable.call({
        'phone': phoneNumber,
        'message': text,
      });
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      throw e;
    }
  }

  // Toggle AI Assistant status
  Future<void> toggleAi(String phoneNumber, bool isActive) async {
    await _firestore
        .collection('whatsapp_conversations')
        .doc(phoneNumber)
        .update({'ai_active': isActive});
  }

  // Mark conversation as read
  Future<void> markAsRead(String phoneNumber) async {
    await _firestore
        .collection('whatsapp_conversations')
        .doc(phoneNumber)
        .update({'unreadCount': 0});
  }
}
