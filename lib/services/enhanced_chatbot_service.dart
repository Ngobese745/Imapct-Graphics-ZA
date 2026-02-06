import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced AI Chatbot Service with Smart Context Awareness
/// Features: Natural Language Processing, Context Memory, Feature Knowledge
class EnhancedChatbotService {
  static final EnhancedChatbotService _instance =
      EnhancedChatbotService._internal();
  factory EnhancedChatbotService() => _instance;
  EnhancedChatbotService._internal();

  // Context memory for conversation continuity
  final Map<String, List<String>> _conversationContext = {};
  final Map<String, String> _userPreferences = {};
  final Map<String, DateTime> _lastInteraction = {};

  // Enhanced personality traits
  static const List<String> _friendlyGreetings = [
    "Hello there! 👋 I'm your friendly AI assistant!",
    "Hi! 😊 Great to see you! How can I help you today?",
    "Hey! 🌟 Welcome back! What can I assist you with?",
    "Hello! ✨ I'm here and ready to help you with anything!",
    "Hi there! 🎉 Let's make your day better together!",
  ];

  static const List<String> _encouragingResponses = [
    "That's a great question! 💡",
    "I love helping with that! 🚀",
    "Absolutely! I'm here for you! 💪",
    "Perfect! Let me help you with that! ⭐",
    "Excellent choice! 🎯",
    "Wonderful! I can definitely help! 🌟",
  ];

  static const List<String> _empathyExpressions = [
    "I understand how that can be frustrating. Let me help! 😊",
    "That sounds challenging, but we'll figure it out together! 💪",
    "I'm here to make things easier for you! 🤗",
    "Don't worry, I've got your back! 🛡️",
    "Let's solve this step by step! 🧩",
  ];

  /// Get personalized greeting based on user context
  String getPersonalizedGreeting(String userId) {
    final now = DateTime.now();
    final lastInteraction = _lastInteraction[userId];

    // Update last interaction
    _lastInteraction[userId] = now;

    // Time-based greetings
    final hour = now.hour;
    String timeGreeting = "";
    if (hour < 12) {
      timeGreeting = "Good morning";
    } else if (hour < 17) {
      timeGreeting = "Good afternoon";
    } else {
      timeGreeting = "Good evening";
    }

    // Check if returning user
    if (lastInteraction != null) {
      final daysSinceLastVisit = now.difference(lastInteraction).inDays;
      if (daysSinceLastVisit > 0) {
        return "$timeGreeting! 🌟 Welcome back! I've missed our conversations. How can I help you today?";
      }
    }

    // Random friendly greeting
    final random = Random();
    return "$timeGreeting! ${_friendlyGreetings[random.nextInt(_friendlyGreetings.length)]}";
  }

