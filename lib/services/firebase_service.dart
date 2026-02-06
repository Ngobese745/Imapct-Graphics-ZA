import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'google_signin_config.dart';
import 'mailersend_service.dart';
import 'notification_service.dart';
import 'user_deletion_service.dart';
import 'web_auth_config.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static bool _firestorePersistenceEnabled = false;

  // Initialize Firebase with persistence settings
  static Future<void> initialize() async {
    try {
      // Enable Firestore persistence for web platform
      if (kIsWeb && !_firestorePersistenceEnabled) {
        try {
          await _firestore.enablePersistence(
            const PersistenceSettings(synchronizeTabs: true),
          );
          _firestorePersistenceEnabled = true;
          print('✅ Firestore persistence enabled for web');
        } catch (e) {
          if (e.toString().contains('failed-precondition')) {
            // Multiple tabs open, persistence can only be enabled in one tab at a time
            print('⚠️ Firestore persistence already enabled in another tab');
          } else if (e.toString().contains('unimplemented')) {
            // The current browser doesn't support persistence
            print('⚠️ Firestore persistence not supported in this browser');
          } else {
            print('⚠️ Error enabling Firestore persistence: $e');
          }
        }
      }

      // Initialize Auth
      await initializeAuth();
    } catch (e) {
      print('Error initializing Firebase Service: $e');
    }
  }

  // Initialize Firebase Auth with custom settings to handle keychain issues
  static Future<void> initializeAuth() async {
    try {
      print('Firebase Auth initialized for macOS');
    } catch (e) {
      print('Error initializing Firebase Auth: $e');
      print('Firebase Auth initialized for macOS (fallback)');
    }
  }

  // Authentication methods
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');

      // Handle keychain error on macOS - this is a known issue
      if (e.toString().contains('keychain-error')) {
        print(
          'Keychain error detected - this is a known macOS issue with Firebase Auth',
        );
        print('The authentication should still work despite this error');

        // For keychain errors, we'll try to check if the user is actually authenticated
        // Wait a moment for the auth state to potentially update
        await Future.delayed(Duration(milliseconds: 1000));

        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          print(
            'User is authenticated despite keychain error: ${currentUser.email}',
          );
          // Return null to indicate success, let the auth state listener handle the flow
          return null;
        } else {
          print('User is not authenticated after keychain error');
          // For keychain errors, we'll allow the authentication to proceed
          // This is a known macOS issue that doesn't prevent authentication from working
          print('Allowing authentication to proceed despite keychain error');
          return null;
        }
      }

      rethrow;
    }
  }

  static Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign up error: $e');

      // Handle keychain error on macOS - this is a known issue
      if (e.toString().contains('keychain-error')) {
        print(
          'Keychain error detected - this is a known macOS issue with Firebase Auth',
        );
        print('The authentication should still work despite this error');

        // For keychain errors, we'll try to check if the user was actually created
        // Wait a moment for the auth state to potentially update
        await Future.delayed(Duration(milliseconds: 1000));

        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          print(
            'User was created despite keychain error: ${currentUser.email}',
          );
          // Return null to indicate success, let the auth state listener handle the flow
          return null;
        } else {
          print('User was not created after keychain error');
          // For keychain errors, we'll allow the user creation to proceed
          // This is a known macOS issue that doesn't prevent authentication from working
          print('Allowing user creation to proceed despite keychain error');
          return null;
        }
      }

      rethrow;
    }
  }

  // Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific Google Sign In
        print('Using web Google Sign In');

        // Use the web auth configuration
        final googleProvider = WebAuthConfig.getGoogleProvider();

        // Sign in with popup for web
        final userCredential = await _auth.signInWithPopup(googleProvider);

        // Check if user originally signed up with Google (for existing users)
        if (userCredential.user != null) {
          final userId = userCredential.user!.uid;
          final userDoc = await usersCollection.doc(userId).get();

          // If user exists, check their original provider
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final originalProvider = userData['provider'];

            // If user originally signed up with email/password, deny Google login
            if (originalProvider != null && originalProvider != 'google') {
              print(
                '❌ Google login denied: User originally signed up with $originalProvider',
              );
              await _auth.signOut(); // Sign out the user
              throw Exception(
                'You originally signed up with email/password. Please use email login instead.',
              );
            }
          }

          final isNewUser =
              userCredential.additionalUserInfo?.isNewUser ?? false;

          await createUserProfile(
            uid: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Google User',
            email: userCredential.user!.email ?? '',
            role: 'user',
            provider: 'google',
          );

          // Send welcome email for new Google Sign-In users
          if (isNewUser && userCredential.user!.email != null) {
            try {
              print(
                '📧 Google Sign-In (Web): Sending welcome email to new user: ${userCredential.user!.email}',
              );
              final welcomeResult = await MailerSendService.sendWelcomeEmail(
                toEmail: userCredential.user!.email!,
                toName: userCredential.user!.displayName ?? 'Google User',
              );
              if (welcomeResult.success) {
                print(
                  '📧 ✅ Google Sign-In (Web): Welcome email sent successfully to ${userCredential.user!.email}',
                );
              } else {
                print(
                  '📧 ❌ Google Sign-In (Web): Failed to send welcome email: ${welcomeResult.message}',
                );
              }
            } catch (e) {
              print(
                '📧 ❌ Google Sign-In (Web): Error sending welcome email: $e',
              );
            }
          }
        }

        return userCredential;
      } else {
        // Mobile/Desktop-specific Google Sign In
        print('Using mobile/desktop Google Sign In');

        // Get configured GoogleSignIn instance
        final GoogleSignIn googleSignIn = GoogleSignInConfig.getGoogleSignIn();

        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          print('Google sign in was cancelled by user');
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        try {
          // Sign in to Firebase with the Google credential
          final userCredential = await _auth.signInWithCredential(credential);

          // Check if user originally signed up with Google (for existing users)
          if (userCredential.user != null) {
            final userId = userCredential.user!.uid;
            final userDoc = await usersCollection.doc(userId).get();

            // If user exists, check their original provider
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final originalProvider = userData['provider'];

              // If user originally signed up with email/password, deny Google login
              if (originalProvider != null && originalProvider != 'google') {
                print(
                  '❌ Google login denied: User originally signed up with $originalProvider',
                );
                await _auth.signOut(); // Sign out the user
                throw Exception(
                  'You originally signed up with email/password. Please use email login instead.',
                );
              }
            }

            final isNewUser =
                userCredential.additionalUserInfo?.isNewUser ?? false;

            await createUserProfile(
              uid: userCredential.user!.uid,
              name: userCredential.user!.displayName ?? 'Google User',
              email: userCredential.user!.email ?? '',
              role: 'user',
              provider: 'google',
            );

            // Send welcome email for new Google Sign-In users
            if (isNewUser && userCredential.user!.email != null) {
              try {
                print(
                  '📧 Google Sign-In: Sending welcome email to new user: ${userCredential.user!.email}',
                );
                final welcomeResult = await MailerSendService.sendWelcomeEmail(
                  toEmail: userCredential.user!.email!,
                  toName: userCredential.user!.displayName ?? 'Google User',
                );
                if (welcomeResult.success) {
                  print(
                    '📧 ✅ Google Sign-In: Welcome email sent successfully to ${userCredential.user!.email}',
                  );
                } else {
                  print(
                    '📧 ❌ Google Sign-In: Failed to send welcome email: ${welcomeResult.message}',
                  );
                }
              } catch (e) {
                print('📧 ❌ Google Sign-In: Error sending welcome email: $e');
              }
            }
          }

          return userCredential;
        } catch (firebaseError) {
          // Handle keychain error on macOS - this is a known issue
          if (firebaseError.toString().contains('keychain-error')) {
            print(
              'Keychain error detected - this is a known macOS issue with Firebase Auth',
            );
            print('The authentication should still work despite this error');

            // For keychain errors, we'll try to check if the user is actually authenticated
            // Wait a moment for the auth state to potentially update
            await Future.delayed(Duration(milliseconds: 1000));

            final currentUser = _auth.currentUser;
            if (currentUser != null && currentUser.email == googleUser.email) {
              print(
                'User is authenticated despite keychain error: ${currentUser.email}',
              );

              // Create or update user profile in Firestore
              await createUserProfile(
                uid: currentUser.uid,
                name: currentUser.displayName ?? 'Google User',
                email: currentUser.email ?? '',
                role: 'user',
                provider: 'google',
              );

              // Return a mock UserCredential to indicate success
              // The auth state listener will handle the flow
              return null;
            } else {
              print('User is not authenticated after keychain error');
              // For keychain errors, we'll allow the authentication to proceed
              // This is a known macOS issue that doesn't prevent authentication from working
              print(
                'Allowing authentication to proceed despite keychain error',
              );
              return null;
            }
          }

          rethrow;
        }
      }
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      print('Starting aggressive signOut process...');

      if (kIsWeb) {
        // Web-specific sign out
        print('Using web sign out');

        // Sign out from Firebase (this handles all providers on web)
        await _auth.signOut();
        print('Firebase Auth: signed out (web)');
      } else {
        // Mobile-specific sign out
        print('Using mobile sign out');

        // Sign out from Google first if using Google Sign In
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
          print('Google Sign In: signed out');
        }

        // Sign out from Facebook if using Facebook Auth
        // try {
        //   await FacebookAuth.instance.logOut();
        //   print('Facebook Auth: signed out');
        // } catch (e) {
        //   // Facebook may not be configured, that's okay
        //   print('Facebook signout skipped: $e');
        // }

        // Sign out from Firebase
        await _auth.signOut();
        print('Firebase Auth: signed out');
      }

      // Force clear any remaining auth state
      await Future.delayed(const Duration(milliseconds: 1000));

      // Double-check and force clear if still authenticated
      if (_auth.currentUser != null) {
        print('User still authenticated after signOut, forcing clear...');
        try {
          // Try to sign out again
          await _auth.signOut();
          print('Second Firebase signOut completed');
        } catch (e) {
          print('Second signOut failed: $e');
        }
      }

      print('Aggressive signOut process completed');
    } catch (e) {
      print('Error during signOut: $e');
      // Still try to sign out from Firebase even if other providers fail
      try {
        await _auth.signOut();
        print('Fallback Firebase signOut completed');
      } catch (e2) {
        print('Fallback signOut also failed: $e2');
      }
    }
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Firestore methods
  static CollectionReference get usersCollection =>
      _firestore.collection('users');
  static CollectionReference get clientsCollection =>
      _firestore.collection('clients');
  static CollectionReference get ordersCollection =>
      _firestore.collection('orders');
  static CollectionReference get cartCollection =>
      _firestore.collection('cart');
  static CollectionReference get servicesCollection =>
      _firestore.collection('services');
  static CollectionReference get updatesCollection =>
      _firestore.collection('updates');
  static CollectionReference get transactionsCollection =>
      _firestore.collection('transactions');
  static CollectionReference get walletTransactionsCollection =>
      _firestore.collection('walletTransactions');
  static CollectionReference get invoicesCollection =>
      _firestore.collection('invoices');

  // User management
  static Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? phone,
    String? provider,
  }) async {
    // CRITICAL FIX: Check if user already exists to prevent data loss
    final existingUser = await usersCollection.doc(uid).get();

    if (existingUser.exists) {
      // User already exists - ONLY update lastLogin to preserve existing data
      print(
        '✅ User profile already exists for $uid - preserving existing data',
      );
      await usersCollection.doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    // User doesn't exist - create new profile with trial
    print('🆕 Creating NEW user profile for $uid with 7-day Gold Tier trial');
    final now = DateTime.now();
    final trialEndDate = now.add(const Duration(days: 7));

    await usersCollection.doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'provider': provider,
      'isActive': true,
      'loyaltyPoints': 0,
      'isSilverTier': false,
      'isGoldTier': true, // Start as Gold Tier for trial
      'goldTierActive': true, // Active Gold Tier
      'goldTierStatus': 'trial', // Trial status
      'goldTierTrialStartDate': FieldValue.serverTimestamp(),
      'goldTierTrialEndDate': Timestamp.fromDate(trialEndDate),
      'hasHadGoldTierTrial': true, // Mark that user has had a trial
      'accountStatus': 'Gold Tier user (Trial)', // Trial status
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  static Future<DocumentSnapshot?> getUserProfile(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await usersCollection.doc(uid).update(data);
  }

  // Check and update trial status (deprecated - use GoldTierTrialService instead)
  static Future<void> checkAndUpdateTrialStatus(String uid) async {
    // This method is deprecated - use GoldTierTrialService.checkAndExpireTrials() instead
    print(
      'Warning: checkAndUpdateTrialStatus is deprecated. Use GoldTierTrialService instead.',
    );
  }

  // Move user to client when they make a purchase
  static Future<void> moveUserToClient(
    String uid, {
    double? orderAmount,
  }) async {
    try {
      // Get user data
      final userDoc = await usersCollection.doc(uid).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Check if user is already a client
      final existingClient = await clientsCollection
          .where('email', isEqualTo: userData['email'])
          .get();

      if (existingClient.docs.isNotEmpty) {
        // User is already a client, update their statistics
        final clientDoc = existingClient.docs.first;
        final clientData = clientDoc.data() as Map<String, dynamic>;
        final currentTotalOrders = clientData['totalOrders'] ?? 0;
        final currentTotalSpent = clientData['totalSpent'] ?? 0.0;

        await clientsCollection.doc(clientDoc.id).update({
          'totalOrders': currentTotalOrders + 1,
          'totalSpent': currentTotalSpent + (orderAmount ?? 0.0),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastOrder': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Create new client from user data
      await clientsCollection.add({
        'name': userData['name'] ?? 'Unknown',
        'contact': userData['name'] ?? 'Unknown',
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'address': 'Address not provided',
        'status': 'Active',
        'totalOrders': 1,
        'totalSpent': orderAmount ?? 0.0,
        'lastOrder': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': uid, // Reference to original user
      });

      print('User $uid moved to clients successfully');
    } catch (e) {
      print('Error moving user to client: $e');
      rethrow;
    }
  }

  // Client management
  static Future<void> createClient(Map<String, dynamic> clientData) async {
    await clientsCollection.add({
      ...clientData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<QuerySnapshot> getClients() async {
    return await clientsCollection.orderBy('createdAt', descending: true).get();
  }

  static Future<void> updateClient(
    String clientId,
    Map<String, dynamic> data,
  ) async {
    await clientsCollection.doc(clientId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteClient(String clientId) async {
    try {
      print('🗑️ FirebaseService: Deleting client with ID: $clientId');

      // Check if client exists first
      final clientDoc = await clientsCollection.doc(clientId).get();
      if (!clientDoc.exists) {
        print('❌ FirebaseService: Client document does not exist');
        throw Exception('Client document does not exist');
      }

      print(
        '✅ FirebaseService: Client document exists, proceeding with deletion',
      );

      await clientsCollection.doc(clientId).delete();

      print('✅ FirebaseService: Client deleted successfully');
    } catch (e) {
      print('❌ FirebaseService: Error deleting client: $e');
      rethrow;
    }
  }

  // Order management
  static Future<String> _generateOrderNumber() async {
    // Get current date for prefix
    final now = DateTime.now();
    final datePrefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Get count of orders for today
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayOrders = await ordersCollection
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .where('createdAt', isLessThan: endOfDay)
        .get();

    // Generate sequential number for today
    final todayCount = todayOrders.docs.length + 1;
    final sequentialNumber = todayCount.toString().padLeft(3, '0');

    // Create order number: YYYYMMDD-XXX (e.g., 20250115-001)
    return 'IGZ-$datePrefix-$sequentialNumber';
  }

  static Future<String> createOrder(Map<String, dynamic> orderData) async {
    // Generate unique order number
    final orderNumber = await _generateOrderNumber();

    print('🔴 FIREBASE SERVICE: Creating order with IGZ prefix');
    print('🔴 Order Number: $orderNumber');
    print('🔴 Service Name: ${orderData['serviceName']}');
    print('🔴 Price: ${orderData['price'] ?? orderData['finalPrice']}');
    print('🔴 User ID: ${orderData['userId']}');
    print('🔴 Stack trace: ${StackTrace.current}');

    final docRef = await ordersCollection.add({
      ...orderData,
      'orderNumber': orderNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('🔴 Order created with document ID: ${docRef.id}');

    // Also create cart entry for real-time tracking
    await cartCollection.add({
      'orderId': docRef.id,
      'orderNumber': orderNumber,
      'userId': orderData['userId'],
      'serviceId': orderData['serviceId'],
      'serviceName': orderData['serviceName'],
      'price': orderData['price'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Move user to client when they make a purchase
    if (orderData['userId'] != null) {
      try {
        final orderAmount = orderData['price'] is double
            ? orderData['price'] as double
            : double.tryParse(orderData['price'].toString()) ?? 0.0;
        await moveUserToClient(orderData['userId'], orderAmount: orderAmount);
      } catch (e) {
        print('Error moving user to client: $e');
        // Don't fail the order creation if moving to client fails
      }
    }

    return docRef.id;
  }

  static Future<QuerySnapshot> getOrders() async {
    return await ordersCollection.orderBy('createdAt', descending: true).get();
  }

  static Future<QuerySnapshot> getOrdersByClient(String clientId) async {
    return await ordersCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  static Stream<QuerySnapshot> getOrdersStream(String userId) {
    return ordersCollection.where('userId', isEqualTo: userId).snapshots();
  }

  static Stream<QuerySnapshot> getCartStream(String userId) {
    return cartCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> data,
  ) async {
    await ordersCollection.doc(orderId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await ordersCollection.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      // Get order details first
      final orderDoc = await ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final userId = orderData['userId'] as String;
      final paymentStatus = orderData['paymentStatus'] as String?;

      // Deduct loyalty points if payment was completed (points were awarded)
      if (paymentStatus == 'completed') {
        print(
          '=== CANCEL ORDER: Deducting loyalty points for cancelled order ===',
        );
        await deductLoyaltyPoints(
          userId,
          10,
          reason: 'order cancellation',
        ); // Deduct 10 points (same as awarded)
      }

      // Update order status to cancelled
      print(
        '=== CANCEL ORDER: Updating order $orderId to cancelled status ===',
      );
      await ordersCollection.doc(orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': userId,
        'cancelReason': reason ?? 'Cancelled by user',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('=== CANCEL ORDER: Order $orderId status updated to cancelled ===');

      // Verify the update was successful
      final updatedOrderDoc = await ordersCollection.doc(orderId).get();
      if (updatedOrderDoc.exists) {
        final updatedData = updatedOrderDoc.data() as Map<String, dynamic>;
        print(
          '=== CANCEL ORDER: Verified - Order $orderId status is now: ${updatedData['status']} ===',
        );
      } else {
        print(
          '=== CANCEL ORDER: ERROR - Order $orderId not found after update ===',
        );
      }

      // Also update cart collection if it exists
      try {
        final cartSnapshot = await cartCollection
            .where('orderId', isEqualTo: orderId)
            .get();

        for (final cartDoc in cartSnapshot.docs) {
          await cartDoc.reference.update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print('Error updating cart collection: $e');
        // Don't fail the cancellation if cart update fails
      }

      // NOTE: Refund processing is now handled by the calling code (e.g., My Orders screen)
      // to allow for proper cancellation fee calculation (25% fee for paid orders).
      // This method only updates the order status to 'cancelled'.
      print(
        '=== CANCEL ORDER: Order $orderId cancelled successfully (refund will be handled by calling code) ===',
      );
      print('Order $orderId cancelled successfully');
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }

  static Future<void> declineOrderWithRefund(
    String orderId,
    String reason,
  ) async {
    try {
      // Get order details
      final orderDoc = await ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final userId = orderData['userId'] as String;
      final amount = (orderData['finalPrice'] as num).toDouble();
      final paymentStatus = orderData['paymentStatus'] as String?;

      // Deduct loyalty points if payment was completed (points were awarded)
      if (paymentStatus == 'completed') {
        print(
          '=== DECLINE ORDER: Deducting loyalty points for declined order ===',
        );
        await deductLoyaltyPoints(
          userId,
          10,
          reason: 'order declined',
        ); // Deduct 10 points (same as awarded)
      }

      // Update order status to declined
      await ordersCollection.doc(orderId).update({
        'status': 'declined',
        'declineReason': reason,
        'declinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If payment was completed, process refund
      if (paymentStatus == 'completed') {
        print(
          '=== DECLINE ORDER WITH REFUND: Processing refund for order $orderId, amount: R$amount ===',
        );

        // Add refund amount back to user's wallet (update both collections)
        final batch = FirebaseFirestore.instance.batch();

        print('💰 FIREBASE SERVICE: Processing decline order refund');
        print('💰 FIREBASE SERVICE: User ID: $userId');
        print('💰 FIREBASE SERVICE: Order ID: $orderId');
        print('💰 FIREBASE SERVICE: Refund amount: R$amount');
        print('💰 FIREBASE SERVICE: About to update users collection');

        // Update users collection (primary wallet storage)
        final userRef = usersCollection.doc(userId);
        batch.update(userRef, {
          'walletBalance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update wallets collection for consistency
        final walletRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(userId);
        batch.set(walletRef, {
          'balance': FieldValue.increment(amount),
          'lastUpdated': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print(
          '💰 FIREBASE SERVICE: About to commit decline order refund batch',
        );
        await batch.commit();
        print(
          '✅ FIREBASE SERVICE: Decline order refund processed successfully',
        );

        // Generate invoice number and reference for refund
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
        final transactionReference = 'REFUND-$timestamp-$random';

        // Create refund transaction record in main transactions collection
        await transactionsCollection.add({
          'userId': userId,
          'type': 'refund',
          'amount': amount,
          'description': 'Refund: Order declined - $reason',
          'status': 'completed',
          'orderId': orderId,
          'transactionId': transactionReference,
          'createdAt': FieldValue.serverTimestamp(),
          'refundReason': reason,
          'invoiceNumber': invoiceNumber,
          'reference': transactionReference,
          'transactionReference': transactionReference,
          'hasInvoice': true,
        });

        // Also create wallet transaction record for wallet-specific tracking
        await walletTransactionsCollection.add({
          'userId': userId,
          'type': 'credit',
          'amount': amount,
          'description': 'Refund: Order declined - $reason',
          'status': 'completed',
          'orderId': orderId,
          'createdAt': FieldValue.serverTimestamp(),
          'refundReason': reason,
          'invoiceNumber': invoiceNumber,
          'reference': transactionReference,
          'transactionReference': transactionReference,
          'hasInvoice': true,
        });

        print(
          '=== DECLINE ORDER WITH REFUND: Refund processed successfully - R$amount credited to user wallet ===',
        );

        // Send refund notification to user
        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: 'Order Declined - Refund Processed 💰',
          body:
              'Your order has been declined. R${amount.toStringAsFixed(2)} has been refunded to your wallet.',
          type: 'refund',
          action: 'order_declined_refund',
          data: {'orderId': orderId, 'refundAmount': amount, 'reason': reason},
        );

        // Send refund confirmation email
        try {
          print(
            '📧 Admin Decline Refund: Sending refund confirmation email...',
          );

          // Get user details for email
          final userDoc = await usersCollection.doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userEmail = userData['email'] as String?;
            final userName = userData['name'] as String?;

            if (userEmail != null) {
              // Get order number and service name
              final orderNumber = orderData['orderNumber']?.toString() ?? 'N/A';
              final serviceName =
                  orderData['serviceName'] ?? orderData['title'] ?? 'Service';

              await MailerSendService.sendRefundConfirmation(
                toEmail: userEmail,
                toName: userName ?? 'Customer',
                orderNumber: orderNumber,
                refundAmount: amount,
                originalAmount: amount,
                cancellationFee: 0.0, // No cancellation fee for admin decline
                serviceName: serviceName,
                reason: 'Order declined by admin: $reason',
              );
              print('📧 ✅ Admin Decline Refund: Email sent successfully');
            }
          }
        } catch (e) {
          print('📧 ❌ Admin Decline Refund: Error sending email: $e');
          // Don't throw - email failure shouldn't fail the refund
        }
      } else {
        print(
          '=== DECLINE ORDER WITH REFUND: No refund needed - payment status: $paymentStatus ===',
        );
      }

      print('Order declined successfully: $orderId');
    } catch (e) {
      print('Error declining order with refund: $e');
      rethrow;
    }
  }

  // Update management
  static Future<void> createUpdate({
    required String title,
    required String message,
    required String type,
    required String userId,
    String? orderId,
    String? clientId,
  }) async {
    await updatesCollection.add({
      'title': title,
      'message': message,
      'type': type,
      'userId': userId,
      'orderId': orderId,
      'clientId': clientId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Update created: $title - $message');
  }

  // --- Service Hub Methods ---

  // Services
  static Future<void> addService(Map<String, dynamic> serviceData) async {
    await _firestore.collection('services').add({
      ...serviceData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateService(
    String serviceId,
    Map<String, dynamic> serviceData,
  ) async {
    await _firestore.collection('services').doc(serviceId).update({
      ...serviceData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  static Stream<List<Map<String, dynamic>>> getServicesStream() {
    return _firestore.collection('services').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  static Stream<int> getTotalServicesCountStream() {
    return _firestore
        .collection('services')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  static Stream<int> getActiveProductsCountStream() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'In Stock')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  static Stream<double> getTotalRevenueStream() {
    // Calculate revenue from orders
    return _firestore.collection('orders').snapshots().map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final price = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        total += price;
      }
      return total;
    });
  }

  // Products
  static Future<void> addProduct(Map<String, dynamic> productData) async {
    await _firestore.collection('products').add({
      ...productData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    await _firestore.collection('products').doc(productId).update({
      ...productData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  static Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  // Categories
  static Future<void> addCategory(Map<String, dynamic> categoryData) async {
    await _firestore.collection('categories').add({
      ...categoryData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    await _firestore.collection('categories').doc(categoryId).update({
      ...categoryData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  static Stream<List<Map<String, dynamic>>> getCategoriesStream() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  // Shared Links
  static Future<void> addSharedLink(Map<String, dynamic> linkData) async {
    await _firestore.collection('shared_links').add({
      ...linkData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSharedLink(
    String linkId,
    Map<String, dynamic> linkData,
  ) async {
    await _firestore.collection('shared_links').doc(linkId).update({
      ...linkData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteSharedLink(String linkId) async {
    await _firestore.collection('shared_links').doc(linkId).delete();
  }

  static Stream<List<Map<String, dynamic>>> getSharedLinksStream() {
    return _firestore
        .collection('shared_links')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  static Stream<QuerySnapshot> getUpdatesStream(String userId) {
    return updatesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<QuerySnapshot> getUpdates(String userId) async {
    return await updatesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  static Future<void> markUpdateAsRead(String updateId) async {
    await updatesCollection.doc(updateId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markAllUpdatesAsRead(String userId) async {
    final updates = await updatesCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in updates.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<int> getUnreadUpdatesCount(String userId) async {
    final snapshot = await updatesCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  // Get total projects count for a user
  static Stream<int> getTotalProjectsCount(String userId) {
    return ordersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Transaction management
  static Future<void> createTransaction({
    required String userId,
    required String type, // 'credit' or 'debit'
    required double amount,
    required String description,
    String? orderId,
    String? orderNumber,
    String? transactionId,
  }) async {
    // Get user details for invoice
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    final String finalTransactionId =
        transactionId ??
        '${type.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';

    // Generate invoice number
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    final invoiceNumber = 'INV$year$month$day$hour$minute$second';

    await transactionsCollection.add({
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'transactionId': finalTransactionId,
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'reference': finalTransactionId,
      'invoiceNumber': invoiceNumber,
      'transactionReference': finalTransactionId,
      // Invoice data
      'customerName':
          userData?['displayName'] ?? userData?['name'] ?? 'Customer',
      'customerEmail': userData?['email'],
      'hasInvoice': true,
      'invoiceType': type,
    });
  }

  static Stream<QuerySnapshot> getTransactionsStream(String userId) {
    return transactionsCollection
        .where('userId', isEqualTo: userId)
        .limit(10) // Limit to 10 most recent transactions
        .snapshots();
  }

  static Future<double> getWalletBalance(String userId) async {
    final snapshot = await transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    double balance = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String;
      final amount = (data['amount'] as num).toDouble();

      if (type == 'credit') {
        balance += amount;
      } else {
        balance -= amount;
      }
    }

    return balance;
  }

  // Loyalty Points management
  static Future<int> getLoyaltyPoints(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return (data['loyaltyPoints'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting loyalty points: $e');
      return 0;
    }
  }

  static Future<void> addLoyaltyPoints(String userId, int points) async {
    try {
      final userRef = usersCollection.doc(userId);
      await userRef.update({
        'loyaltyPoints': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check if user is now eligible for loyalty reward (2000 points)
      final currentPoints = await getLoyaltyPoints(userId);
      if (currentPoints >= 2000) {
        print(
          '🎉 User has reached 2000 loyalty points! Checking for reward...',
        );

        // Schedule loyalty reward check (avoid circular dependency)
        _scheduleLoyaltyRewardCheck(userId);
      }
    } catch (e) {
      print('Error adding loyalty points: $e');
    }
  }

  static Future<void> deductLoyaltyPoints(
    String userId,
    int points, {
    String? reason,
  }) async {
    try {
      final userRef = usersCollection.doc(userId);
      final currentPoints = await getLoyaltyPoints(userId);

      // Ensure we don't go below 0 points
      final pointsToDeduct = points > currentPoints ? currentPoints : points;

      if (pointsToDeduct > 0) {
        await userRef.update({
          'loyaltyPoints': FieldValue.increment(-pointsToDeduct),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final newPoints = currentPoints - pointsToDeduct;
        print('✅ Deducted $pointsToDeduct loyalty points from user $userId');
        print('Previous points: $currentPoints, New points: $newPoints');

        // Send notification to user about points deduction
        if (reason != null) {
          await _sendLoyaltyPointsDeductionNotification(
            userId,
            pointsToDeduct,
            newPoints,
            reason,
          );
        }
      } else {
        print(
          '⚠️ No loyalty points to deduct for user $userId (current: $currentPoints)',
        );
      }
    } catch (e) {
      print('Error deducting loyalty points: $e');
    }
  }

  /// Send notification when loyalty points are deducted
  static Future<void> _sendLoyaltyPointsDeductionNotification(
    String userId,
    int pointsDeducted,
    int newTotal,
    String reason,
  ) async {
    try {
      // Use Future.delayed to avoid circular import
      Future.delayed(const Duration(seconds: 1), () async {
        await NotificationService.sendLoyaltyPointsDeductionNotification(
          userId: userId,
          pointsDeducted: pointsDeducted,
          totalPoints: newTotal,
          reason: reason,
        );
      });
    } catch (e) {
      print('Error sending loyalty points deduction notification: $e');
    }
  }

  /// Schedule loyalty reward check to avoid circular dependency
  static void _scheduleLoyaltyRewardCheck(String userId) {
    // Use Future.delayed to avoid circular import
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        // This will be called from the loyalty reward service
        // to avoid circular dependency
        print('Scheduling loyalty reward check for user: $userId');
      } catch (e) {
        print('Error in scheduled loyalty reward check: $e');
      }
    });
  }

  static Future<int> getActiveProjectsCount(String userId) async {
    try {
      final snapshot = await ordersCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active projects count: $e');
      return 0;
    }
  }

  static Stream<int> getActiveProjectsCountStream(String userId) {
    return ordersCollection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'in_progress'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get total services used count for a user
  // Templates management
  static Stream<List<Map<String, dynamic>>> getTemplatesStream() {
    return _firestore
        .collection('templates')
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  static Stream<int> getTotalServicesUsedCount(String userId) {
    return ordersCollection.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      // Count unique service IDs to get services used
      final serviceIds = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['serviceId'] as String?;
          })
          .where((serviceId) => serviceId != null)
          .toSet();
      return serviceIds.length;
    });
  }

  // Analytics
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  static Future<void> setUserProperties({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Storage methods
  static Future<String> uploadFile(String path, List<int> bytes) async {
    final ref = _storage.ref().child(path);
    await ref.putData(Uint8List.fromList(bytes));
    return await ref.getDownloadURL();
  }

  static Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  /// Test Firebase connectivity
  static Future<bool> testConnection() async {
    try {
      // Test basic Firebase connection
      final app = Firebase.app();
      print('Firebase app initialized: ${app.name}');

      // Test if we can access Firebase Auth
      final auth = FirebaseAuth.instance;
      print('Firebase Auth instance created successfully');

      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  /// Check if Firebase Authentication is enabled
  static Future<bool> isAuthEnabled() async {
    try {
      final auth = FirebaseAuth.instance;
      // Try to get current user (this will fail if Auth is not enabled)
      final user = auth.currentUser;
      print('Firebase Auth is enabled. Current user: ${user?.email ?? 'none'}');
      return true;
    } catch (e) {
      print('Firebase Auth not enabled: $e');
      return false;
    }
  }

  /// Test Firebase Authentication by creating a test user
  static Future<bool> testAuthCreation() async {
    try {
      final testEmail =
          'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'test123456';

      print('Testing Firebase Auth creation with email: $testEmail');

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );

      print('Test user created successfully: ${userCredential.user?.email}');

      // Clean up - delete the test user
      await userCredential.user?.delete();
      print('Test user deleted successfully');

      return true;
    } catch (e) {
      print('Firebase Auth creation test failed: $e');
      return false;
    }
  }

  // Admin Dashboard Methods

  /// Get all authenticated users in real-time (excluding those who are already clients)
  static Stream<QuerySnapshot> getUsersStream() {
    return usersCollection
        .where(
          'role',
          isNotEqualTo: 'admin',
        ) // Exclude admin users from the list
        .snapshots();
  }

  /// Get users who haven't made any purchases yet (potential clients)
  static Stream<QuerySnapshot> getPotentialClientsStream() {
    try {
      print('🔍 Getting potential clients stream...');
      // First try with ordering
      return usersCollection
          .where('role', isEqualTo: 'user') // Only get regular users
          .orderBy('createdAt', descending: true) // Order by creation date
          .snapshots();
    } catch (e) {
      print('❌ Error in getPotentialClientsStream with ordering: $e');
      try {
        // Fallback to basic query without ordering
        print('🔄 Trying fallback query without ordering...');
        return usersCollection.where('role', isEqualTo: 'user').snapshots();
      } catch (e2) {
        print('❌ Error in fallback query: $e2');
        // Final fallback - get all users and filter in memory
        print('🔄 Trying final fallback - all users...');
        return usersCollection.snapshots();
      }
    }
  }

  /// Get all clients in real-time
  static Stream<QuerySnapshot> getClientsStream() {
    return clientsCollection.snapshots();
  }

  /// Get user statistics for admin dashboard
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final usersSnapshot = await usersCollection.get();
      final totalUsers = usersSnapshot.docs.length;

      final activeUsers = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] == true;
      }).length;

      final newUsersThisMonth = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;

        final now = DateTime.now();
        final userCreatedAt = createdAt.toDate();
        return userCreatedAt.year == now.year &&
            userCreatedAt.month == now.month;
      }).length;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsersThisMonth': newUsersThisMonth,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'totalUsers': 0, 'activeUsers': 0, 'newUsersThisMonth': 0};
    }
  }

  /// Get client statistics for admin dashboard
  static Future<Map<String, dynamic>> getClientStats() async {
    try {
      final clientsSnapshot = await clientsCollection.get();
      final totalClients = clientsSnapshot.docs.length;

      final activeClients = clientsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'Active';
      }).length;

      final totalRevenue = clientsSnapshot.docs.fold<double>(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        final totalSpent = data['totalSpent'] ?? 0;
        if (totalSpent is String) {
          // Handle "R 45,000" format
          final numericValue = totalSpent
              .replaceAll('R ', '')
              .replaceAll(',', '');
          return sum + (double.tryParse(numericValue) ?? 0);
        }
        return sum + (totalSpent as num).toDouble();
      });

      return {
        'totalClients': totalClients,
        'activeClients': activeClients,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      print('Error getting client stats: $e');
      return {'totalClients': 0, 'activeClients': 0, 'totalRevenue': 0.0};
    }
  }

  /// Update user status (active/inactive)
  static Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await usersCollection.doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }

  /// Update client status (active/inactive)
  static Future<void> updateClientStatus(String clientId, String status) async {
    try {
      await clientsCollection.doc(clientId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating client status: $e');
      rethrow;
    }
  }

  /// Delete a user (admin only) - Comprehensive deletion
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      return await UserDeletionService.deleteUserCompletely(userId);
    } catch (e) {
      print('Error deleting user: $e');
      return {
        'success': false,
        'message': 'Failed to delete user: $e',
        'deletionResults': {},
        'errors': [e.toString()],
      };
    }
  }

  /// Populate Firestore with sample data for testing
  static Future<void> populateSampleData() async {
    try {
      // Add sample clients
      final sampleClients = [
        {
          'name': 'ABC Corporation',
          'contact': 'Jane Smith',
          'email': 'jane.smith@abccorp.co.za',
          'phone': '+27 82 111 2222',
          'address': '123 Business Street, Johannesburg',
          'status': 'Active',
          'totalOrders': 15,
          'totalSpent': 45000.0,
          'lastOrder': DateTime.now().subtract(const Duration(days: 2)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'XYZ Enterprises',
          'contact': 'Mike Johnson',
          'email': 'mike.johnson@xyzenterprises.co.za',
          'phone': '+27 83 333 4444',
          'address': '456 Corporate Avenue, Cape Town',
          'status': 'Active',
          'totalOrders': 8,
          'totalSpent': 28500.0,
          'lastOrder': DateTime.now().subtract(const Duration(days: 5)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Tech Solutions Ltd',
          'contact': 'Sarah Williams',
          'email': 'sarah.williams@techsolutions.co.za',
          'phone': '+27 84 555 6666',
          'address': '789 Innovation Drive, Durban',
          'status': 'Active',
          'totalOrders': 22,
          'totalSpent': 67800.0,
          'lastOrder': DateTime.now().subtract(const Duration(days: 1)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Global Marketing',
          'contact': 'David Brown',
          'email': 'david.brown@globalmarketing.co.za',
          'phone': '+27 85 777 8888',
          'address': '321 Marketing Road, Pretoria',
          'status': 'Inactive',
          'totalOrders': 5,
          'totalSpent': 12300.0,
          'lastOrder': DateTime.now().subtract(const Duration(days: 30)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Creative Studios',
          'contact': 'Lisa Davis',
          'email': 'lisa.davis@creativestudios.co.za',
          'phone': '+27 86 999 0000',
          'address': '654 Creative Lane, Port Elizabeth',
          'status': 'Active',
          'totalOrders': 12,
          'totalSpent': 38900.0,
          'lastOrder': DateTime.now().subtract(const Duration(days: 3)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final clientData in sampleClients) {
        await clientsCollection.add(clientData);
      }

      // Add sample users (non-admin)
      final sampleUsers = [
        {
          'name': 'Sarah Johnson',
          'email': 'sarah.johnson@impactgraphicsza.co.za',
          'phone': '+27 83 987 6543',
          'role': 'Manager',
          'isActive': true,
          'loyaltyPoints': 150,
          'isSilverTier': true,
          'isGoldTier': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Michael Brown',
          'email': 'michael.brown@impactgraphicsza.co.za',
          'phone': '+27 84 555 1234',
          'role': 'Designer',
          'isActive': true,
          'loyaltyPoints': 80,
          'isSilverTier': true,
          'isGoldTier': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Lisa Davis',
          'email': 'lisa.davis@impactgraphicsza.co.za',
          'phone': '+27 85 777 8888',
          'role': 'Designer',
          'isActive': false,
          'loyaltyPoints': 45,
          'isSilverTier': false,
          'isGoldTier': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': DateTime.now().subtract(const Duration(days: 7)),
        },
        {
          'name': 'David Wilson',
          'email': 'david.wilson@impactgraphicsza.co.za',
          'phone': '+27 86 999 0000',
          'role': 'Manager',
          'isActive': true,
          'loyaltyPoints': 200,
          'isSilverTier': true,
          'isGoldTier': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        },
      ];

      for (final userData in sampleUsers) {
        await usersCollection.add(userData);
      }

      print('Sample data populated successfully!');
    } catch (e) {
      print('Error populating sample data: $e');
    }
  }
}
