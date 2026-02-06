import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

// Transaction model for wallet
class WalletTransaction {
  final String id;
  final String
  type; // 'payment', 'wallet_funding', 'refund', 'invoice_received', etc.
  final double amount;
  final String description;
  final DateTime date;
  final String status;
  final String? transactionId;
  final String? orderId;
  final String? reference;
  final bool? isInvoice;
  final String? invoiceId;
  final String? invoiceNumber;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.status,
    this.transactionId,
    this.orderId,
    this.reference,
    this.isInvoice,
    this.invoiceId,
    this.invoiceNumber,
  });

  factory WalletTransaction.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return WalletTransaction(
      id: id,
      type: data['type'] ?? 'payment',
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? 'Transaction',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'completed',
      transactionId: data['transactionId'],
      orderId: data['orderId'],
      reference: data['reference'],
      isInvoice: data['isInvoice'] ?? false,
      invoiceId: data['invoiceId'],
      invoiceNumber: data['invoiceNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'createdAt': Timestamp.fromDate(date),
      'status': status,
      'transactionId': transactionId,
      'orderId': orderId,
      'reference': reference,
      'isInvoice': isInvoice,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
    };
  }
}

// Wallet model
class Wallet {
  final String userId;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'active', 'suspended', 'closed'
  final double? creditLimit;
  final double? availableCredit;

  Wallet({
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.creditLimit,
    this.availableCredit,
  });