  /// Enhanced FAQ with comprehensive app knowledge
  List<EnhancedFAQItem> getEnhancedFAQ() {
    return [
      // GREETINGS & PERSONALITY
      EnhancedFAQItem(
        question: "Greetings and Hello",
        answer:
            "Hello! 👋 I'm your smart AI assistant for Impact Graphics ZA! I'm here to help you with everything from wallet management to rewards, orders, and all our amazing features. How can I make your day better?",
        keywords: [
          "hi",
          "hello",
          "hey",
          "good morning",
          "good afternoon",
          "good evening",
          "greetings",
        ],
        context: ["greeting", "introduction"],
        followUpQuestions: [
          "What can you help me with?",
          "Tell me about your features",
          "How do I get started?",
        ],
      ),

      // WALLET & PAYMENTS (Enhanced)
      EnhancedFAQItem(
        question: "Smart Wallet Features",
        answer:
            "Your wallet is super smart! 💳 You can add funds instantly with Paystack, track all transactions in real-time, and use it for any service. Plus, you earn rewards that go straight to your wallet! Want to add some funds or check your balance?",
        keywords: [
          "wallet",
          "funds",
          "balance",
          "add money",
          "paystack",
          "payment",
          "transactions",
        ],
        context: ["wallet", "payment"],
        followUpQuestions: [
          "How do I add funds?",
          "Check my balance",
          "View transaction history",
          "How do rewards work?",
        ],
      ),

      // NEW REWARDS SYSTEM (Comprehensive)
      EnhancedFAQItem(
        question: "Amazing Rewards System",
        answer:
            "Our rewards are incredible! 🎁 You can earn in 3 ways: 1) Watch 100 ads = R10 reward 💰 2) Refer 20 friends = R10 reward 👥 3) Earn 2000 loyalty points = R500 wallet credit! 🏆 All rewards go to your wallet for services only. Ready to start earning?",
        keywords: [
          "rewards",
          "ads",
          "referral",
          "loyalty",
          "points",
          "earn money",
          "R10",
          "R500",
          "watch ads",
        ],
        context: ["rewards", "earnings"],
        followUpQuestions: [
          "How do I watch ads for rewards?",
          "How do referrals work?",
          "What are loyalty points?",
          "Check my rewards progress",
        ],
      ),

      EnhancedFAQItem(
        question: "Ad Rewards Program",
        answer:
            "Watch ads and earn money! 📱 Simply watch 100 ads and get R10 credited to your wallet automatically! You can track your progress in the Rewards section. The more ads you watch, the more you earn! 💰",
        keywords: [
          "ads",
          "watch ads",
          "ad rewards",
          "100 ads",
          "R10",
          "earn from ads",
          "banner ads",
        ],
        context: ["rewards", "ads"],
        followUpQuestions: [
          "How many ads have I watched?",
          "Where do I watch ads?",
          "When do I get paid?",
        ],
      ),

      EnhancedFAQItem(
        question: "Referral Rewards Program",
        answer:
            "Invite friends and earn together! 🤝 For every 20 friends who join, you get R10! When you reach R100 in referral earnings, it's automatically added to your wallet for services. Share your referral code and start earning! 💵",
        keywords: [
          "referral",
          "invite friends",
          "referral code",
          "20 referrals",
          "R100",
          "share",
          "invite",
        ],
        context: ["rewards", "referrals"],
        followUpQuestions: [
          "How do I share my referral code?",
          "How many referrals do I have?",
          "When do I get paid?",
        ],
      ),

      EnhancedFAQItem(
        question: "Loyalty Points System",
        answer:
            "Earn loyalty points with every purchase! ⭐ Collect 2000 points and get R500 credited directly to your wallet! Your points reset after claiming the reward. Check your progress anytime in the Rewards section! 🎯",
        keywords: [
          "loyalty",
          "points",
          "2000 points",
          "R500",
          "loyalty reward",
          "earn points",
        ],
        context: ["rewards", "loyalty"],
        followUpQuestions: [
          "How many loyalty points do I have?",
          "How do I earn more points?",
          "When can I claim my reward?",
        ],
      ),

      // ORDER MANAGEMENT (Enhanced)
      EnhancedFAQItem(
        question: "Smart Order Management",
        answer:
            "Ordering is super easy! 🛒 Browse our services, add to cart, and pay with your wallet or Paystack. Track everything in real-time, get instant notifications, and download your files when ready. Plus, you earn loyalty points on every order! 📦",
        keywords: [
          "order",
          "place order",
          "services",
          "track order",
          "order status",
          "cart",
          "checkout",
        ],
        context: ["orders", "services"],
        followUpQuestions: [
          "How do I place an order?",
          "Check my order status",
          "What services are available?",
          "How do I track my order?",
        ],
      ),

      // SERVICES (Comprehensive)
      EnhancedFAQItem(
        question: "Our Amazing Services",
        answer:
            "We offer premium graphic design services! 🎨 Logo Design (R299+), Brand Identity (R899+), Business Cards, Flyers, Social Media Graphics, Web Design, and more! Each service earns you loyalty points and comes with unlimited revisions. What catches your eye? ✨",
        keywords: [
          "services",
          "logo design",
          "brand identity",
          "business card",
          "flyer",
          "social media",
          "web design",
          "graphics",
        ],
        context: ["services", "design"],
        followUpQuestions: [
          "Show me logo design",
          "What's brand identity?",
          "How much does it cost?",
          "Book a consultation",
        ],
      ),

      // CONSULTATION (New Feature)
      EnhancedFAQItem(
        question: "Free Design Consultation",
        answer:
            "Get expert advice for free! 💬 Our design consultation helps you plan your project perfectly. Discuss your vision, get professional recommendations, and understand the process before ordering. It's completely free and no commitment required! 🎯",
        keywords: [
          "consultation",
          "free consultation",
          "design advice",
          "expert advice",
          "plan project",
          "discuss design",
        ],
        context: ["consultation", "support"],
        followUpQuestions: [
          "Book a consultation",
          "How does consultation work?",
          "Is it really free?",
          "What can I discuss?",
        ],
      ),

      // GUEST FEATURES (New)
      EnhancedFAQItem(
        question: "Guest User Benefits",
        answer:
            "Even as a guest, you can explore amazing features! 👀 View our portfolio, browse services, and learn about our rewards system. Create an account to unlock wallet, orders, rewards tracking, and exclusive features. Ready to join our community? 🚀",
        keywords: [
          "guest",
          "limited access",
          "create account",
          "sign up",
          "register",
          "join",
          "benefits",
        ],
        context: ["guest", "account"],
        followUpQuestions: [
          "How do I create an account?",
          "What can guests do?",
          "Why should I join?",
          "What features do I get?",
        ],
      ),

      // NOTIFICATIONS & UPDATES (Enhanced)
      EnhancedFAQItem(
        question: "Smart Notifications",
        answer:
            "Stay updated with everything! 🔔 Get real-time notifications for orders, payments, rewards, and important updates. Customize what you want to hear about in settings. Never miss a reward opportunity or order update! 📱",
        keywords: [
          "notifications",
          "updates",
          "alerts",
          "messages",
          "notify",
          "reminders",
        ],
        context: ["notifications", "updates"],
        followUpQuestions: [
          "Manage my notifications",
          "What notifications do I get?",
          "Turn off notifications",
          "Check my updates",
        ],
      ),

      // PROFILE & SETTINGS (Enhanced)
      EnhancedFAQItem(
        question: "Profile Management",
        answer:
            "Your profile is your command center! 👤 Update your information, manage payment methods, view your activity, and customize your experience. You can also see your loyalty progress, referral stats, and account history all in one place! ⚙️",
        keywords: [
          "profile",
          "settings",
          "account",
          "personal info",
          "payment methods",
          "activity",
          "history",
        ],
        context: ["profile", "settings"],
        followUpQuestions: [
          "Update my profile",
          "Change payment methods",
          "View my activity",
          "Account settings",
        ],
      ),

      // SUPPORT & HELP (Enhanced)
      EnhancedFAQItem(
        question: "Premium Support",
        answer:
            "We're here for you 24/7! 🛟 Chat with our friendly support team, get instant help, or schedule a call. Our AI assistant (that's me!) can handle most questions, and we connect you to humans for complex issues. How can I help you today? 💬",
        keywords: [
          "support",
          "help",
          "contact",
          "chat",
          "assistance",
          "problem",
          "issue",
          "customer service",
        ],
        context: ["support", "help"],
        followUpQuestions: [
          "Speak with human support",
          "Report a problem",
          "Get help with orders",
          "Contact customer service",
        ],
      ),

      // PAYMENT METHODS (Enhanced)
      EnhancedFAQItem(
        question: "Secure Payment Options",
        answer:
            "Pay safely with multiple options! 💳 Use your wallet balance, Paystack (cards, bank transfer, mobile money), or split payments. All transactions are encrypted and secure. You can also save payment methods for faster checkout! 🔒",
        keywords: [
          "payment",
          "paystack",
          "cards",
          "bank transfer",
          "mobile money",
          "secure",
          "encrypted",
          "save payment",
        ],
        context: ["payment", "security"],
        followUpQuestions: [
          "Add payment method",
          "How secure are payments?",
          "What payment methods work?",
          "Save my card",
        ],
      ),

      // TECHNOLOGY & FEATURES (New)
      EnhancedFAQItem(
        question: "Smart App Features",
        answer:
            "Our app is packed with smart features! 🧠 Real-time updates, smart caching for fast loading, background data refresh, skeleton loaders for smooth experience, and cross-platform support (iOS, Android, Web). Everything runs smoothly and securely! ⚡",
        keywords: [
          "features",
          "technology",
          "smart",
          "fast",
          "smooth",
          "cross-platform",
          "iOS",
          "Android",
          "web",
        ],
        context: ["technology", "features"],
        followUpQuestions: [
          "What makes the app special?",
          "How fast is it?",
          "Does it work on all devices?",
          "What's new?",
        ],
      ),

      // CONTEXTUAL HELP
      EnhancedFAQItem(
        question: "General Help",
        answer:
            "I'm your personal guide to Impact Graphics ZA! 🎯 Whether you need help with wallet, rewards, orders, services, or just want to explore, I'm here to help! Ask me anything or try one of these popular topics:",
        keywords: [
          "help",
          "guide",
          "assistance",
          "how to",
          "what is",
          "explain",
          "show me",
        ],
        context: ["help", "general"],
        followUpQuestions: [
          "Show me all features",
          "How do I get started?",
          "What can I do here?",
          "Explain the rewards system",
        ],
      ),
    ];
  }

