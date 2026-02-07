import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/whatsapp_models.dart';
import '../services/whatsapp_service.dart';
import '../services/auth_service.dart';

class AdminWhatsAppScreen extends StatefulWidget {
  const AdminWhatsAppScreen({super.key});

  @override
  State<AdminWhatsAppScreen> createState() => _AdminWhatsAppScreenState();
}

class _AdminWhatsAppScreenState extends State<AdminWhatsAppScreen> {
  final WhatsAppService _whatsAppService = WhatsAppService();
  WhatsAppConversation? _selectedConversation;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    // Check if we are on a wide screen for split view
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Manager'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
      body: isWideScreen ? _buildSplitView() : _buildMobileListView(),
    );
  }

  Widget _buildSplitView() {
    return Row(
      children: [
        // Conversation List (Left Pane)
        SizedBox(
          width: 350,
          child: _buildConversationList(compact: false),
        ),
        const VerticalDivider(width: 1),
        // Chat View (Right Pane)
        Expanded(
          child: _selectedConversation == null
              ? _buildEmptyState()
              : _buildChatView(_selectedConversation!),
        ),
      ],
    );
  }

  Widget _buildMobileListView() {
    return _selectedConversation == null
        ? _buildConversationList(compact: false)
        : _buildChatView(_selectedConversation!); // This should ideally be a push navigation
  }

  Widget _buildConversationList({required bool compact}) {
    return StreamBuilder<List<WhatsAppConversation>>(
      stream: _whatsAppService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return const Center(child: Text('No active WhatsApp conversations'));
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final isSelected = _selectedConversation?.phoneNumber ==
                conversation.phoneNumber;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF25D366),
                child: Text(
                  conversation.userName.isNotEmpty
                      ? conversation.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                conversation.userName,
                style: TextStyle(
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                conversation.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(conversation.lastMessageAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (conversation.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B0000),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              selected: isSelected,
              selectedTileColor: Colors.grey[200],
              onTap: () {
                setState(() {
                  _selectedConversation = conversation;
                });
                // Mark as read immediately when selected
                if (conversation.unreadCount > 0) {
                  _whatsAppService.markAsRead(conversation.phoneNumber);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatView(WhatsAppConversation conversation) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              if (MediaQuery.of(context).size.width <= 800)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedConversation = null;
                    });
                  },
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      conversation.phoneNumber,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text('AI Assistant:'),
                  Switch(
                    value: conversation.aiActive,
                    activeColor: const Color(0xFF25D366),
                    onChanged: (value) {
                      _whatsAppService.toggleAi(conversation.phoneNumber, value);
                      // Optimistic update
                      setState(() {
                        _selectedConversation = WhatsAppConversation(
                          phoneNumber: conversation.phoneNumber,
                          userName: conversation.userName,
                          lastMessage: conversation.lastMessage,
                          lastMessageAt: conversation.lastMessageAt,
                          unreadCount: conversation.unreadCount,
                          aiActive: value
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Messages Area
        Expanded(
          child: StreamBuilder<List<WhatsAppMessage>>(
            stream: _whatsAppService.getMessages(conversation.phoneNumber),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No messages yet.'));
              }

              final messages = snapshot.data!;

              return ListView.builder(
                controller: _scrollController,
                reverse: true, // Start from bottom
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message);
                },
              );
            },
          ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Color(0xFF25D366)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(WhatsAppMessage message) {
    final isMe = !message.isFromUser;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe 
            ? (message.isAi ? const Color(0xFFE3F2FD) : const Color(0xFFDCF8C6)) 
            : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.black87 : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isAi)
                  const Padding(
                    padding: EdgeInsets.only(right: 4.0),
                    child: Icon(Icons.smart_toy, size: 12, color: Colors.blue),
                  ),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Select a conversation to start chatting',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedConversation == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    setState(() {
      _isSending = true;
    });

    try {
      await _whatsAppService.sendMessage(
        _selectedConversation!.phoneNumber,
        messageText,
      );
      _messageController.clear();
      // Scroll to bottom will happen automatically due to reverse ListView and stream update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
}
