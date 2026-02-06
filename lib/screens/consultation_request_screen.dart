import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart' show ResponsiveUtils, CartItem;
import 'paystack_payment_screen.dart';

class ConsultationRequestScreen extends StatefulWidget {
  final String serviceType; // 'marketing' or 'development'

  const ConsultationRequestScreen({super.key, required this.serviceType});

  @override
  State<ConsultationRequestScreen> createState() =>
      _ConsultationRequestScreenState();
}

class _ConsultationRequestScreenState extends State<ConsultationRequestScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _consultationId;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeConsultation();
  }

  Future<void> _initializeConsultation() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Check if there's an active consultation
      final consultationsQuery = await FirebaseFirestore.instance
          .collection('consultations')
          .where('userId', isEqualTo: userId)
          .where('serviceType', isEqualTo: widget.serviceType)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (consultationsQuery.docs.isNotEmpty) {
        _consultationId = consultationsQuery.docs.first.id;
      } else {
        // Create new consultation
        final currentUser = FirebaseAuth.instance.currentUser;

        // Get user name from Firestore, fallback to displayName, then email
        String userName = 'Unknown User';
        String userEmail = currentUser?.email ?? '';

        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final nameFromFirestore = userData['name'] as String?;
            if (nameFromFirestore != null && nameFromFirestore.isNotEmpty) {
              userName = nameFromFirestore;
            } else if (currentUser?.displayName != null &&
                currentUser!.displayName!.isNotEmpty) {
              userName = currentUser.displayName!;
            } else if (userEmail.isNotEmpty) {
              userName = userEmail;
            } else {
              userName = 'Unknown User';
            }
          } else {
            if (currentUser?.displayName != null &&
                currentUser!.displayName!.isNotEmpty) {
              userName = currentUser.displayName!;
            } else if (userEmail.isNotEmpty) {
              userName = userEmail;
            } else {
              userName = 'Unknown User';
            }
          }
        } catch (e) {
          print('Error fetching user data for consultation: $e');
          if (currentUser?.displayName != null &&
              currentUser!.displayName!.isNotEmpty) {
            userName = currentUser.displayName!;
          } else if (userEmail.isNotEmpty) {
            userName = userEmail;
          } else {
            userName = 'Unknown User';
          }
        }

        final docRef = await FirebaseFirestore.instance
            .collection('consultations')
            .add({
              'userId': userId,
              'userName': userName,
              'userEmail': userEmail,
              'serviceType': widget.serviceType,
              'status': 'active',
              'createdAt': FieldValue.serverTimestamp(),
              'lastMessageAt': FieldValue.serverTimestamp(),
              'hasUnreadMessages': false,
            });
        _consultationId = docRef.id;

        // Send initial system message
        await _sendSystemMessage(
          'Welcome! Please describe the service you need and we\'ll get back to you shortly.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error initializing chat: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSystemMessage(String message) async {
    if (_consultationId == null) return;

    await FirebaseFirestore.instance
        .collection('consultations')
        .doc(_consultationId)
        .collection('messages')
        .add({
          'message': message,
          'senderId': 'system',
          'senderName': 'Impact Graphics ZA',
          'senderType': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _consultationId == null) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final currentUser = FirebaseAuth.instance.currentUser;

      // Get user name from Firestore, fallback to displayName, then email
      String userName = 'User';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId!)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final nameFromFirestore = userData['name'] as String?;
          if (nameFromFirestore != null && nameFromFirestore.isNotEmpty) {
            userName = nameFromFirestore;
          } else if (currentUser?.displayName != null &&
              currentUser!.displayName!.isNotEmpty) {
            userName = currentUser.displayName!;
          } else if (currentUser?.email != null &&
              currentUser!.email!.isNotEmpty) {
            userName = currentUser.email!;
          } else {
            userName = 'User';
          }
        } else {
          if (currentUser?.displayName != null &&
              currentUser!.displayName!.isNotEmpty) {
            userName = currentUser.displayName!;
          } else if (currentUser?.email != null &&
              currentUser!.email!.isNotEmpty) {
            userName = currentUser.email!;
          } else {
            userName = 'User';
          }
        }
      } catch (e) {
        print('Error fetching user name for message: $e');
        if (currentUser?.displayName != null &&
            currentUser!.displayName!.isNotEmpty) {
          userName = currentUser.displayName!;
        } else if (currentUser?.email != null &&
            currentUser!.email!.isNotEmpty) {
          userName = currentUser.email!;
        } else {
          userName = 'User';
        }
      }

      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(_consultationId)
          .collection('messages')
          .add({
            'message': message,
            'senderId': userId,
            'senderName': userName,
            'senderType': 'user',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });

      // Update last message timestamp and mark as unread for admin
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(_consultationId)
          .update({
            'lastMessageAt': FieldValue.serverTimestamp(),
            'hasUnreadMessages': true,
            'lastMessageBy': userId,
          });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _handlePayment(
    String messageId,
    Map<String, dynamic> messageData,
  ) async {
    final amount = (messageData['amount'] as num?)?.toDouble() ?? 0.0;
    final description = messageData['message'] as String? ?? '';

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Navigate to Paystack payment screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaystackPaymentScreen(
          cartItems: [
            CartItem(
              id: messageId,
              name: 'Consultation Service',
              description: description,
              price: amount,
              quantity: 1,
              image: 'https://via.placeholder.com/150',
              timestamp: DateTime.now(),
            ),
          ],
          totalAmount: amount,
          userEmail: currentUser.email ?? '',
          userName: currentUser.displayName,
          userPhone: currentUser.phoneNumber,
          userId: currentUser.uid,
          paymentType: 'consultation_service',
        ),
      ),
    );

    // If payment was successful, update the message
    if (result == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('consultations')
            .doc(_consultationId)
            .collection('messages')
            .doc(messageId)
            .update({'paymentStatus': 'paid'});

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment successful!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating payment status: $e')),
          );
        }
      }
    }
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> messageData,
    bool isMe,
    String messageId,
  ) {
    final message = messageData['message'] as String? ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;
    final senderName = messageData['senderName'] as String? ?? 'Unknown';
    final senderType = messageData['senderType'] as String? ?? 'user';

    final isSystem = senderType == 'system';
    final isPaymentOffer = senderType == 'payment_offer';

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Payment offer bubble
    if (isPaymentOffer) {
      final amount = (messageData['amount'] as num?)?.toDouble() ?? 0.0;
      final paymentStatus =
          messageData['paymentStatus'] as String? ?? 'pending';

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B0000), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PAYMENT OFFER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                if (paymentStatus == 'paid')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PAID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Amount: ',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'R ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (paymentStatus != 'paid') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handlePayment(messageId, messageData),
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Sent ${_formatTimestamp(timestamp)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.black38,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF8B0000)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87),
                  fontSize: 15,
                ),
              ),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                child: Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.black38,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultation Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.serviceType[0].toUpperCase()}${widget.serviceType.substring(1)} Services',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Consultation Info'),
                  content: const Text(
                    'Chat with our team to discuss your project requirements, '
                    'get a custom quote, and plan your service delivery.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chat Messages
                Expanded(
                  child: _consultationId == null
                      ? const Center(
                          child: Text('Failed to initialize consultation'),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('consultations')
                              .doc(_consultationId)
                              .collection('messages')
                              .orderBy('timestamp', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final messages = snapshot.data!.docs;

                            if (messages.isEmpty) {
                              return const Center(
                                child: Text('No messages yet'),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final messageDoc = messages[index];
                                final messageData =
                                    messageDoc.data() as Map<String, dynamic>;
                                final senderId =
                                    messageData['senderId'] as String? ?? '';
                                final currentUserId =
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    '';
                                final isMe = senderId == currentUserId;

                                return _buildMessageBubble(
                                  messageData,
                                  isMe,
                                  messageDoc.id,
                                );
                              },
                            );
                          },
                        ),
                ),

                // Message Input
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B0000),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
