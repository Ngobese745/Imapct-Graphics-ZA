import 'dart:math';
import 'package:flutter/material.dart';
import 'enhanced_chatbot_service.dart';

/// Guest-specific chatbot service with limited functionality
/// No human agent access for guest users - they must sign in
class GuestChatbotService {
  static final GuestChatbotService _instance = GuestChatbotService._internal();
  factory GuestChatbotService() => _instance;
  GuestChatbotService._internal();

  final EnhancedChatbotService _enhancedChatbot = EnhancedChatbotService();

  /// Get guest-specific greeting
  String getGuestGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    String timeGreeting = "";
    if (hour < 12) {
      timeGreeting = "Good morning";
    } else if (hour < 17) {
      timeGreeting = "Good afternoon";
    } else {
      timeGreeting = "Good evening";
    }

    final random = Random();
    final greetings = [
      "$timeGreeting! 👋 I'm your friendly AI assistant! I can help you explore our amazing services and features. What would you like to know?",
      "$timeGreeting! 😊 Welcome to Impact Graphics ZA! I'm here to help you discover our services, portfolio, and benefits. How can I assist you?",
      "$timeGreeting! 🌟 Great to see you! I can show you our design services, explain our rewards system, and help you get started. What interests you most?",
      "$timeGreeting! ✨ I'm your guide to Impact Graphics ZA! Let me help you explore our services and learn about our amazing features!",
    ];

