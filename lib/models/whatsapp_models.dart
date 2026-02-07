import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppConversation {
  final String phoneNumber;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool aiActive;

  WhatsAppConversation({
    required this.phoneNumber,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.aiActive,
  });

  factory WhatsAppConversation.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WhatsAppConversation(
      phoneNumber: doc.id,
      userName: data['userName'] ?? 'Unknown',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      aiActive: data['ai_active'] ?? false,
    );
  }
}

class WhatsAppMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final bool isAi;
  final DateTime timestamp;

  WhatsAppMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.isAi,
    required this.timestamp,
  });

  factory WhatsAppMessage.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WhatsAppMessage(
      id: doc.id,
      text: data['text'] ?? '',
      isFromUser: data['isFromUser'] ?? false,
      isAi: data['isAi'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
