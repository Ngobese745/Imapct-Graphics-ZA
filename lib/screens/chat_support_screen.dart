import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/chat_cleanup_service.dart';
import '../services/enhanced_chatbot_service.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _waitingForHumanSupport = false;

  // Enhanced chatbot service
  final EnhancedChatbotService _enhancedChatbot = EnhancedChatbotService();

  // Comprehensive FAQ data covering all app features
  final List<FAQItem> _faqItems = [
    // Greetings and Common Responses
    FAQItem(
      question: "Greetings and Hello",
      answer:
          "Hello! 👋 I'm your AI assistant. I'm here to help you with any questions about our services, payments, orders, or general support. How can I assist you today?",
      keywords: [
        "hi",
        "hello",
        "hey",
        "good morning",
        "good afternoon",
        "good evening",
        "greetings",
        "what's up",
        "how are you",
      ],
    ),
    FAQItem(
      question: "Thanks and Appreciation",
      answer:
          "You're very welcome! 😊 I'm glad I could help. If you have any other questions or need further assistance, feel free to ask anytime!",
      keywords: [
        "thanks",
        "thank you",
        "appreciate",
        "grateful",
        "awesome",
        "great",
        "perfect",
        "excellent",
        "wonderful",
      ],
    ),
    FAQItem(
      question: "Goodbye and Farewell",
      answer:
          "Goodbye! 👋 It was great helping you today. Don't hesitate to come back if you need any assistance. Have a wonderful day!",
      keywords: [
        "bye",
        "goodbye",
        "see you",
        "farewell",
        "later",
        "take care",
        "have a good day",
        "talk soon",
      ],
    ),
    FAQItem(
      question: "Help and Support",
      answer:
          "I'm here to help! 😊 I can assist you with wallet management, placing orders, payment questions, tracking your projects, and much more. What would you like to know about?",
      keywords: [
        "help",
        "support",
        "assistance",
        "can you help",
        "need help",
        "stuck",
        "confused",
        "don't understand",
      ],
    ),
    FAQItem(
      question: "How are you and Status",
      answer:
          "I'm doing great, thank you for asking! 😊 I'm an AI assistant here to help you with all your Impact Graphics ZA needs. How are you doing today?",
      keywords: [
        "how are you",
        "how's it going",
        "what's up",
        "status",
        "doing well",
        "feeling",
        "everything okay",
      ],
    ),
    FAQItem(
      question: "What can you do",
      answer:
          "I can help you with many things! 💪 I can assist with wallet funding, placing orders, tracking your projects, explaining our services, helping with payments, and connecting you with human support when needed. What would you like to explore?",
      keywords: [
        "what can you do",
        "what do you know",
        "capabilities",
        "features",
        "services you offer",
        "what's available",
      ],
    ),
    FAQItem(
      question: "Who are you",
      answer:
          "I'm your AI assistant for Impact Graphics ZA! 🤖 I'm here to help you navigate our services, answer questions about your orders, assist with payments, and provide support. Think of me as your personal guide to our platform!",
      keywords: [
        "who are you",
        "what are you",
        "introduce yourself",
        "tell me about yourself",
        "your name",
        "ai assistant",
      ],
    ),
    // WALLET & PAYMENT SYSTEM
    FAQItem(
      question: "How do I add funds to my wallet?",
      answer:
          "You can add funds to your wallet by going to the Wallet section and tapping 'Add Funds'. You can use Paystack for secure payment processing with various payment methods including cards and bank transfers.",
      keywords: [
        "wallet",
        "funds",
        "add",
        "money",
        "payment",
        "paystack",
        "deposit",
        "load",
        "credit",
        "balance",
        "add money",
        "fund wallet",
      ],
    ),
    FAQItem(
      question: "Payment Methods Available",
      answer:
          "We accept multiple payment methods through Paystack: Credit/Debit cards (Visa, Mastercard), Bank transfers, Mobile money, and other local payment options. All transactions are secure and encrypted.",
      keywords: [
        "payment method",
        "card",
        "visa",
        "mastercard",
        "bank transfer",
        "mobile money",
        "paystack",
        "credit card",
        "debit card",
        "how to pay",
        "payment options",
      ],
    ),
    FAQItem(
      question: "Wallet Balance and Transactions",
      answer:
          "You can view your wallet balance and transaction history in the Wallet section. Your balance shows available funds for orders, and you can see all deposits, withdrawals, and payments made through the platform.",
      keywords: [
        "balance",
        "transaction",
        "history",
        "wallet balance",
        "check balance",
        "view transactions",
        "statement",
        "account balance",
      ],
    ),
    FAQItem(
      question: "Payment Issues and Troubleshooting",
      answer:
          "If you're experiencing payment issues, check your internet connection, ensure your card has sufficient funds, and try a different payment method. Contact support if problems persist - we'll help resolve any payment-related issues quickly.",
      keywords: [
        "payment failed",
        "payment error",
        "payment issue",
        "transaction failed",
        "card declined",
        "payment problem",
        "can't pay",
        "payment not working",
      ],
    ),
    FAQItem(
      question: "Refunds and Cancellations",
      answer:
          "Refunds are processed within 5-7 business days for cancelled orders or failed projects. You can request refunds through the order details or contact support. Refunds are credited back to your original payment method or wallet.",
      keywords: [
        "refund",
        "cancel",
        "cancellation",
        "get money back",
        "return payment",
        "refund policy",
        "cancel order",
        "reverse payment",
      ],
    ),
    // ORDERING & SERVICES
    FAQItem(
      question: "How do I place an order?",
      answer:
          "To place an order: 1) Go to Dashboard and select your desired service, 2) Fill in project details and requirements, 3) Set your budget, 4) Tap 'Pay Now' to complete. You'll receive confirmation and can track progress in your orders.",
      keywords: [
        "order",
        "place",
        "service",
        "booking",
        "create order",
        "new order",
        "place order",
        "order service",
        "book service",
        "make order",
        "submit order",
      ],
    ),
    FAQItem(
      question: "Available Services and Categories",
      answer:
          "We offer comprehensive graphic design services including: Logo Design, Brand Identity, Business Cards, Flyers, Social Media Graphics, Web Design, Print Materials, and Custom Graphics. Each service has different pricing tiers based on complexity and requirements.",
      keywords: [
        "services",
        "logo design",
        "brand identity",
        "business card",
        "flyer",
        "social media",
        "web design",
        "print",
        "graphics",
        "design services",
        "what services",
        "available services",
      ],
    ),
    FAQItem(
      question: "Order Tracking and Status",
      answer:
          "You can track your orders in the 'My Orders' section. Status updates include: Pending (payment processing), In Progress (design work), Review (awaiting your approval), and Completed (ready for download). You'll receive notifications at each stage.",
      keywords: [
        "track order",
        "order status",
        "order progress",
        "where is my order",
        "order tracking",
        "status update",
        "order update",
        "check order",
        "order history",
      ],
    ),
    FAQItem(
      question: "Order Modifications and Changes",
      answer:
          "You can request modifications within 24 hours of order completion. For major changes, additional fees may apply. Contact support or use the modification request feature in your order details. Minor revisions are often included at no extra cost.",
      keywords: [
        "modify order",
        "change order",
        "edit order",
        "revision",
        "modify design",
        "change design",
        "update order",
        "order changes",
        "request changes",
      ],
    ),
    FAQItem(
      question: "Order Delivery and Files",
      answer:
          "Completed orders are delivered through the platform where you can download high-quality files (PNG, JPG, PDF, AI, PSD formats). Files are available for download for 30 days. You'll receive email notifications when files are ready.",
      keywords: [
        "delivery",
        "download",
        "files",
        "order ready",
        "completed order",
        "get files",
        "download files",
        "file delivery",
        "order complete",
      ],
    ),
    FAQItem(
      question: "What payment methods do you accept?",
      answer:
          "We accept Paystack payments, wallet payments, and split payments (combining wallet and external payment). All payments are secure and encrypted.",
      keywords: ["payment", "paystack", "wallet", "split", "methods"],
    ),
    FAQItem(
      question: "How do I track my order status?",
      answer:
          "You can track your order status in the Updates section. You'll receive notifications when your order status changes.",
      keywords: ["track", "status", "order", "progress", "updates"],
    ),
    FAQItem(
      question: "What is the Gold Tier?",
      answer:
          "Gold Tier is our premium membership that offers 10% discount on all services, priority support, exclusive features, and double loyalty points. Upgrade anytime from your profile settings for enhanced benefits.",
      keywords: [
        "gold",
        "tier",
        "premium",
        "discount",
        "membership",
        "gold tier",
        "premium membership",
        "upgrade",
        "subscription",
        "premium features",
        "exclusive benefits",
      ],
    ),
    FAQItem(
      question: "How do I earn loyalty points?",
      answer:
          "You earn loyalty points by making purchases, referring friends, and completing certain actions. Points can be used for discounts and rewards.",
      keywords: ["loyalty", "points", "earn", "rewards", "discounts"],
    ),
    FAQItem(
      question: "How do I refer friends?",
      answer:
          "Go to the Referrals section and share your referral code. When someone uses your code, you both get exclusive discounts.",
      keywords: ["refer", "friends", "code", "share", "discount"],
    ),
    FAQItem(
      question: "What services do you offer?",
      answer:
          "We offer graphic design services including logos, business cards, posters, websites, and custom design solutions. Check our service catalog for more details.",
      keywords: ["services", "design", "logo", "website", "graphics"],
    ),
    FAQItem(
      question: "How long does order delivery take?",
      answer:
          "Delivery times vary by service type. Simple designs take 1-3 days, while complex projects may take 5-7 days. You'll get updates throughout the process.",
      keywords: ["delivery", "time", "duration", "when", "ready"],
    ),
    FAQItem(
      question: "Can I cancel my order?",
      answer:
          "Orders can be cancelled within 24 hours of placement. After that, cancellation depends on the project status. Contact support for assistance.",
      keywords: ["cancel", "refund", "change", "modify"],
    ),
    // Additional conversational responses
    FAQItem(
      question: "Yes and Confirmation",
      answer:
          "Great! 👍 I'm glad I could help clarify that for you. Is there anything specific you'd like to know more about or any other way I can assist you?",
      keywords: [
        "yes",
        "yeah",
        "yep",
        "sure",
        "okay",
        "ok",
        "alright",
        "correct",
        "right",
        "exactly",
      ],
    ),
    FAQItem(
      question: "No and Negation",
      answer:
          "No problem at all! 😊 I'm here whenever you need assistance. Feel free to ask me anything about our services, orders, payments, or any other questions you might have.",
      keywords: [
        "no",
        "nope",
        "nah",
        "not really",
        "don't think so",
        "incorrect",
        "wrong",
        "not sure",
      ],
    ),
    FAQItem(
      question: "I don't know",
      answer:
          "That's perfectly fine! 😊 We all have questions sometimes. I'm here to help you find the answers you need. What would you like to learn more about?",
      keywords: [
        "i don't know",
        "idk",
        "not sure",
        "confused",
        "unclear",
        "unsure",
        "don't understand",
      ],
    ),
    FAQItem(
      question: "Maybe and Uncertainty",
      answer:
          "I understand! 🤔 Sometimes it helps to explore your options. I can provide more information about our services, explain how things work, or connect you with human support if you'd like to discuss your specific situation.",
      keywords: [
        "maybe",
        "perhaps",
        "might",
        "could be",
        "possibly",
        "not certain",
        "thinking about it",
      ],
    ),
    FAQItem(
      question: "I need help",
      answer:
          "I'm here to help you! 😊 What specific area would you like assistance with? I can help with wallet management, placing orders, payment questions, tracking projects, or connect you with human support for more complex issues.",
      keywords: [
        "i need help",
        "help me",
        "assist me",
        "guide me",
        "support me",
        "stuck",
        "problem",
      ],
    ),
    // ACCOUNT & PROFILE MANAGEMENT
    FAQItem(
      question: "Account Settings and Profile",
      answer:
          "Manage your account in the Profile section. You can update your personal information, change password, manage notification preferences, view account history, and access security settings. Keep your information updated for better service.",
      keywords: [
        "account",
        "profile",
        "settings",
        "personal info",
        "change password",
        "update profile",
        "account settings",
        "user settings",
        "profile settings",
      ],
    ),
    FAQItem(
      question: "Notifications and Alerts",
      answer:
          "You can customize notifications in Settings. Receive alerts for order updates, payment confirmations, new messages, and promotional offers. Turn on/off specific notification types based on your preferences.",
      keywords: [
        "notifications",
        "alerts",
        "messages",
        "email notifications",
        "push notifications",
        "notification settings",
        "alerts settings",
        "turn off notifications",
      ],
    ),
    FAQItem(
      question: "Password and Security",
      answer:
          "Keep your account secure by using a strong password and enabling two-factor authentication if available. You can change your password anytime in Account Settings. Never share your login credentials with others.",
      keywords: [
        "password",
        "security",
        "login",
        "two factor",
        "authentication",
        "change password",
        "reset password",
        "forgot password",
        "secure account",
      ],
    ),
    // TECHNICAL SUPPORT
    FAQItem(
      question: "App Issues and Technical Problems",
      answer:
          "If you're experiencing app issues, try: 1) Restart the app, 2) Check your internet connection, 3) Update to the latest version, 4) Clear app cache. If problems persist, contact technical support with details about the issue.",
      keywords: [
        "app not working",
        "technical issue",
        "bug",
        "error",
        "app crashed",
        "slow app",
        "loading problem",
        "app freeze",
        "technical support",
        "app problem",
      ],
    ),
    FAQItem(
      question: "File Upload and Download Issues",
      answer:
          "For upload issues: Check file size limits, supported formats (JPG, PNG, PDF, AI, PSD), and internet connection. For download issues: Ensure sufficient storage space and stable connection. Contact support if files are corrupted or missing.",
      keywords: [
        "upload",
        "download",
        "file upload",
        "file download",
        "upload failed",
        "download failed",
        "file format",
        "file size",
        "corrupted file",
      ],
    ),
    // BUSINESS & COMPANY INFO
    FAQItem(
      question: "About Impact Graphics ZA",
      answer:
          "Impact Graphics ZA is a professional graphic design platform serving South Africa and beyond. We specialize in logo design, brand identity, marketing materials, and custom graphics. Our team of experienced designers delivers high-quality work with fast turnaround times.",
      keywords: [
        "about us",
        "company",
        "impact graphics",
        "who we are",
        "our company",
        "business info",
        "company information",
        "about the company",
      ],
    ),
    FAQItem(
      question: "Contact Information and Support Hours",
      answer:
          "You can contact us through the chat support, email, or phone. Our support team is available during business hours (Monday-Friday, 9 AM - 5 PM SAST). For urgent issues, use the emergency contact option in the app.",
      keywords: [
        "contact",
        "support hours",
        "business hours",
        "phone number",
        "email",
        "contact us",
        "customer service",
        "support team",
        "emergency contact",
      ],
    ),
    FAQItem(
      question: "Privacy and Data Protection",
      answer:
          "We take privacy seriously and comply with data protection regulations. Your personal information and project details are encrypted and secure. We don't share your data with third parties without consent. Read our privacy policy for details.",
      keywords: [
        "privacy",
        "data protection",
        "personal data",
        "security",
        "privacy policy",
        "data security",
        "information protection",
        "confidentiality",
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _listenForAdminMessages();
  }

  void _initializeChat() {
    // Get personalized greeting from enhanced chatbot
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'guest';

    final personalizedGreeting = _enhancedChatbot.getPersonalizedGreeting(
      userId,
    );

    // Add personalized welcome message
    _messages.add(
      ChatMessage(
        text: personalizedGreeting,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.bot,
        quickActions: ['Speak with a human agent'],
      ),
    );

    // Add smart suggestions based on user context
    final smartSuggestions = _enhancedChatbot.getSmartSuggestions(userId);

    _messages.add(
      ChatMessage(
        text: "Here are some things I can help you with:",
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.quickActions,
        quickActions: smartSuggestions,
      ),
    );
  }

  void _listenForAdminMessages() {
    // Listen for support requests for this user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // print('=== LISTENING FOR ADMIN MESSAGES ===');
    // print('User ID: ${currentUser.uid}');

    FirebaseFirestore.instance
        .collection('support_requests')
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', whereIn: ['pending', 'in_progress'])
        .snapshots()
        .listen((supportRequestsSnapshot) {
          // print(
          //            'Support requests found: ${supportRequestsSnapshot.docs.length}',
          //          );

          for (final supportRequestDoc in supportRequestsSnapshot.docs) {
            final supportRequestId = supportRequestDoc.id;
            // print('Listening to support request: $supportRequestId');

            // Listen for messages in this support request's chat
            FirebaseFirestore.instance
                .collection('support_chats')
                .doc(supportRequestId)
                .collection('messages')
                .orderBy('timestamp', descending: false)
                .snapshots()
                .listen((messageSnapshot) {
                  // print('Messages received: ${messageSnapshot.docs.length}');

                  for (final messageDoc in messageSnapshot.docs) {
                    final messageData = messageDoc.data();
                    final isFromAdmin = messageData['isFromAdmin'] ?? false;
                    final messageText = messageData['message'] ?? '';
                    final senderName = messageData['senderName'] ?? 'Admin';

                    // print(
                    //                      'Message from admin: $isFromAdmin, Text: $messageText, Sender: $senderName',
                    //                    );

                    if (isFromAdmin) {
                      // Check if this message is already in our local list
                      final messageExists = _messages.any(
                        (msg) =>
                            msg.text == messageText &&
                            msg.adminName == senderName,
                      );

                      // print('Message exists in local list: $messageExists');

                      if (!messageExists) {
                        // print('Adding admin message to chat');
                        _addBotMessage(
                          messageText,
                          isAdminMessage: true,
                          adminName: senderName,
                        );
                      }
                    }
                  }
                });
          }
        });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      messageType: MessageType.user,
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Save user message to chat history
    _saveUserMessageToHistory(userMessage);

    // If human support is active, save message to support chat immediately
    if (_waitingForHumanSupport) {
      _saveUserMessageToSupportChat(text.trim());
      setState(() {
        _isTyping = false;
      });
      return;
    }

    // Simulate typing delay for automated responses
    Future.delayed(const Duration(seconds: 1), () {
      _processMessage(text.trim());
    });
  }

  Future<void> _saveUserMessageToHistory(ChatMessage message) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Save user message to chat history
      await FirebaseFirestore.instance
          .collection('user_chat_history')
          .doc(currentUser.uid)
          .collection('conversations')
          .add({
            'message': message.text,
            'isUser': true,
            'isAdmin': false,
            'senderName': currentUser.displayName ?? 'User',
            'timestamp': FieldValue.serverTimestamp(),
            'supportRequestId': _getCurrentSupportRequestId(),
            'messageType': message.messageType.name,
          });
    } catch (e) {
      // print('Error saving user message to history: $e');
    }
  }

  void _processMessage(String userMessage) {
    setState(() {
      _isTyping = false;
    });

    // Check for human support request
    if (_shouldRequestHumanSupport(userMessage)) {
      _handleHumanSupportRequest(userMessage);
      return;
    }

    // If human support is active, don't send automated responses
    if (_waitingForHumanSupport) {
      // Just save the user message to the support chat for the admin to see
      _saveUserMessageToSupportChat(userMessage);
      return;
    }

    // Use enhanced chatbot service for intelligent responses
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'guest';

    final enhancedResponse = _enhancedChatbot.processMessage(
      userMessage,
      userId,
    );

    _addBotMessage(enhancedResponse);

    // Add follow-up suggestions if not human support
    if (!enhancedResponse.toLowerCase().contains('human') &&
        !enhancedResponse.toLowerCase().contains('agent')) {
      // Get smart follow-up suggestions
      final followUpSuggestions = _enhancedChatbot.getSmartSuggestions(userId);

      if (followUpSuggestions.isNotEmpty) {
        _addBotMessage(
          "Here are some related things you might want to explore:",
          quickActions: followUpSuggestions.take(4).toList(),
        );
      }
    }
  }

  bool _shouldRequestHumanSupport(String message) {
    final humanSupportKeywords = [
      "human",
      "agent",
      "person",
      "speak to",
      "talk to",
      "complex",
      "complicated",
      "urgent",
      "emergency",
      "complaint",
      "issue",
      "problem",
      "not working",
      "error",
      "bug",
      "technical",
    ];

    final lowerMessage = message.toLowerCase();
    return humanSupportKeywords.any(
      (keyword) => lowerMessage.contains(keyword),
    );
  }

  void _handleHumanSupportRequest(String message) {
    _addBotMessage(
      "I understand you'd like to speak with a human agent. Let me connect you with our support team.",
    );

    setState(() {
      _waitingForHumanSupport = true;
    });

    // Send notification to admin about human support request
    _sendHumanSupportNotification(message);

    _addBotMessage(
      "I've notified our support team about your request. A human agent will be with you shortly. Please wait for their response.",
    );
  }

  Future<void> _saveUserMessageToSupportChat(String userMessage) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Find the support request for this user
      final supportRequestsSnapshot = await FirebaseFirestore.instance
          .collection('support_requests')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['pending', 'in_progress'])
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (supportRequestsSnapshot.docs.isNotEmpty) {
        final supportRequestId = supportRequestsSnapshot.docs.first.id;

        // Save user message to the support chat
        await FirebaseFirestore.instance
            .collection('support_chats')
            .doc(supportRequestId)
            .collection('messages')
            .add({
              'message': userMessage,
              'isFromAdmin': false,
              'senderId': currentUser.uid,
              'senderName': currentUser.displayName ?? 'User',
              'timestamp': FieldValue.serverTimestamp(),
              'supportRequestId': supportRequestId,
              'userId': currentUser.uid,
            });

        // Update support request last activity
        await FirebaseFirestore.instance
            .collection('support_requests')
            .doc(supportRequestId)
            .update({
              'lastMessageAt': FieldValue.serverTimestamp(),
              'lastMessageBy': currentUser.uid,
              'lastUserActivity':
                  FieldValue.serverTimestamp(), // Track user activity
              'hasUnreadMessages': true, // Admin has unread messages
            });

        // Also update user activity in cleanup service
        ChatCleanupService.updateUserActivity(supportRequestId);
      }
    } catch (e) {
      // print('Error saving user message to support chat: $e');
    }
  }

  Future<void> _sendHumanSupportNotification(String userMessage) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Create support request in Firestore
      final supportRequestRef = await FirebaseFirestore.instance
          .collection('support_requests')
          .add({
            'userId': currentUser.uid,
            'userEmail': currentUser.email,
            'userName': currentUser.displayName ?? 'Unknown User',
            'message': userMessage,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
            'priority': 'normal',
            'assignedTo': null,
            'lastUserActivity':
                FieldValue.serverTimestamp(), // Track user activity
            'lastMessageAt': FieldValue.serverTimestamp(),
            'lastMessageBy': currentUser.uid,
            'hasUnreadMessages': true,
          });

      // Also save the initial message to the support chat
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(supportRequestRef.id)
          .collection('messages')
          .add({
            'message': userMessage,
            'isFromAdmin': false,
            'senderId': currentUser.uid,
            'senderName': currentUser.displayName ?? 'User',
            'timestamp': FieldValue.serverTimestamp(),
            'supportRequestId': supportRequestRef.id,
            'userId': currentUser.uid,
          });

      // Send notification to admin
      await NotificationService.sendAdminNotification(
        title: 'Human Support Request',
        body: '${currentUser.displayName ?? 'User'} requested human support',
        action: 'support_request',
        data: {'userId': currentUser.uid, 'message': userMessage},
      );

      // Send confirmation to user
      await NotificationService.sendNotificationToUser(
        userId: currentUser.uid,
        title: 'Support Request Submitted',
        body: 'Your request has been sent to our support team',
        type: 'support',
        action: 'support_requested',
      );
    } catch (e) {
      // print('Error sending support notification: $e');
    }
  }

  // Advanced text preprocessing for understanding various writing styles
  String _preprocessText(String text) {
    // Remove extra whitespace and normalize
    String processed = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Fix common typos and misspellings
    processed = _fixCommonTypos(processed);

    // Expand contractions and slang
    processed = _expandContractions(processed);

    // Fix broken English patterns
    processed = _fixBrokenEnglish(processed);

    return processed;
  }

  // Fix common typos and misspellings
  String _fixCommonTypos(String text) {
    final typoMap = {
      'recieve': 'receive',
      'seperate': 'separate',
      'occured': 'occurred',
      'definately': 'definitely',
      'accomodate': 'accommodate',
      'begining': 'beginning',
      'calender': 'calendar',
      'cemetary': 'cemetery',
      'embarass': 'embarrass',
      'existance': 'existence',
      'goverment': 'government',
      'independant': 'independent',
      'occurence': 'occurrence',
      'recomend': 'recommend',
      'thier': 'their',
      'untill': 'until',
      'writting': 'writing',
      'paymnt': 'payment',
      'ordr': 'order',
      'servis': 'service',
      'balnce': 'balance',
      'wallett': 'wallet',
      'acount': 'account',
      'problm': 'problem',
      'quesion': 'question',
      'helpp': 'help',
      'spport': 'support',
      'complain': 'complaint',
      'urgnt': 'urgent',
      'emergncy': 'emergency',
    };

    String fixed = text.toLowerCase();
    typoMap.forEach((typo, correct) {
      fixed = fixed.replaceAll(typo, correct);
    });

    return fixed;
  }

  // Expand contractions and informal language
  String _expandContractions(String text) {
    final contractionMap = {
      "i'm": "i am",
      "you're": "you are",
      "he's": "he is",
      "she's": "she is",
      "it's": "it is",
      "we're": "we are",
      "they're": "they are",
      "i've": "i have",
      "you've": "you have",
      "we've": "we have",
      "they've": "they have",
      "i'd": "i would",
      "you'd": "you would",
      "he'd": "he would",
      "she'd": "she would",
      "we'd": "we would",
      "they'd": "they would",
      "i'll": "i will",
      "you'll": "you will",
      "he'll": "he will",
      "she'll": "she will",
      "we'll": "we will",
      "they'll": "they will",
      "isn't": "is not",
      "aren't": "are not",
      "wasn't": "was not",
      "weren't": "were not",
      "don't": "do not",
      "doesn't": "does not",
      "didn't": "did not",
      "won't": "will not",
      "can't": "cannot",
      "couldn't": "could not",
      "shouldn't": "should not",
      "wouldn't": "would not",
      "haven't": "have not",
      "hasn't": "has not",
      "hadn't": "had not",
      "mustn't": "must not",
      "needn't": "need not",
      "gonna": "going to",
      "wanna": "want to",
      "gotta": "got to",
      "lemme": "let me",
      "gimme": "give me",
      "dunno": "do not know",
      "kinda": "kind of",
      "sorta": "sort of",
      "lotsa": "lots of",
      "oughta": "ought to",
      "shoulda": "should have",
      "woulda": "would have",
      "coulda": "could have",
      "mighta": "might have",
      "musta": "must have",
    };

    String expanded = text.toLowerCase();
    contractionMap.forEach((contraction, expandedForm) {
      expanded = expanded.replaceAll(
        RegExp(r'\b' + contraction + r'\b'),
        expandedForm,
      );
    });

    return expanded;
  }

  // Fix broken English patterns
  String _fixBrokenEnglish(String text) {
    String fixed = text.toLowerCase();

    // Fix common broken English patterns
    final brokenPatterns = {
      'i want to know': 'how do i',
      'i need help with': 'help with',
      'can you tell me about': 'tell me about',
      'i dont understand': 'i do not understand',
      'pls': 'please',
      'plz': 'please',
      'thx': 'thanks',
      'ty': 'thank you',
      'ur': 'your',
      'u': 'you',
      'r': 'are',
      'n': 'and',
      'b': 'be',
      'c': 'see',
      '2': 'to',
      '4': 'for',
      'b4': 'before',
      'l8r': 'later',
      'gr8': 'great',
      'luv': 'love',
      'nite': 'night',
      'thru': 'through',
      'tho': 'though',
      'coz': 'because',
      'cos': 'because',
      'cuz': 'because',
      'k': 'okay',
      'kk': 'okay',
      'ok': 'okay',
      'yep': 'yes',
      'yea': 'yes',
      'nah': 'no',
      'nope': 'no',
      'sure': 'yes',
      'yup': 'yes',
    };

    brokenPatterns.forEach((broken, correct) {
      fixed = fixed.replaceAll(RegExp(r'\b' + broken + r'\b'), correct);
    });

    return fixed;
  }

  // Normalize text for better matching
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  // Tokenize and normalize text into words
  List<String> _tokenizeAndNormalize(String text) {
    return text
        .split(RegExp(r'[\s,.-]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => _normalizeText(word))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  // Fuzzy string matching using Levenshtein distance
  double _fuzzyMatch(String s1, String s2, double threshold) {
    if (s1 == s2) return 1.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    if (maxLength == 0) return 1.0;

    final similarity = 1.0 - (distance / maxLength);
    return similarity >= threshold ? similarity : 0.0;
  }

  // Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.length < s2.length) {
      return _levenshteinDistance(s2, s1);
    }

    if (s2.isEmpty) return s1.length;

    List<int> previousRow = List.generate(s2.length + 1, (index) => index);

    for (int i = 0; i < s1.length; i++) {
      List<int> currentRow = [i + 1];

      for (int j = 0; j < s2.length; j++) {
        int insertions = previousRow[j + 1] + 1;
        int deletions = currentRow[j] + 1;
        int substitutions = previousRow[j] + (s1[i] != s2[j] ? 1 : 0);

        currentRow.add(
          [
            insertions,
            deletions,
            substitutions,
          ].reduce((a, b) => a < b ? a : b),
        );
      }

      previousRow = currentRow;
    }

    return previousRow.last;
  }

  // Get contextual suggestions based on user message content
  String _getContextualSuggestion(String userMessage) {
    final processedMessage = _preprocessText(userMessage);
    final messageWords = _tokenizeAndNormalize(processedMessage.toLowerCase());

    // Check for different types of queries and provide relevant suggestions
    if (_containsAny(messageWords, [
      'payment',
      'pay',
      'money',
      'fund',
      'wallet',
      'balance',
      'cost',
      'price',
    ])) {
      return "💳 I can help you with payment-related questions! You can ask about:\n• How to add funds to your wallet\n• Payment methods we accept\n• Checking your account balance\n• Understanding charges and fees";
    }

    if (_containsAny(messageWords, [
      'order',
      'track',
      'status',
      'delivery',
      'progress',
      'purchase',
    ])) {
      return "📦 I can help you with order-related questions! You can ask about:\n• How to track your order\n• Order status updates\n• Delivery timelines\n• Order history and details";
    }

    if (_containsAny(messageWords, [
      'account',
      'profile',
      'login',
      'user',
      'sign',
    ])) {
      return "👤 I can help you with account-related questions! You can ask about:\n• Managing your profile\n• Account settings\n• Login issues\n• Account security";
    }

    if (_containsAny(messageWords, [
      'service',
      'help',
      'support',
      'assistance',
      'guide',
    ])) {
      return "🛠️ I can help you with service-related questions! You can ask about:\n• Our available services\n• How to use specific features\n• Getting help with orders\n• Service pricing and details";
    }

    if (_containsAny(messageWords, [
      'problem',
      'issue',
      'trouble',
      'error',
      'bug',
      'not working',
      'broken',
    ])) {
      return "🔧 I can help you with technical issues! You can ask about:\n• App problems and errors\n• Service issues\n• Troubleshooting steps\n• Getting technical support";
    }

    if (_containsAny(messageWords, [
      'urgent',
      'emergency',
      'quick',
      'fast',
      'asap',
      'immediately',
    ])) {
      return "⚡ For urgent matters, I recommend speaking with a human agent who can provide immediate assistance!";
    }

    // Default suggestion for unclear queries
    return "💡 Here are some popular topics I can help with:\n• Payment and wallet management\n• Order tracking and status\n• Account settings and profile\n• Service information and pricing\n• Technical support and troubleshooting";
  }

  // Helper method to check if any words in the list are contained in message words
  bool _containsAny(List<String> messageWords, List<String> keywords) {
    return keywords.any(
      (keyword) => messageWords.any(
        (word) =>
            word == keyword ||
            (_fuzzyMatch(word, keyword, 0.8) > 0) ||
            word.contains(keyword) ||
            keyword.contains(word),
      ),
    );
  }

  // Enhanced keyword matching with synonyms and variations
  Map<String, List<String>> _getKeywordVariations(String keyword) {
    final variations = <String, List<String>>{};

    // Common synonyms and variations
    final synonymMap = {
      'help': ['assist', 'support', 'aid', 'guide', 'show'],
      'payment': [
        'pay',
        'money',
        'fund',
        'wallet',
        'balance',
        'cost',
        'price',
        'fee',
      ],
      'order': ['purchase', 'buy', 'request', 'booking'],
      'track': ['follow', 'monitor', 'check', 'status', 'progress'],
      'problem': ['issue', 'trouble', 'difficulty', 'error', 'bug'],
      'service': ['help', 'support', 'assistance'],
      'account': ['profile', 'user', 'login'],
      'balance': ['funds', 'money', 'wallet'],
      'urgent': ['emergency', 'quick', 'fast', 'asap'],
      'complaint': ['problem', 'issue', 'concern', 'feedback'],
      'question': ['query', 'ask', 'wonder', 'inquiry'],
      'how': ['what', 'where', 'when', 'why'],
      'where': ['how', 'what', 'when'],
      'when': ['how', 'what', 'where'],
      'what': ['how', 'where', 'when'],
      'why': ['how', 'what', 'reason'],
      'hello': ['hi', 'hey', 'greetings', 'good morning', 'good afternoon'],
      'thanks': ['thank you', 'appreciate', 'grateful'],
      'goodbye': ['bye', 'farewell', 'see you', 'later'],
    };

    final normalizedKeyword = _normalizeText(keyword);
    final synonyms = synonymMap[normalizedKeyword] ?? [];

    variations[normalizedKeyword] = [normalizedKeyword, ...synonyms];

    return variations;
  }

  FAQItem? _findBestFAQMatch(String message) {
    // Advanced text preprocessing for better understanding
    final preprocessedMessage = _preprocessText(message);
    final lowerMessage = preprocessedMessage.toLowerCase().trim();
    FAQItem? bestMatch;
    int bestScore = 0;

    // Handle very short messages with exact matches
    if (lowerMessage.length <= 10) {
      for (final faq in _faqItems) {
        for (final keyword in faq.keywords) {
          final normalizedKeyword = _normalizeText(keyword.toLowerCase());
          if (lowerMessage == normalizedKeyword ||
              (_fuzzyMatch(lowerMessage, normalizedKeyword, 0.8) > 0)) {
            return faq; // Exact match or fuzzy match for short messages
          }
        }
      }
    }

    // Split message into words for better matching with normalization
    final messageWords = _tokenizeAndNormalize(lowerMessage);

    for (final faq in _faqItems) {
      int score = 0;

      // Enhanced keyword matching with preprocessing and fuzzy matching
      for (final keyword in faq.keywords) {
        final normalizedKeyword = _normalizeText(keyword.toLowerCase());
        final keywordVariations = _getKeywordVariations(normalizedKeyword);

        // Check all variations of the keyword
        for (final variation in keywordVariations.values.expand((v) => v)) {
          final variationWords = _tokenizeAndNormalize(variation);

          // Exact phrase match gets highest score
          if (lowerMessage == variation) {
            score += 5;
          }
          // Fuzzy phrase match gets high score
          else if (_fuzzyMatch(lowerMessage, variation, 0.8) > 0) {
            score += 4;
          }
          // Partial phrase match gets medium-high score
          else if (lowerMessage.contains(variation)) {
            score += 3;
          }
          // Individual word matches with fuzzy matching
          else {
            for (final keywordWord in variationWords) {
              if (keywordWord.length > 2) {
                for (final messageWord in messageWords) {
                  if (messageWord == keywordWord) {
                    score += 2;
                  } else if (_fuzzyMatch(messageWord, keywordWord, 0.7) > 0) {
                    score += 1;
                  } else if (messageWord.contains(keywordWord) ||
                      keywordWord.contains(messageWord)) {
                    score += 1;
                  }
                }
              }
            }
          }
        }
      }

      // Check if the message contains parts of the question
      final questionWords = faq.question.toLowerCase().split(
        RegExp(r'[\s,.-]+'),
      );
      for (final questionWord in questionWords) {
        if (questionWord.length > 3) {
          for (final messageWord in messageWords) {
            if (messageWord.contains(questionWord) ||
                questionWord.contains(messageWord)) {
              score += 1;
            }
          }
        }
      }

      // Context-based scoring boosts
      if (lowerMessage.length <= 15 && faq.question.contains("Greetings")) {
        score += 2;
      }

      // Boost for payment-related queries
      if (messageWords.any(
            (word) => [
              'payment',
              'pay',
              'money',
              'fund',
              'wallet',
              'cost',
              'price',
            ].contains(word),
          ) &&
          faq.keywords.any(
            (keyword) =>
                keyword.toLowerCase().contains('payment') ||
                keyword.toLowerCase().contains('wallet'),
          )) {
        score += 2;
      }

      // Boost for order-related queries
      if (messageWords.any(
            (word) => [
              'order',
              'track',
              'status',
              'delivery',
              'progress',
            ].contains(word),
          ) &&
          faq.keywords.any(
            (keyword) =>
                keyword.toLowerCase().contains('order') ||
                keyword.toLowerCase().contains('track'),
          )) {
        score += 2;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = faq;
      }
    }

    // Only return a match if the score is significant enough
    return bestScore >= 2 ? bestMatch : null;
  }

  void _addBotMessage(
    String text, {
    List<String>? quickActions,
    bool isAdminMessage = false,
    String adminName = '',
    bool includeHumanSupportButton = true,
  }) {
    // Create quick actions list with Human Support button
    List<String>? finalQuickActions = quickActions;

    // Add Human Support button to all bot responses (except admin messages)
    if (!isAdminMessage &&
        includeHumanSupportButton &&
        !_waitingForHumanSupport) {
      finalQuickActions ??= [];
      // Add Human Support button if not already present
      if (!finalQuickActions.any(
        (action) => action.toLowerCase().contains('human'),
      )) {
        finalQuickActions.add('Speak with a human agent');
      }
    }

    final message = ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      messageType: isAdminMessage ? MessageType.admin : MessageType.bot,
      quickActions: finalQuickActions,
      adminName: isAdminMessage ? adminName : null,
    );

    setState(() {
      _messages.add(message);
    });

    // Save bot message to Firestore for admin visibility
    _saveBotMessageToHistory(message);

    _scrollToBottom();
  }

  Future<void> _saveBotMessageToHistory(ChatMessage message) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Save bot message to user chat history
      await FirebaseFirestore.instance
          .collection('user_chat_history')
          .doc(currentUser.uid)
          .collection('conversations')
          .add({
            'message': message.text,
            'isUser': false,
            'isAdmin': false,
            'senderName': 'Bot',
            'timestamp': FieldValue.serverTimestamp(),
            'supportRequestId': _getCurrentSupportRequestId(),
            'messageType': message.messageType.name,
            'quickActions': message.quickActions,
          });
    } catch (e) {
      // print('Error saving bot message to history: $e');
    }
  }

  String? _getCurrentSupportRequestId() {
    // Get the current support request ID if human support is active
    if (_waitingForHumanSupport) {
      // This would be set when human support is requested
      // For now, return null as we'll handle this in the human support request
      return null;
    }
    return null;
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
        title: const Text(
          'Chat Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_waitingForHumanSupport)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Human Support Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
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
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
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
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF8B0000),
                shape: BoxShape.circle,
              ),
              child: message.messageType == MessageType.admin
                  ? const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 18,
                    )
                  : const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF8B0000)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
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
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  if (message.quickActions != null) ...[
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.quickActions!.map((action) {
                        return GestureDetector(
                          onTap: () => _sendMessage(action),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.yellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: message.isUser
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.yellow.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              action,
                              style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.yellow,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.adminName != null) ...[
                        Text(
                          message.adminName!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(
                20,
              ).copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Typing...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;
  final List<String>? quickActions;
  final String? adminName;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
    this.quickActions,
    this.adminName,
  });
}

enum MessageType { user, bot, quickActions, admin }

class FAQItem {
  final String question;
  final String answer;
  final List<String> keywords;

  FAQItem({
    required this.question,
    required this.answer,
    required this.keywords,
  });
}