    return greetings[random.nextInt(greetings.length)];
  }

  /// Process guest messages with limited functionality
  String processGuestMessage(String message) {
    final normalizedMessage = _normalizeText(message);

    // Check for human agent requests and redirect to sign up
    if (_isHumanAgentRequest(normalizedMessage)) {
      return "I'd love to connect you with our human support team! 🤝 However, to access live chat with our agents, you'll need to create an account first. It's quick and free!\n\nOnce you sign up, you'll get access to:\n💬 **Live Chat Support** - Talk directly with our team\n🎁 **Rewards System** - Earn money watching ads and referring friends\n💳 **Wallet Features** - Add funds and manage payments\n🛒 **Order Management** - Place orders and track progress\n\nWould you like to create an account now?";
    }

    // Get response from enhanced chatbot but filter out human agent suggestions
    final response = _enhancedChatbot.processMessage(message, 'guest');

    // Remove human agent suggestions from the response
    return _filterGuestResponse(response);
  }

  /// Check if message is requesting human agent
  bool _isHumanAgentRequest(String message) {
    final humanKeywords = [
      "human",
      "agent",
      "person",
      "speak to",
      "talk to",
      "live chat",
      "customer service",
      "support agent",
      "human support",
      "real person",
      "speak with human",
      "talk with agent",
      "connect to human",
    ];

    return humanKeywords.any((keyword) => message.contains(keyword));
  }

  /// Filter response to remove human agent references for guests
  String _filterGuestResponse(String response) {
    // Remove human agent suggestions and replace with sign-up prompts
    String filteredResponse = response;

    // Replace human agent references
    filteredResponse = filteredResponse.replaceAll(
      RegExp(r'Speak with a human agent', caseSensitive: false),
      'Create account for live support',
    );

    filteredResponse = filteredResponse.replaceAll(
      RegExp(r'speak with human support', caseSensitive: false),
      'sign up for live chat',
    );

    filteredResponse = filteredResponse.replaceAll(
      RegExp(r'human support', caseSensitive: false),
      'live chat support',
    );

    // Add sign-up encouragement if not already present
    if (!filteredResponse.toLowerCase().contains('account') &&
        !filteredResponse.toLowerCase().contains('sign up') &&
        !filteredResponse.toLowerCase().contains('create account')) {
      filteredResponse +=
          "\n\n💡 **Want more features?** Create a free account to unlock live chat support, rewards, wallet features, and much more!";
    }

    return filteredResponse;
  }

  /// Get guest-specific suggestions
  List<String> getGuestSuggestions() {
    return [
      'What services do you offer?',
      'How much does logo design cost?',
      'Show me your portfolio',
      'What are your rewards?',
      'How do I create an account?',
      'What can guests do?',
      'Tell me about consultation',
      'What payment methods do you accept?',
    ];
  }

  /// Get guest-specific FAQ items
  List<GuestFAQItem> getGuestFAQ() {
    return [
      GuestFAQItem(
        question: "What services do you offer?",
        answer:
            "We offer premium graphic design services! 🎨 **Logo Design** (R299+), **Brand Identity** (R899+), **Business Cards**, **Flyers**, **Social Media Graphics**, **Web Design**, and more! Each service comes with unlimited revisions and professional quality. What catches your eye? ✨",
        keywords: [
          "services",
          "logo design",
          "brand identity",
          "business card",
          "flyer",
          "social media",
          "web design",
          "graphics",
          "what services",
          "offer",
        ],
      ),
      GuestFAQItem(
        question: "How much does logo design cost?",
        answer:
            "Our logo design starts from **R299**! 💰 This includes unlimited revisions, multiple file formats (PNG, JPG, PDF, AI, PSD), and commercial usage rights. Premium packages with additional concepts and faster delivery are also available. Ready to get started? 🚀",
        keywords: [
          "logo design",
          "cost",
          "price",
          "how much",
          "R299",
          "logo",
          "design cost",
          "pricing",
        ],
      ),
      GuestFAQItem(
        question: "What can I do as a guest?",
        answer:
            "As a guest, you can explore amazing features! 👀 **View our portfolio**, **browse services**, **learn about our rewards system**, and **see our pricing**. Create a free account to unlock **wallet features**, **order management**, **rewards tracking**, **live chat support**, and much more! 🎉",
        keywords: [
          "guest",
          "limited access",
          "what can guests do",
          "guest features",
          "without account",
          "explore",
        ],
      ),
      GuestFAQItem(
        question: "How do I create an account?",
        answer:
            "Creating an account is quick and free! 📱 Simply tap **'Create Account'** or **'Sign Up'** anywhere in the app. You can use email/password or sign in with Google. Once registered, you'll unlock all premium features including rewards, wallet, orders, and live support! 🎁",
        keywords: [
          "create account",
          "sign up",
          "register",
          "account",
          "how to join",
          "become member",
          "free account",
        ],
      ),
      GuestFAQItem(
        question: "What are your rewards?",
        answer:
            "Our rewards are incredible! 🎁 **Watch 100 ads = R10 reward** 💰, **Refer 20 friends = R10 reward** 👥, **Earn 2000 loyalty points = R500 wallet credit**! 🏆 All rewards go to your wallet for services only. Create an account to start earning! 💵",
        keywords: [
          "rewards",
          "earn money",
          "ads",
          "referral",
          "loyalty",
          "R10",
          "R500",
          "watch ads",
          "refer friends",
        ],
      ),
      GuestFAQItem(
        question: "Show me your portfolio",
        answer:
            "Check out our amazing work! 🎨 You can view our portfolio in the **Portfolio** section. We've created stunning logos, brand identities, business cards, and more for clients worldwide. Each project showcases our creativity and attention to detail. What style appeals to you? ✨",
        keywords: [
          "portfolio",
          "show work",
          "examples",
          "previous work",
          "gallery",
          "designs",
          "projects",
        ],
      ),
      GuestFAQItem(
        question: "What is consultation?",
        answer:
            "Our **free design consultation** helps you plan your project perfectly! 💬 Discuss your vision, get professional recommendations, and understand the process before ordering. It's completely free with no commitment required. Perfect for planning your brand or design needs! 🎯",
        keywords: [
          "consultation",
          "free consultation",
          "design advice",
          "expert advice",
          "plan project",
          "discuss design",
          "help planning",
        ],
      ),
      GuestFAQItem(
        question: "What payment methods do you accept?",
        answer:
            "We accept multiple secure payment methods! 💳 **Paystack** (cards, bank transfer, mobile money), **wallet payments**, and **split payments**. All transactions are encrypted and secure. Create an account to access wallet features for faster checkout! 🔒",
        keywords: [
          "payment",
          "paystack",
          "cards",
          "bank transfer",
          "mobile money",
          "secure",
          "payment methods",
          "how to pay",
        ],
      ),
    ];
  }

  /// Find best matching FAQ for guests
  GuestFAQItem? findBestGuestFAQ(String message) {
    final faqs = getGuestFAQ();
    final normalizedMessage = _normalizeText(message);

    int bestScore = 0;
    GuestFAQItem? bestMatch;

    for (final faq in faqs) {
      int score = 0;

      for (final keyword in faq.keywords) {
        if (normalizedMessage.contains(keyword.toLowerCase())) {
          score += 2;
        }
      }

      // Partial word matching
      final words = normalizedMessage.split(' ');
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

  /// Normalize text for better matching
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Guest FAQ Item
class GuestFAQItem {
  final String question;
  final String answer;
  final List<String> keywords;

  GuestFAQItem({
    required this.question,
    required this.answer,
    required this.keywords,
  });
}
