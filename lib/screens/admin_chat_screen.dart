import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

enum MessageType { user, bot, admin, quickActions }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isFromAdmin;
  final DateTime timestamp;
  final String? senderName;
  final MessageType messageType;
  final List<String>? quickActions;

  ChatMessage({
    required this.id,
    required this.text,
    this.isUser = false,
    this.isFromAdmin = false,
    required this.timestamp,
    this.senderName,
    this.messageType = MessageType.bot,
    this.quickActions,
  });
}

class AdminChatScreen extends StatefulWidget {
  final String supportRequestId;
  final String userId;
  final String userName;
  final String userEmail;
  final String initialMessage;

  const AdminChatScreen({
    super.key,
    required this.supportRequestId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.initialMessage,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load the complete conversation history including bot messages
      await _loadCompleteConversationHistory();

      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
// print('Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCompleteConversationHistory() async {
    try {
      // Load support chat messages (admin-user messages)
      final chatSnapshot = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.supportRequestId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      // Load bot conversation history from user's chat support
      final botConversationSnapshot = await FirebaseFirestore.instance
          .collection('user_chat_history')
          .doc(widget.userId)
          .collection('conversations')
          .where('supportRequestId', isEqualTo: widget.supportRequestId)
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _messages.clear();

        // Combine and sort all messages by timestamp
        List<ChatMessage> allMessages = [];

        // Add initial support request message
        allMessages.add(
          ChatMessage(
            id: 'initial',
            text: widget.initialMessage,
            isFromAdmin: false,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            senderName: widget.userName,
            messageType: MessageType.user,
          ),
        );

        // Add support chat messages
        for (final doc in chatSnapshot.docs) {
          final data = doc.data();
          allMessages.add(
            ChatMessage(
              id: doc.id,
              text: data['message'] ?? '',
              isFromAdmin: data['isFromAdmin'] ?? false,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              senderName: data['senderName'] ?? 'Unknown',
              messageType: data['isFromAdmin'] == true
                  ? MessageType.admin
                  : MessageType.user,
            ),
          );
        }

        // Add bot conversation messages
        for (final doc in botConversationSnapshot.docs) {
          final data = doc.data();
          allMessages.add(
            ChatMessage(
              id: doc.id,
              text: data['message'] ?? '',
              isFromAdmin: false,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              senderName: data['senderName'] ?? 'Bot',
              messageType: data['isUser'] == true
                  ? MessageType.user
                  : MessageType.bot,
            ),
          );
        }

        // Sort all messages by timestamp
        allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _messages.addAll(allMessages);
      });
    } catch (e) {
// print('Error loading complete conversation history: $e');
      // Fallback to loading just support chat messages
      await _loadSupportChatOnly();
    }
  }

  Future<void> _loadSupportChatOnly() async {
    try {
      final chatSnapshot = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.supportRequestId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _messages.clear();

        // Add initial support request message
        _messages.add(
          ChatMessage(
            id: 'initial',
            text: widget.initialMessage,
            isFromAdmin: false,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            senderName: widget.userName,
            messageType: MessageType.user,
          ),
        );

        // Add existing chat messages
        for (final doc in chatSnapshot.docs) {
          final data = doc.data();
          _messages.add(
            ChatMessage(
              id: doc.id,
              text: data['message'] ?? '',
              isFromAdmin: data['isFromAdmin'] ?? false,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              senderName: data['senderName'] ?? '',
              messageType: data['isFromAdmin'] == true
                  ? MessageType.admin
                  : MessageType.user,
            ),
          );
        }
      });
    } catch (e) {
// print('Error loading support chat only: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      isFromAdmin: true,
      timestamp: DateTime.now(),
      senderName: currentUser.displayName ?? 'Admin',
    );

    try {
      // Add message to local list immediately for better UX
      setState(() {
        _messages.add(newMessage);
      });

      _messageController.clear();
      _scrollToBottom();

      // Save message to Firestore
// print('=== ADMIN SENDING MESSAGE ===');
// print('Support Request ID: ${widget.supportRequestId}');
// print('User ID: ${widget.userId}');
// print('Message: $messageText');

      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.supportRequestId)
          .collection('messages')
          .add({
            'message': messageText,
            'isFromAdmin': true,
            'senderId': currentUser.uid,
            'senderName': currentUser.displayName ?? 'Admin',
            'timestamp': FieldValue.serverTimestamp(),
            'supportRequestId': widget.supportRequestId,
            'userId': widget.userId,
          });