  factory Wallet.fromFirestore(Map<String, dynamic> data, String userId) {
    return Wallet(
      userId: userId,
      balance: (data['balance'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      creditLimit: data['creditLimit']?.toDouble(),
      availableCredit: data['availableCredit']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
      'creditLimit': creditLimit,
      'availableCredit': availableCredit,
    };
  }
}

class WalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's wallet
  static Future<Wallet?> getUserWallet(String userId) async {
    try {
      print('💰 WalletService: Fetching wallet for user $userId...');

      // First check users collection (primary source)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final walletBalance = userData?['walletBalance'] ?? 0.0;
        print(
          '💰 WalletService: Found wallet balance in users collection: R$walletBalance',
        );
      }

      // Then check wallets collection
      final doc = await _firestore.collection('wallets').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final wallet = Wallet.fromFirestore(data, userId);
          print(
            '💰 WalletService: Wallet loaded from Firestore - Balance: R${wallet.balance}',
          );
          return wallet;
        }
        return null;
      } else {
        print(
          '⚠️ WalletService: No wallet document found, checking users collection...',
        );
        // If no wallet doc exists, get from users collection
        if (userDoc.exists) {
          final userData = userDoc.data();
          final walletBalance = (userData?['walletBalance'] ?? 0.0) as num;
          print(
            '💰 WalletService: Creating wallet from users collection - Balance: R$walletBalance',
          );
          return Wallet(
            userId: userId,
            balance: walletBalance.toDouble(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        return null;
      }
    } catch (e) {
      print('❌ WalletService: Error getting user wallet: $e');
      return null;
    }
  }

  // Create wallet for user
  static Future<bool> createWallet(String userId) async {
    try {
      final wallet = Wallet(
        userId: userId,
        balance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('wallets').doc(userId).set(wallet.toMap());
      return true;
    } catch (e) {
      print('Error creating wallet: $e');
      return false;
    }
  }

  // Get wallet transactions
  static Stream<List<WalletTransaction>> getWalletTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs
              .map((doc) => WalletTransaction.fromFirestore(doc.data(), doc.id))
              .toList();

          // Sort by date in descending order (most recent first)
          transactions.sort((a, b) => b.date.compareTo(a.date));

          return transactions;
        });
  }

  // Add funds to wallet
  static Future<bool> addFunds(
    String userId,
    double amount,
    String description,
  ) async {
    try {
      print('=== ADDING FUNDS TO WALLET ===');
      print('User ID: $userId');
      print('Amount: R$amount');
      print('Description: $description');

      final batch = _firestore.batch();

      // Update wallet balance in wallets collection (create if doesn't exist)
      final walletRef = _firestore.collection('wallets').doc(userId);

      // First check if wallet exists, if not create it
      final walletDoc = await walletRef.get();
      if (!walletDoc.exists) {
        print('Wallet does not exist, creating new wallet...');
        // Create new wallet with initial balance
        batch.set(walletRef, {
          'userId': userId,
          'balance': amount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        print('Wallet exists, updating balance...');
        // Update existing wallet
        batch.update(walletRef, {
          'balance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Also update users collection for consistency (primary wallet storage)
      final userRef = _firestore.collection('users').doc(userId);
      print('💰 WALLET SERVICE: About to update users collection');
      print('💰 WALLET SERVICE: User ID: $userId');
      print('💰 WALLET SERVICE: Amount: R$amount');
      print('💰 WALLET SERVICE: Description: $description');
      batch.update(userRef, {
        'walletBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('💰 WALLET SERVICE: Users collection update added to batch');

      // Generate invoice number and reference
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final second = now.second.toString().padLeft(2, '0');

      final invoiceNumber = 'INV$year$month$day$hour$minute$second';
      final timestamp = now.millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final transactionReference = 'WALLET-FUND-$timestamp-$random';

      // Create transaction record
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': 'wallet_funding',
        'amount': amount,
        'description': description,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'reference': transactionReference,
        'invoiceNumber': invoiceNumber,
        'transactionReference': transactionReference,
        'hasInvoice': true,
      });

      await batch.commit();
      print('✅ Funds added successfully to wallet');

      // Send notification to user about the wallet funding
      try {
        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: 'Wallet Funded! 💰',
          body:
              'R${amount.toStringAsFixed(2)} has been added to your wallet. $description',
          type: 'wallet',
          action: 'wallet_funded',
          data: {
            'amount': amount,
            'description': description,
            'invoiceNumber': invoiceNumber,
          },
        );
        print('✅ Wallet funding notification sent');
      } catch (e) {
        print('❌ Error sending wallet funding notification: $e');
      }

      return true;
    } catch (e) {
      print('❌ Error adding funds: $e');
      return false;
    }
  }

  // Credit wallet (admin function)
  static Future<bool> creditWallet({
    required String userId,
    required double amount,
    required String type,
    required String description,
    String? adminId,
  }) async {
    try {
      print('=== ADMIN CREDITING WALLET ===');
      print('User ID: $userId');
      print('Amount: R$amount');
      print('Type: $type');
      print('Description: $description');
      print('Admin ID: $adminId');

      final batch = _firestore.batch();

      // Update user wallet balance in users collection (primary storage)
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'walletBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
        '💰 WALLET SERVICE: Users collection update added to batch for user: $userId',
      );

      // Update wallet balance (create if doesn't exist)
      final walletRef = _firestore.collection('wallets').doc(userId);

      // Check if wallet document exists, create if it doesn't
      final walletDoc = await walletRef.get();
      if (!walletDoc.exists) {
        // Create new wallet document for new users
        batch.set(walletRef, {
          'userId': userId,
          'balance': amount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(
          '💰 WALLET SERVICE: Created new wallet document for user: $userId',
        );
      } else {
        // Update existing wallet document
        batch.update(walletRef, {
          'balance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(
          '💰 WALLET SERVICE: Updated existing wallet document for user: $userId',
        );
      }

      // Generate invoice number and reference
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final second = now.second.toString().padLeft(2, '0');

      final invoiceNumber = 'INV$year$month$day$hour$minute$second';
      final timestamp = now.millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final transactionReference = 'ADMIN-CREDIT-$timestamp-$random';

      // Create transaction record
      final transactionRef = _firestore.collection('wallet_transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': type,
        'amount': amount,
        'description': description,
        'status': 'completed',
        'adminId': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reference': transactionReference,
        'invoiceNumber': invoiceNumber,
        'transactionReference': transactionReference,
        'hasInvoice': true,
      });

      await batch.commit();
      print('✅ Admin credit completed successfully');

      // Get user details for notification and email
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userEmail = userData['email'] as String?;
          final userName =
              userData['name'] as String? ??
              userData['username'] as String? ??
              'Valued Client';

          // Send notification to user
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: 'Wallet Credited! 💰',
            body:
                'Admin has credited R${amount.toStringAsFixed(2)} to your wallet. $description',
            type: 'wallet',
            action: 'admin_credit',
            data: {
              'amount': amount,
              'description': description,
              'invoiceNumber': invoiceNumber,
              'transactionReference': transactionReference,
            },
          );
          print('✅ Wallet credit notification sent to user');

          // Send email notification to user
          if (userEmail != null && userEmail.isNotEmpty) {
            print('📧 Sending wallet credit email to: $userEmail');
            // await MailerSendService.sendWalletCreditEmail(
            //   toEmail: userEmail,
            //   toName: userName,
            //   amount: amount,
            //   description: description,
            //   invoiceNumber: invoiceNumber,
            //   transactionReference: transactionReference,
            // );
            print('✅ Wallet credit email sent');
          }
        }
      } catch (e) {
        print('❌ Error sending credit notifications: $e');
        // Don't fail the credit operation if notification fails
      }

      return true;
    } catch (e) {
      print('Error crediting wallet: $e');
      return false;
    }
  }

  // Deduct funds from wallet (admin function)
  static Future<bool> deductWallet({
    required String userId,
    required double amount,
    required String type,
    required String description,
    String? adminId,
  }) async {
    try {
      print('=== ADMIN DEDUCTING FROM WALLET ===');
      print('User ID: $userId');
      print('Amount: R$amount');
      print('Type: $type');
      print('Description: $description');
      print('Admin ID: $adminId');

      // Check if user has sufficient balance
      final wallet = await getUserWallet(userId);
      if (wallet == null) {
        print('❌ User wallet not found');
        return false;
      }

      if (wallet.balance < amount) {
        print(
          '❌ Insufficient funds. Current balance: R${wallet.balance}, Requested: R$amount',
        );
        return false;
      }

      final batch = _firestore.batch();

      // Update wallet balance
      final walletRef = _firestore.collection('wallets').doc(userId);
      batch.update(walletRef, {
        'balance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update users collection for consistency
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'walletBalance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Generate invoice number and reference
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final second = now.second.toString().padLeft(2, '0');

      final invoiceNumber = 'INV$year$month$day$hour$minute$second';
      final timestamp = now.millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final transactionReference = 'ADMIN-DEDUCT-$timestamp-$random';

      // Create transaction record
      final transactionRef = _firestore.collection('wallet_transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': type,
        'amount': amount,
        'description': description,
        'status': 'completed',
        'adminId': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reference': transactionReference,
        'invoiceNumber': invoiceNumber,
        'transactionReference': transactionReference,
        'hasInvoice': true,
      });

      await batch.commit();
      print('✅ Admin deduction completed successfully');

      // Get user details for notification and email
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userEmail = userData['email'] as String?;
          final userName =
              userData['name'] as String? ??
              userData['username'] as String? ??
              'Valued Client';

          // Send notification to user
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: 'Wallet Deducted ⚠️',
            body:
                'Admin has deducted R${amount.toStringAsFixed(2)} from your wallet. $description',
            type: 'wallet',
            action: 'admin_deduct',
            data: {
              'amount': amount,
              'description': description,
              'invoiceNumber': invoiceNumber,
              'transactionReference': transactionReference,
            },
          );
          print('✅ Wallet deduction notification sent to user');

          // Send email notification to user
          if (userEmail != null && userEmail.isNotEmpty) {
            print('📧 Sending wallet deduction email to: $userEmail');
            // await MailerSendService.sendWalletDeductionEmail(
            //   toEmail: userEmail,
            //   toName: userName,
            //   amount: amount,
            //   description: description,
            //   invoiceNumber: invoiceNumber,
            //   transactionReference: transactionReference,
            // );
            print('✅ Wallet deduction email sent');
          }
        }
      } catch (e) {
        print('❌ Error sending deduction notifications: $e');
        // Don't fail the deduction operation if notification fails
      }

      return true;
    } catch (e) {
      print('❌ Error deducting from wallet: $e');
      return false;
    }
  }

  // Deduct funds from wallet
  static Future<bool> deductFunds(
    String userId,
    double amount,
    String description, {
    String? orderId,
  }) async {
    try {
      final wallet = await getUserWallet(userId);
      if (wallet == null || wallet.balance < amount) {
        return false; // Insufficient funds
      }

      final batch = _firestore.batch();

      // Update wallet balance
      final walletRef = _firestore.collection('wallets').doc(userId);
      batch.update(walletRef, {
        'balance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Generate invoice number and reference
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final second = now.second.toString().padLeft(2, '0');

      final invoiceNumber = 'INV$year$month$day$hour$minute$second';
      final timestamp = now.millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final transactionReference = 'PAYMENT-$timestamp-$random';

      // Create transaction record
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': 'payment',
        'amount': amount,
        'description': description,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'orderId': orderId,
        'reference': transactionReference,
        'invoiceNumber': invoiceNumber,
        'transactionReference': transactionReference,
        'hasInvoice': true,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deducting funds: $e');
      return false;
    }
  }

  // Process payment with wallet
  static Future<bool> processPayment(
    String userId,
    double amount,
    String description, {
    String? orderId,
  }) async {
    try {
      final wallet = await getUserWallet(userId);
      if (wallet == null) {
        // Create wallet if it doesn't exist
        await createWallet(userId);
      }

      return await deductFunds(userId, amount, description, orderId: orderId);
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  // Get all wallets (for admin)
  static Stream<List<Wallet>> getAllWallets() {
    return _firestore
        .collection('wallets')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Wallet.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get wallet with user details (for admin)
  static Stream<List<Map<String, dynamic>>> getAllWalletsWithUserDetails() {
    return _firestore.collection('wallets').snapshots().asyncMap((
      walletSnapshot,
    ) async {
      List<Map<String, dynamic>> walletsWithUsers = [];

      for (var walletDoc in walletSnapshot.docs) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(walletDoc.id)
              .get();

          if (userDoc.exists) {
            walletsWithUsers.add({
              'wallet': Wallet.fromFirestore(walletDoc.data(), walletDoc.id),
              'user': userDoc.data(),
              'userId': walletDoc.id,
            });
          }
        } catch (e) {
          print('Error getting user details for wallet ${walletDoc.id}: $e');
        }
      }

      return walletsWithUsers;
    });
  }

  // Format currency
  static String formatCurrency(double amount) {
    return 'R${amount.toStringAsFixed(2)}';
  }

  // Format date
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