  /// Enhanced message processing with context awareness
  String processMessage(String message, String userId) {
    final normalizedMessage = _normalizeText(message);
    final context = _getUserContext(userId);

    // Store user message in context
    _addToContext(userId, message);

    // Find best matching FAQ with context consideration
    final bestMatch = _findBestMatch(normalizedMessage, context);

    if (bestMatch != null) {
      // Add personality and context to response
      return _enhanceResponse(bestMatch, context, userId);
    }

    // Contextual fallback responses
    return _getContextualFallback(normalizedMessage, context, userId);
  }

  /// Get user conversation context
  List<String> _getUserContext(String userId) {
    return _conversationContext[userId] ?? [];
  }

  /// Add message to user context
  void _addToContext(String userId, String message) {
    _conversationContext[userId] ??= [];
    _conversationContext[userId]!.add(message);

    // Keep only last 5 messages for context
    if (_conversationContext[userId]!.length > 5) {
      _conversationContext[userId]!.removeAt(0);
    }
  }

  /// Find best matching FAQ with context awareness
  EnhancedFAQItem? _findBestMatch(String message, List<String> context) {
    final faqs = getEnhancedFAQ();
    int bestScore = 0;
    EnhancedFAQItem? bestMatch;

    for (final faq in faqs) {
      int score = 0;

      // Direct keyword matching
      for (final keyword in faq.keywords) {
        if (message.contains(keyword.toLowerCase())) {
          score += 2;
        }
      }

      // Context matching
      for (final ctx in faq.context) {
        if (context.any((c) => c.toLowerCase().contains(ctx))) {
          score += 1;
        }
      }

      // Partial word matching
      final words = message.split(' ');
      for (final word in words) {
        if (faq.keywords.any(
          (k) =>
              k.toLowerCase().contains(word) || word.contains(k.toLowerCase()),
        )) {
          score += 1;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = faq;
      }
    }

    return bestScore >= 2 ? bestMatch : null;
  }

  /// Enhance response with personality and context
  String _enhanceResponse(
    EnhancedFAQItem faq,
    List<String> context,
    String userId,
  ) {
    final random = Random();
    String response = faq.answer;

    // Add encouraging expression
    if (Random().nextBool()) {
      response =
          "${_encouragingResponses[random.nextInt(_encouragingResponses.length)]}\n\n$response";
    }

    // Add follow-up suggestions if appropriate
    if (faq.followUpQuestions.isNotEmpty && Random().nextBool()) {
      response += "\n\n💡 You might also want to ask about:";
      final suggestions = faq.followUpQuestions.take(2).toList();
      for (final suggestion in suggestions) {
        response += "\n• $suggestion";
      }
    }

    return response;
  }

  /// Contextual fallback responses
  String _getContextualFallback(
    String message,
    List<String> context,
    String userId,
  ) {
    final random = Random();

    // Check if user is asking about something specific
    if (message.contains("how") ||
        message.contains("what") ||
        message.contains("where")) {
      return "${_empathyExpressions[random.nextInt(_empathyExpressions.length)]}\n\nI'm still learning about that specific topic, but I can definitely help you with:\n\n💳 **Wallet & Payments**\n🎁 **Rewards & Loyalty**\n🛒 **Orders & Services**\n💬 **Support & Help**\n\nWhat would you like to explore? Or would you prefer to speak with a human agent for more detailed assistance?";
    }

    // Default friendly response
    return "${_empathyExpressions[random.nextInt(_empathyExpressions.length)]}\n\nI'm here to help you with all things Impact Graphics ZA! 🚀\n\nHere are some popular topics I can help with:\n\n🎁 **Rewards System** - Earn money watching ads and referring friends!\n💳 **Wallet Features** - Add funds and manage payments\n🛒 **Order Management** - Place orders and track progress\n💬 **Support** - Get help with any questions\n\nWhat interests you most?";
  }

  /// Normalize text for better matching
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get smart suggestions based on user context
  List<String> getSmartSuggestions(String userId) {
    final context = _getUserContext(userId);
    final suggestions = <String>[];

    // Context-based suggestions
    if (context.any((c) => c.toLowerCase().contains('wallet'))) {
      suggestions.addAll([
        'Add funds to wallet',
        'Check transaction history',
        'View balance',
      ]);
    }

    if (context.any((c) => c.toLowerCase().contains('reward'))) {
      suggestions.addAll([
        'Watch ads for rewards',
        'Check referral progress',
        'View loyalty points',
      ]);
    }

    if (context.any((c) => c.toLowerCase().contains('order'))) {
      suggestions.addAll([
        'Place new order',
        'Track existing orders',
        'View order history',
      ]);
    }

    // Default suggestions
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'How do I earn rewards?',
        'Add funds to my wallet',
        'Place a new order',
        'Check my account balance',
        'Get design consultation',
        'View available services',
      ]);
    }

    return suggestions.take(6).toList();
  }

  /// Clear user context
  void clearUserContext(String userId) {
    _conversationContext.remove(userId);
    _userPreferences.remove(userId);
    _lastInteraction.remove(userId);
  }
}

/// Enhanced FAQ Item with additional context and follow-up questions
class EnhancedFAQItem {
  final String question;
  final String answer;
  final List<String> keywords;
  final List<String> context;
  final List<String> followUpQuestions;

  EnhancedFAQItem({
    required this.question,
    required this.answer,
    required this.keywords,
    required this.context,
    required this.followUpQuestions,
  });
}


