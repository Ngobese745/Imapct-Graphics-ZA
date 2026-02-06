import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PaystackCustomerService {
  static const String _secretKey = 'sk_live_PLACEHOLDER';
  static const String _baseUrl = 'https://api.paystack.co';

  static PaystackCustomerService? _instance;
  static PaystackCustomerService get instance =>
      _instance ??= PaystackCustomerService._();
  PaystackCustomerService._();

  /// Create a Paystack customer
  Future<Map<String, dynamic>> createCustomer({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      print('=== CREATING PAYSTACK CUSTOMER ===');
      print('Email: $email');
      print('Name: $firstName $lastName');

      final response = await http.post(
        Uri.parse('$_baseUrl/customer'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
        }),
      );

      print(
        'Paystack customer creation response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Paystack customer created successfully');
        print('Customer ID: ${data['data']['customer_code']}');

        return {'success': true, 'customer': data['data']};
      } else {
        print('❌ Failed to create Paystack customer');
        return {
          'success': false,
          'error': 'Failed to create customer: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error creating Paystack customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get customer details from Paystack
  Future<Map<String, dynamic>> getCustomer(String customerCode) async {
    try {
      print('=== GETTING PAYSTACK CUSTOMER ===');
      print('Customer Code: $customerCode');

      final response = await http.get(
        Uri.parse('$_baseUrl/customer/$customerCode'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      print(
        'Paystack customer fetch response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Paystack customer retrieved successfully');

        return {'success': true, 'customer': data['data']};
      } else {
        print('❌ Failed to get Paystack customer');
        return {
          'success': false,
          'error': 'Failed to get customer: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting Paystack customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Save customer card details locally (encrypted)
  Future<bool> saveCustomerCard({
    required String userId,
    required String cardNumber,
    required String cardName,
    required String expiryDate,
    required String cvv,
    String? paystackCustomerCode,
  }) async {
    try {
      print('=== SAVING CUSTOMER CARD LOCALLY ===');
      print('User ID: $userId');
      print('Card Number: ${cardNumber.replaceRange(0, 12, '****')}****');

      // Encrypt sensitive data before storing
      final encryptedCardNumber = _encryptData(cardNumber);
      final encryptedCvv = _encryptData(cvv);

      final cardData = {
        'userId': userId,
        'cardNumber': encryptedCardNumber,
        'cardName': cardName,
        'expiryDate': expiryDate,
        'cvv': encryptedCvv,
        'lastFourDigits': cardNumber.substring(cardNumber.length - 4),
        'cardType': _getCardType(cardNumber),
        'paystackCustomerCode': paystackCustomerCode,
        'isDefault': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('saved_cards').add(cardData);

      // Update user document with saved cards count
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hasSavedCards': true,
        'savedCardsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Customer card saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving customer card: $e');
      return false;
    }
  }

  /// Get user's saved cards
  Future<List<Map<String, dynamic>>> getSavedCards(String userId) async {
    try {
      print('=== GETTING SAVED CARDS ===');
      print('User ID: $userId');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('saved_cards')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final cards = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'cardName': data['cardName'],
          'lastFourDigits': data['lastFourDigits'],
          'expiryDate': data['expiryDate'],
          'cardType': data['cardType'],
          'isDefault': data['isDefault'] ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();

      print('✅ Retrieved ${cards.length} saved cards');
      return cards;
    } catch (e) {
      print('❌ Error getting saved cards: $e');
      return [];
    }
  }

  /// Delete saved card
  Future<bool> deleteSavedCard(String cardId, String userId) async {
    try {
      print('=== DELETING SAVED CARD ===');
      print('Card ID: $cardId');

      await FirebaseFirestore.instance
          .collection('saved_cards')
          .doc(cardId)
          .delete();

      // Update user document
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'savedCardsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Saved card deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting saved card: $e');
      return false;
    }
  }

  /// Set default card
  Future<bool> setDefaultCard(String cardId, String userId) async {
    try {
      print('=== SETTING DEFAULT CARD ===');
      print('Card ID: $cardId');

      final batch = FirebaseFirestore.instance.batch();

      // Remove default from all user's cards
      final cardsQuery = await FirebaseFirestore.instance
          .collection('saved_cards')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in cardsQuery.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Set the selected card as default
      batch.update(
        FirebaseFirestore.instance.collection('saved_cards').doc(cardId),
        {'isDefault': true, 'updatedAt': FieldValue.serverTimestamp()},
      );

      await batch.commit();

      print('✅ Default card set successfully');
      return true;
    } catch (e) {
      print('❌ Error setting default card: $e');
      return false;
    }
  }

  /// Get decrypted card details for payment
  Future<Map<String, dynamic>?> getCardDetails(String cardId) async {
    try {
      print('=== GETTING CARD DETAILS ===');
      print('Card ID: $cardId');

      final doc = await FirebaseFirestore.instance
          .collection('saved_cards')
          .doc(cardId)
          .get();

      if (!doc.exists) {
        print('❌ Card not found');
        return null;
      }

      final data = doc.data();
      if (data == null) return null;
      final decryptedCardNumber = _decryptData(data['cardNumber']);
      final decryptedCvv = _decryptData(data['cvv']);

      return {
        'cardNumber': decryptedCardNumber,
        'cardName': data['cardName'],
        'expiryDate': data['expiryDate'],
        'cvv': decryptedCvv,
        'lastFourDigits': data['lastFourDigits'],
        'cardType': data['cardType'],
      };
    } catch (e) {
      print('❌ Error getting card details: $e');
      return null;
    }
  }

  /// Simple encryption (for demo - use proper encryption in production)
  String _encryptData(String data) {
    // In production, use proper encryption like AES
    // This is just a simple example
    return base64.encode(utf8.encode(data));
  }

  /// Simple decryption (for demo - use proper decryption in production)
  String _decryptData(String encryptedData) {
    // In production, use proper decryption
    // This is just a simple example
    try {
      return utf8.decode(base64.decode(encryptedData));
    } catch (e) {
      return encryptedData; // Fallback if decryption fails
    }
  }

  /// Determine card type from number
  String _getCardType(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');

    if (number.startsWith('4')) {
      return 'Visa';
    } else if (number.startsWith('5') || number.startsWith('2')) {
      return 'Mastercard';
    } else if (number.startsWith('3')) {
      return 'American Express';
    } else if (number.startsWith('6')) {
      return 'Discover';
    } else {
      return 'Unknown';
    }
  }

  /// Initialize customer in Paystack if not exists
  Future<String?> initializeCustomer() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      // Check if user already has a Paystack customer code
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData == null) return null;
        if (userData['paystackCustomerCode'] != null) {
          print('✅ User already has Paystack customer code');
          return userData['paystackCustomerCode'];
        }
      }

      // Create new Paystack customer
      final customerResult = await createCustomer(
        email: currentUser.email!,
        firstName: currentUser.displayName?.split(' ').first ?? 'User',
        lastName: currentUser.displayName?.split(' ').last ?? '',
        phone: userDoc.data()?['phone'],
      );

      if (customerResult['success']) {
        final customerCode = customerResult['customer']['customer_code'];

        // Save customer code to user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'paystackCustomerCode': customerCode,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        print('✅ Paystack customer initialized successfully');
        return customerCode;
      } else {
        print('❌ Failed to initialize Paystack customer');
        return null;
      }
    } catch (e) {
      print('❌ Error initializing Paystack customer: $e');
      return null;
    }
  }
}