// print('Message saved to Firestore successfully');

      // Also ensure the support chat document exists
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.supportRequestId)
          .set({
            'supportRequestId': widget.supportRequestId,
            'userId': widget.userId,
            'userName': widget.userName,
            'userEmail': widget.userEmail,
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageAt': FieldValue.serverTimestamp(),
          });

      // Update support request last activity
      await FirebaseFirestore.instance
          .collection('support_requests')
          .doc(widget.supportRequestId)
          .update({
            'lastMessageAt': FieldValue.serverTimestamp(),
            'lastMessageBy': currentUser.uid,
            'hasUnreadMessages':
                false, // Admin sent message, so no unread for admin
          });

      // Send notification to user
      await NotificationService.sendNotificationToUser(
        userId: widget.userId,
        title: 'New Message from Support',
        body: 'You have a new message about your support request',
        type: 'support_chat',
        action: 'new_admin_message',
        data: {
          'supportRequestId': widget.supportRequestId,
          'message': messageText,
          'adminName': currentUser.displayName ?? 'Admin',
        },
      );
    } catch (e) {
// print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Remove the message from local list if it failed to send
      setState(() {
        _messages.removeWhere((msg) => msg.id == newMessage.id);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.userEmail,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'resolve':
                  _resolveSupportRequest();
                  break;
                case 'view_details':
                  _viewSupportRequestDetails();
                  break;
                case 'contact_info':
                  _showContactInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'resolve',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Resolve Request'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_details',
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'contact_info',
                child: Row(
                  children: [
                    Icon(Icons.contact_phone, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Contact Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start the conversation',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to ${widget.userName} about their support request',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('support_chats')
                        .doc(widget.supportRequestId)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final messages = snapshot.data!.docs;

                        // Update local messages list with latest data
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            final updatedMessages = <ChatMessage>[];

                            // Add initial support request message
                            updatedMessages.add(
                              ChatMessage(
                                id: 'initial',
                                text: widget.initialMessage,
                                isFromAdmin: false,
                                timestamp: DateTime.now().subtract(
                                  const Duration(hours: 1),
                                ),
                                senderName: widget.userName,
                              ),
                            );

                            // Add all chat messages
                            for (final doc in messages) {
                              final data = doc.data() as Map<String, dynamic>;
                              updatedMessages.add(
                                ChatMessage(
                                  id: doc.id,
                                  text: data['message'] ?? '',
                                  isFromAdmin: data['isFromAdmin'] ?? false,
                                  timestamp: (data['timestamp'] as Timestamp)
                                      .toDate(),
                                  senderName: data['senderName'] ?? '',
                                ),
                              );
                            }

                            if (updatedMessages.length != _messages.length) {
                              setState(() {
                                _messages.clear();
                                _messages.addAll(updatedMessages);
                              });
                              _scrollToBottom();
                            }
                          }
                        });
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(_messages[index]);
                        },
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B0000),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B0000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8B0000),
              child: Text(
                (message.senderName?.isNotEmpty ?? false)
                    ? message.senderName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromAdmin
                    ? const Color(0xFF8B0000)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isFromAdmin
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isFromAdmin
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.senderName ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromAdmin) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8B0000),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _resolveSupportRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Resolve Support Request',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to mark this support request as resolved? This will notify ${widget.userName} that their issue has been resolved.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resolve', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('support_requests')
            .doc(widget.supportRequestId)
            .update({
              'status': 'resolved',
              'resolvedAt': FieldValue.serverTimestamp(),
              'resolvedBy': FirebaseAuth.instance.currentUser?.uid,
            });

        // Send notification to user
        await NotificationService.sendNotificationToUser(
          userId: widget.userId,
          title: 'Support Request Resolved',
          body:
              'Your support request has been resolved. Thank you for contacting us!',
          type: 'support',
          action: 'support_resolved',
          data: {'supportRequestId': widget.supportRequestId},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resolving support request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewSupportRequestDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Support Request Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Request ID', widget.supportRequestId),
            _buildDetailRow('User Name', widget.userName),
            _buildDetailRow('Email', widget.userEmail),
            _buildDetailRow('Initial Message', widget.initialMessage),
            _buildDetailRow('Messages Count', '${_messages.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Contact Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Name', widget.userName),
            _buildDetailRow('Email', widget.userEmail),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
