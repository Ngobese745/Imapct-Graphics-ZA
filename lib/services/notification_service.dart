import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Notification Types Enum
enum NotificationType {
  orderUpdate,
  paymentReceived,
  projectCompleted,
  newService,
  systemUpdate,
  adminMessage,
  invoiceGenerated,
  membershipUpdate,
  general,
  orderCreated,
  userUpgrade,
  chatSupport,
  paymentSuccess,
  goldTierUpgrade,
}

// Notification Priority Enum
enum NotificationPriority { low, medium, high, urgent }

// Notification Item Model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final String? userId;
  final String? orderId;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
    this.userId,
    this.orderId,
    this.metadata,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (priority) => priority.name == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      userId: map['userId'],
      orderId: map['orderId'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'userId': userId,
      'orderId': orderId,
      'metadata': metadata,
    };
  }
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // App state tracking
  static bool _isAppInForeground = true;
  static AppLifecycleState _currentAppState = AppLifecycleState.resumed;

  // Getters for app state (needed for external access)
  static bool get isAppInForeground => _isAppInForeground;
  static AppLifecycleState get currentAppState => _currentAppState;

  // Notification channels
  static const String _generalChannel = 'general_notifications';
  static const String _orderChannel = 'order_notifications';
  static const String _paymentChannel = 'payment_notifications';
  static const String _updateChannel = 'update_notifications';
  static const String _adminChannel = 'admin_notifications';

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // print('=== NOTIFICATION SERVICE INITIALIZATION START ===');

      // Set up app lifecycle listener
      _setupAppLifecycleListener();

      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // print('User granted permission: ${settings.authorizationStatus}');
      // print('Authorization status: ${settings.authorizationStatus}');

      // Initialize local notifications
      await _initializeLocalNotifications();
      // print('Local notifications initialized');

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        // print('FCM Token: $token');
        await _saveTokenToDatabase(token);
        // print('FCM token saved to database');
      } else {
        // print('WARNING: FCM token is null');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        // print('FCM token refreshed: $newToken');
        _saveTokenToDatabase(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // print('=== FOREGROUND MESSAGE RECEIVED ===');
        // print('Message ID: ${message.messageId}');
        // print('Title: ${message.notification?.title}');
        // print('Body: ${message.notification?.body}');
        // print('Data: ${message.data}');
        _handleForegroundMessage(message);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // print('=== NOTIFICATION TAPPED ===');
        // print('Message ID: ${message.messageId}');
        // print('Data: ${message.data}');
        _handleNotificationTap(message);
      });

      // Check for initial notification (app opened from notification)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        // print('=== INITIAL MESSAGE FOUND ===');
        // print('Message ID: ${initialMessage.messageId}');
        // print('Data: ${initialMessage.data}');
        _handleNotificationTap(initialMessage);
      } else {
        // print('No initial message found');
      }

      // print('=== NOTIFICATION SERVICE INITIALIZATION COMPLETE ===');
    } catch (e) {
      // print('=== NOTIFICATION SERVICE INITIALIZATION ERROR ===');
      // print('Error: $e');
      // print('Error type: ${e.runtimeType}');
      // print('Stack trace: ${StackTrace.current}');

      // Handle macOS-specific APNS token error gracefully
      if (e.toString().contains('apns-token-not-set')) {
        // print(
        //          'APNS token not available on macOS - this is expected for desktop apps',
        //        );
      } else {
        // print('Error initializing notification service: $e');
      }
    }
  }

  // Set up app lifecycle listener
  static void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsMacOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permission for local notifications (Android)
    if (!kIsWeb && Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final permission = await androidImplementation
            .requestNotificationsPermission();
        print('🔔 Android local notification permission: $permission');
      }
    }

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          _generalChannel,
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.high,
        );

    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      _orderChannel,
      'Order Notifications',
      description: 'Order status updates and notifications',
      importance: Importance.high,
    );

    const AndroidNotificationChannel paymentChannel =
        AndroidNotificationChannel(
          _paymentChannel,
          'Payment Notifications',
          description: 'Payment confirmations and updates',
          importance: Importance.high,
        );

    const AndroidNotificationChannel updateChannel = AndroidNotificationChannel(
      _updateChannel,
      'Update Notifications',
      description: 'App updates and announcements',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel adminChannel = AndroidNotificationChannel(
      _adminChannel,
      'Admin Notifications',
      description: 'Administrative notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(orderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(paymentChannel);

    // print('=== PAYMENT CHANNEL CREATED ===');
    // print('Channel ID: $_paymentChannel');
    // print('Channel Name: Payment Notifications');

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(updateChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(adminChannel);
  }

  // Save FCM token to database
  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // print('=== SAVING FCM TOKEN ===');
        // print('User ID: ${user.uid}');
        // print('Token: ${token.substring(0, 20)}...');

        await _firestore.collection('users').doc(user.uid).set(
          {'fcmToken': token, 'lastTokenUpdate': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        ); // Use merge to avoid overwriting other fields

        // print('✅ FCM token saved successfully to Firestore');

        // Verify it was saved
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        final savedToken = userDoc.data()?['fcmToken'];
        // print('Verified saved token exists: ${savedToken != null}');
      } else {
        // print('⚠️ Cannot save FCM token: No user logged in');
      }
    } catch (e) {
      // print('❌ Error saving FCM token: $e');
      // print('Stack trace: ${StackTrace.current}');
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    // print('Received foreground message: ${message.messageId}');
    _showLocalNotification(message);
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // print('Received background message: ${message.messageId}');
    // Background messages are handled automatically by Firebase
  }

  // Handle notification taps
  static void _handleNotificationTap(RemoteMessage message) {
    // print('Notification tapped: ${message.messageId}');
    // Handle navigation based on notification type
    _handleNotificationNavigation(message);
  }

  // Handle local notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    // print('=== LOCAL NOTIFICATION TAPPED ===');
    // print('Action ID: ${response.actionId}');
    // print('Payload: ${response.payload}');
    // print('Notification ID: ${response.id}');

    // Handle action button clicks (Android)
    if (response.actionId == 'view_portfolio') {
      // print('View Portfolio action button clicked!');
      navigateToPortfolio({});
      return;
    }

    // Handle local notification navigation
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      // print('Parsed notification data: $data');
      _handleNotificationNavigation(RemoteMessage(data: data));
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      String channelId = _getChannelId(message.data);

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            channelDescription: _getChannelDescription(channelId),
            icon: android?.smallIcon ?? '@mipmap/launcher_icon',
            color: const Color(0xFF8B0000),
            priority: Priority.high,
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // Get channel ID based on notification type
  static String _getChannelId(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    String channelId;
    switch (type) {
      case 'order':
        channelId = _orderChannel;
        break;
      case 'payment':
        // Use general channel for payment notifications to ensure they work
        channelId = _generalChannel;
        break;
      case 'update':
        channelId = _updateChannel;
        break;
      case 'admin':
        channelId = _adminChannel;
        break;
      default:
        channelId = _generalChannel;
    }
    // print('=== CHANNEL ID SELECTION ===');
    // print('Type: $type');
    // print('Selected Channel ID: $channelId');
    return channelId;
  }

  // Get channel name
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case _orderChannel:
        return 'Order Notifications';
      case _paymentChannel:
        return 'Payment Notifications';
      case _updateChannel:
        return 'Update Notifications';
      case _adminChannel:
        return 'Admin Notifications';
      default:
        return 'General Notifications';
    }
  }

  // Get channel description
  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _orderChannel:
        return 'Order status updates and notifications';
      case _paymentChannel:
        return 'Payment confirmations and updates';
      case _updateChannel:
        return 'App updates and announcements';
      case _adminChannel:
        return 'Administrative notifications';
      default:
        return 'General app notifications';
    }
  }

  // Handle notification navigation
  static void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? 'general';
    final action = data['action'] ?? '';

    // print('=== NOTIFICATION NAVIGATION HANDLER ===');
    // print('Type: $type');
    // print('Action: $action');
    // print('Data: $data');

    switch (type) {
      case 'order':
        _handleOrderNotification(action, data);
        break;
      case 'payment':
        _handlePaymentNotification(action, data);
        break;
      case 'update':
        _handleUpdateNotification(action, data);
        break;
      case 'admin':
        _handleAdminNotification(action, data);
        break;
      case 'portfolio_update':
        // print('Portfolio update notification detected!');
        _handleGeneralNotification(action, data);
        break;
      default:
        // print('Default handler - calling _handleGeneralNotification');
        _handleGeneralNotification(action, data);
    }
  }

  // Handle order notifications
  static void _handleOrderNotification(
    String action,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'order_accepted':
        // Navigate to order details
        // print('Navigate to accepted order: ${data['orderId']}');
        break;
      case 'order_declined':
        // Navigate to order details
        // print('Navigate to declined order: ${data['orderId']}');
        break;
      case 'order_completed':
        // Navigate to order details
        // print('Navigate to completed order: ${data['orderId']}');
        break;
      default:
      // Navigate to orders screen
      // print('Navigate to orders screen');
    }
  }

  // Handle payment notifications
  static void _handlePaymentNotification(
    String action,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'payment_successful':
        // Navigate to transaction details
        // print('Navigate to successful payment: ${data['transactionId']}');
        break;
      case 'payment_success_with_whatsapp':
        // Show WhatsApp dialog for project details
        // print(
        //          'Show WhatsApp dialog for payment success: ${data['transactionId']}',
        //        );
        _showWhatsAppDialog(data);
        break;
      case 'payment_failed':
        // Navigate to payment retry
        // print('Navigate to failed payment: ${data['transactionId']}');
        break;
      default:
      // Navigate to wallet/transactions
      // print('Navigate to wallet screen');
    }
  }

  // Show WhatsApp dialog for project details
  static void _showWhatsAppDialog(Map<String, dynamic> data) {
    // This will be handled by the UI layer when the notification is tapped
    // print('=== SHOWING WHATSAPP DIALOG ===');
    // print('Transaction ID: ${data['transactionId']}');
    // print('Amount: ${data['amount']}');
    // print('Service: ${data['serviceName']}');
    // print('WhatsApp Message: ${data['whatsAppMessage']}');

    // Store the notification data globally so the UI can access it
    _pendingWhatsAppNotification = data;

    // Trigger the callback if it's set
    _whatsAppCallback?.call(data);
  }

  // Global variable to store pending WhatsApp notification
  static Map<String, dynamic>? _pendingWhatsAppNotification;

  // Callback function for WhatsApp notifications
  static Function(Map<String, dynamic>)? _whatsAppCallback;

  // Set callback for WhatsApp notifications
  static void setWhatsAppCallback(Function(Map<String, dynamic>) callback) {
    _whatsAppCallback = callback;
  }

  // Get pending WhatsApp notification and clear it
  static Map<String, dynamic>? getPendingWhatsAppNotification() {
    final notification = _pendingWhatsAppNotification;
    _pendingWhatsAppNotification = null; // Clear after getting
    return notification;
  }

  // Handle update notifications
  static void _handleUpdateNotification(
    String action,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'new_update':
        // Navigate to updates screen
        // print('Navigate to updates screen');
        break;
      case 'announcement':
        // Show announcement dialog
        // print('Show announcement: ${data['message']}');
        break;
      default:
      // Navigate to updates screen
      // print('Navigate to updates screen');
    }
  }

  // Handle admin notifications
  static void _handleAdminNotification(
    String action,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'new_user':
        // Navigate to admin users screen
        // print('Navigate to admin users screen');
        break;
      case 'new_order':
        // Navigate to admin orders screen
        // print('Navigate to admin orders screen');
        break;
      default:
      // Navigate to admin dashboard
      // print('Navigate to admin dashboard');
    }
  }

  // Handle general notifications
  static void _handleGeneralNotification(
    String action,
    Map<String, dynamic> data,
  ) {
    // print('=== GENERAL NOTIFICATION HANDLER ===');
    // print('Action: $action');
    // print('Callback set: ${_navigateToPortfolio != null}');

    switch (action) {
      case 'view_portfolio':
        // Navigate to Services Hub portfolio tab
        // print('View portfolio action detected!');
        // print('Calling navigation callback...');
        _navigateToPortfolio?.call(data);
        // print('Navigation callback called');
        break;
      default:
      // Navigate to main dashboard
      // print('Navigate to main dashboard (action: $action)');
    }
  }

  // Callback for portfolio navigation
  static void Function(Map<String, dynamic>)? _navigateToPortfolio;

  // Set portfolio navigation callback
  static void setPortfolioNavigationCallback(
    void Function(Map<String, dynamic>) callback,
  ) {
    _navigateToPortfolio = callback;
  }

  // Trigger portfolio navigation
  static void navigateToPortfolio([Map<String, dynamic>? data]) {
    _navigateToPortfolio?.call(data ?? {});
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? action,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('=== SEND NOTIFICATION TO USER ===');
      print('User ID: $userId');
      print('Title: $title');
      print('Type: $type');
      print('Action: $action');

      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ User not found: $userId');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'];
      final userEmail = userData['email'];
      final userName =
          userData['displayName'] ?? userData['name'] ?? 'Unknown User';

      print('📧 User Email: $userEmail');
      print('👤 User Name: $userName');
      print('🔑 FCM Token: ${fcmToken != null ? 'Present' : 'Missing'}');
      if (fcmToken != null) {
        print(
          '🔑 FCM Token (first 20 chars): ${fcmToken.toString().substring(0, fcmToken.toString().length > 20 ? 20 : fcmToken.toString().length)}...',
        );
      }

      // Save notification to Firestore updates collection so it appears in UpdatesScreen
      final updateRef = await _firestore.collection('updates').add({
        'title': title,
        'message': body,
        'type': type,
        'userId': userId,
        'action': action,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': data?['priority'] ?? 'medium',
        'urgent': data?['urgent'] ?? false,
      });

      print(
        '✅ Notification saved to Firestore updates collection with ID: ${updateRef.id}',
      );

      if (fcmToken == null) {
        print('⚠️ No FCM token for user: $userId');
        // Still show local notification even without FCM token
        await _showLocalNotificationFallback(title, body, type, action, data);
        return;
      }

      print('🔔 FCM Token: $fcmToken');
      print('🔔 FCM Token Length: ${fcmToken.toString().length}');
      print(
        '🔔 FCM Token (first 50 chars): ${fcmToken.toString().substring(0, fcmToken.toString().length > 50 ? 50 : fcmToken.toString().length)}...',
      );

      // FCM is not configured (server key is placeholder), so only send local notifications
      print('📱 FCM not configured, sending local notification only');
      await _showLocalNotificationFallback(title, body, type, action, data);
    } catch (e) {
      print('❌ Error sending notification to user: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
    }
  }

  // Send notification to all users
  static Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    required String type,
    String? action,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      for (final doc in usersSnapshot.docs) {
        final userId = doc.id;
        final userData = doc.data();
        final fcmToken = userData['fcmToken'];

        // Save notification to Firestore updates collection for each user
        await _firestore.collection('updates').add({
          'title': title,
          'message': body,
          'type': type,
          'userId': userId,
          'action': action,
          'data': data,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'priority': data?['priority'] ?? 'medium',
          'urgent': data?['urgent'] ?? false,
        });

        // Send FCM notification if token exists and app is in background
        if (fcmToken != null && !_isAppInForeground) {
          await _sendFCMNotification(
            token: fcmToken,
            title: title,
            body: body,
            type: type,
            action: action,
            data: data,
          );
        }
      }

      // print(
      //        'Notification saved to Firestore and sent to ${usersSnapshot.docs.length} users',
      //      );
    } catch (e) {
      // print('Error sending notification to all users: $e');
    }
  }

  // Send FCM notification using HTTP API directly
  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required String type,
    String? action,
    Map<String, dynamic>? data,
  }) async {
    try {
      // print('=== SENDING FCM PUSH NOTIFICATION VIA HTTP API ===');
      // print('Token: ${token.substring(0, 20)}...');
      // print('Title: $title');
      // print('Type: $type');

      // Get Firebase project server key (you need to add this to your Firebase project settings)
      const String serverKey =
          'YOUR_ACTUAL_FIREBASE_SERVER_KEY_HERE'; // TODO: Replace with actual server key from Firebase Console

      // Prepare FCM message payload
      final payload = {
        'to': token,
        'priority': 'high',
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'color': type == 'portfolio_update' ? '#9C27B0' : '#8B0000',
          'icon': '@mipmap/ic_launcher',
        },
        'data': {
          'type': type,
          'action': action ?? '',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          ...?data,
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channelId': _getChannelId({'type': type}),
            'color': type == 'portfolio_update' ? '#9C27B0' : '#8B0000',
            'sound': 'default',
            'tag': type,
            'sticky': false,
          },
        },
        'apns': {
          'headers': {'apns-priority': '10'},
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
                'subtitle': type == 'portfolio_update'
                    ? 'New Work Available'
                    : null,
              },
              'sound': 'default',
              'badge': 1,
              'mutable-content': 1,
              'content-available': 1,
              'interruption-level':
                  type == 'portfolio_update' || type == 'payment'
                  ? 'time-sensitive'
                  : 'active',
            },
          },
        },
      };

      // For now, send via local notification AND save for future FCM implementation
      // Once server key is configured, uncomment the HTTP request below
      // print(
      //        'Note: Using local notifications. To enable FCM, configure server key.',
      //      );
      await _showLocalNotificationFallback(title, body, type, action, data);

      /* Uncomment when server key is added:
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
// print('FCM notification sent successfully: ${response.body}');
      } else {
// print('FCM notification failed: ${response.statusCode} - ${response.body}');
        await _showLocalNotificationFallback(title, body, type, action, data);
      }
      */
    } catch (e) {
      // print('Error sending FCM notification: $e');
      // print('Falling back to local notification...');
      await _showLocalNotificationFallback(title, body, type, action, data);
    }
  }

  // Fallback local notification method
  static Future<void> _showLocalNotificationFallback(
    String title,
    String body,
    String type,
    String? action,
    Map<String, dynamic>? data,
  ) async {
    try {
      print('=== SENDING LOCAL NOTIFICATION ===');
      print('Title: $title');
      print('Body: $body');
      print('Type: $type');
      print('Action: $action');

      final notificationData = {'type': type, 'action': action, ...?data};

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );
      // print('Notification ID: $notificationId');

      // Determine if this is a payment notification for special handling
      final bool isPaymentNotification = type == 'payment';
      final bool isPortfolioNotification = type == 'portfolio_update';
      final bool isUrgent = notificationData['urgent'] == 'true';

      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _getChannelId(notificationData),
            _getChannelName(_getChannelId(notificationData)),
            channelDescription: _getChannelDescription(
              _getChannelId(notificationData),
            ),
            icon: 'ic_notification',
            color: isPaymentNotification
                ? const Color(0xFF00AA00)
                : isPortfolioNotification
                ? const Color(0xFF9C27B0) // Purple for portfolio
                : const Color(0xFF8B0000),
            priority: Priority.max,
            importance: Importance.max,
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
            enableVibration: true,
            playSound: true,
            autoCancel: false,
            ongoing: isPaymentNotification,
            fullScreenIntent: isPaymentNotification || isPortfolioNotification,
            category: isPortfolioNotification
                ? AndroidNotificationCategory.social
                : AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
            ticker: isPaymentNotification
                ? 'Payment Notification'
                : isPortfolioNotification
                ? 'New Portfolio Item'
                : 'App Notification',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/launcher_icon',
            ),
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              htmlFormatBigText: true,
              summaryText: isPortfolioNotification
                  ? '📸 View our latest work'
                  : null,
            ),
            actions: isPortfolioNotification
                ? <AndroidNotificationAction>[
                    const AndroidNotificationAction(
                      'view_portfolio',
                      'View Portfolio',
                      showsUserInterface: true,
                      cancelNotification: true,
                    ),
                  ]
                : null,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
            interruptionLevel: isPortfolioNotification || isPaymentNotification
                ? InterruptionLevel.timeSensitive
                : InterruptionLevel.active,
            subtitle: isPortfolioNotification ? 'New Work Available' : null,
          ),
        ),
        payload: json.encode(notificationData),
      );

      print('✅ Local notification sent with ID: $notificationId');
      print('=== LOCAL NOTIFICATION SENT SUCCESSFULLY ===');
    } catch (e) {
      print('❌ Error sending local notification fallback: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
    }
  }

  // Send portfolio item notification to all users
  static Future<void> sendPortfolioNotification({
    required String title,
    required String description,
    String? imageUrl,
  }) async {
    try {
      // print('=== SENDING PORTFOLIO NOTIFICATION TO ALL USERS ===');
      // print('Title: $title');
      // print('Description: $description');
      // print('Image: $imageUrl');

      await sendNotificationToAllUsers(
        title: '📸 New Portfolio Item Added!',
        body: 'Check out our latest work: $title',
        type: 'portfolio_update',
        action: 'view_portfolio',
        data: {
          'portfolioTitle': title,
          'portfolioDescription': description,
          'portfolioImage': imageUrl ?? '',
          'priority': 'high',
          'urgent': false,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // print('Portfolio notification sent successfully to all users');
    } catch (e) {
      // print('Error sending portfolio notification: $e');
    }
  }

  // Send order status notification
  static Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
    required String serviceName,
    String? paymentStatus, // Add payment status parameter
  }) async {
    String title, body, action;

    switch (status) {
      case 'accepted':
        // Check if order is already paid to send appropriate message
        if (paymentStatus == 'completed') {
          title = 'Order Accepted! 🎉';
          body =
              'Your $serviceName order has been accepted and we are now working on it!';
          action = 'order_accepted_paid';
        } else {
          title = 'Order Accepted! 🎉';
          body =
              'Your $serviceName order has been accepted and is ready for payment.';
          action = 'order_accepted';
        }
        break;
      case 'declined':
        title = 'Order Update';
        body =
            'Your $serviceName order has been declined. Please review and update.';
        action = 'order_declined';
        break;
      case 'completed':
        title = 'Order Completed! ✅';
        body = 'Your $serviceName order has been completed successfully.';
        action = 'order_completed';
        break;
      default:
        title = 'Order Update';
        body = 'Your $serviceName order status has been updated to $status.';
        action = 'order_update';
    }

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      type: 'order',
      action: action,
      data: {'orderId': orderId, 'status': status, 'serviceName': serviceName},
    );
  }

  // Send payment notification
  static Future<void> sendPaymentNotification({
    required String userId,
    required String transactionId,
    required String status,
    required double amount,
  }) async {
    // print('=== SENDING PAYMENT NOTIFICATION ===');
    // print('User ID: $userId');
    // print('Transaction ID: $transactionId');
    // print('Status: $status');
    // print('Amount: $amount');

    String title, body, action;

    switch (status) {
      case 'successful':
        title = 'Payment Successful! 💳';
        body =
            'Your payment of R${amount.toStringAsFixed(2)} has been processed successfully.';
        action = 'payment_successful';
        break;
      case 'failed':
        title = 'Payment Failed ❌';
        body =
            'Your payment of R${amount.toStringAsFixed(2)} has failed. Please try again.';
        action = 'payment_failed';
        break;
      default:
        title = 'Payment Update';
        body = 'Your payment status has been updated to $status.';
        action = 'payment_update';
    }

    // Send through the normal notification system like other notifications
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      type: 'payment',
      action: action,
      data: {
        'transactionId': transactionId,
        'status': status,
        'amount': amount,
        'priority': 'high',
        'urgent': 'true',
      },
    );

    // print('=== PAYMENT NOTIFICATION SENT ===');
  }

  // Send enhanced payment success notification with WhatsApp functionality
  static Future<void> sendPaymentSuccessWithWhatsApp({
    required String userId,
    required String transactionId,
    required double amount,
    String? orderId,
    String? serviceName,
  }) async {
    // print('=== SENDING ENHANCED PAYMENT SUCCESS NOTIFICATION ===');
    // print('User ID: $userId');
    // print('Transaction ID: $transactionId');
    // print('Amount: $amount');
    // print('Order ID: $orderId');
    // print('Service Name: $serviceName');

    // Create enhanced notification with WhatsApp action
    final title = 'Payment Successful! 🎉';
    final body =
        'Your payment of R${amount.toStringAsFixed(2)} has been processed successfully. Click to share project details via WhatsApp!';
    final action = 'payment_success_with_whatsapp';

    // Enhanced data payload for WhatsApp functionality
    final notificationData = {
      'transactionId': transactionId,
      'status': 'successful',
      'amount': amount,
      'orderId': orderId ?? '',
      'orderNumber': orderId ?? '', // Store order number for invoice and WhatsApp
      'serviceName': serviceName ?? '',
      'priority': 'high',
      'urgent': 'true',
      'hasWhatsAppAction': 'true',
      'whatsAppMessage': _generateWhatsAppMessage(amount, serviceName),
    };

    // Send in-app notification
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      type: 'payment_success',
      action: action,
      data: notificationData,
    );

    // Send push notification with enhanced payload
    await _sendEnhancedPushNotification(
      userId: userId,
      title: title,
      body: body,
      data: notificationData,
    );

    // print('=== ENHANCED PAYMENT NOTIFICATION SENT ===');
  }

  // Generate WhatsApp message template
  static String _generateWhatsAppMessage(double amount, String? serviceName) {
    final service = serviceName ?? 'service';
    final message =
        '''
Hi! I've successfully made a payment of R${amount.toStringAsFixed(2)} for $service.

I'd like to share my project details and pictures with you. Could you please guide me on how to proceed?

Thank you! 😊
''';
    return message;
  }

  // Send enhanced push notification with custom payload
  static Future<void> _sendEnhancedPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        // print('User document not found for FCM notification');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null) {
        // print('FCM token not found for user $userId');
        return;
      }

      // Send FCM notification with enhanced payload
      await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        type: 'payment_success',
        action: 'payment_success_with_whatsapp',
        data: data,
      );

      // print('Enhanced push notification sent to user $userId');
    } catch (e) {
      // print('Error sending enhanced push notification: $e');
    }
  }

  // Send update notification
  static Future<void> sendUpdateNotification({
    required String title,
    required String message,
    String? action,
    Map<String, dynamic>? data,
  }) async {
    await sendNotificationToAllUsers(
      title: title,
      body: message,
      type: 'update',
      action: action ?? 'new_update',
      data: data,
    );
  }

  // Send admin notification
  static Future<void> sendAdminNotification({
    required String title,
    required String body,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    // Get all admin users
    final adminUsersSnapshot = await _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .where('fcmToken', isNotEqualTo: null)
        .get();

    for (final doc in adminUsersSnapshot.docs) {
      final userData = doc.data();
      final fcmToken = userData['fcmToken'];

      if (fcmToken != null && !_isAppInForeground) {
        await _sendFCMNotification(
          token: fcmToken,
          title: title,
          body: body,
          type: 'admin',
          action: action,
          data: data,
        );
      }
    }

    // print(
    //      'Admin notification sent to ${adminUsersSnapshot.docs.length} admins',
    //    );
  }

  // Send new order notification to admin
  static Future<void> sendNewOrderNotificationToAdmin({
    required String orderId,
    required String customerName,
    required String serviceName,
    required double amount,
  }) async {
    await sendAdminNotification(
      title: 'New Order Received! 📦',
      body:
          '$customerName has placed a new $serviceName order for R${amount.toStringAsFixed(2)}',
      action: 'new_order',
      data: {
        'orderId': orderId,
        'customerName': customerName,
        'serviceName': serviceName,
        'amount': amount,
      },
    );
  }

  // Send loyalty points notification
  static Future<void> sendLoyaltyPointsNotification({
    required String userId,
    required int pointsEarned,
    required int totalPoints,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Loyalty Points Earned! ⭐',
      body:
          'You earned $pointsEarned loyalty points! Total points: $totalPoints',
      type: 'loyalty',
      action: 'points_earned',
      data: {'pointsEarned': pointsEarned, 'totalPoints': totalPoints},
    );
  }

  // Send loyalty points deduction notification
  static Future<void> sendLoyaltyPointsDeductionNotification({
    required String userId,
    required int pointsDeducted,
    required int totalPoints,
    required String reason,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Loyalty Points Deducted ⚠️',
      body:
          '$pointsDeducted loyalty points were deducted due to $reason. Total points: $totalPoints',
      type: 'loyalty',
      action: 'points_deducted',
      data: {
        'pointsDeducted': pointsDeducted,
        'totalPoints': totalPoints,
        'reason': reason,
      },
    );
  }

  // Send tier upgrade notification
  static Future<void> sendTierUpgradeNotification({
    required String userId,
    required String newTier,
    required String benefits,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Tier Upgraded! 🎉',
      body: 'Congratulations! You\'ve been upgraded to $newTier. $benefits',
      type: 'tier',
      action: 'tier_upgraded',
      data: {'newTier': newTier, 'benefits': benefits},
    );
  }

  // Send project completion notification
  static Future<void> sendProjectCompletionNotification({
    required String userId,
    required String projectName,
    required String orderId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Project Completed! ✅',
      body:
          'Your $projectName project has been completed and is ready for review.',
      type: 'project',
      action: 'project_completed',
      data: {'projectName': projectName, 'orderId': orderId},
    );
  }

  // Send welcome notification for new users
  static Future<void> sendWelcomeNotification({
    required String userId,
    required String userName,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Welcome to Impact Graphics ZA! 🎨',
      body:
          'Hi $userName! Welcome to our creative community. Start exploring our services!',
      type: 'welcome',
      action: 'welcome',
      data: {'userName': userName},
    );
  }

  // Send maintenance notification
  static Future<void> sendMaintenanceNotification({
    required String title,
    required String message,
    DateTime? scheduledTime,
  }) async {
    await sendNotificationToAllUsers(
      title: title,
      body: message,
      type: 'maintenance',
      action: 'maintenance',
      data: {'scheduledTime': scheduledTime?.toIso8601String()},
    );
  }

  // Send wallet funding notification
  static Future<void> sendWalletFundingNotification({
    required String userId,
    required double amount,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Wallet Funded Successfully! 💰',
      body:
          'R${amount.toStringAsFixed(2)} has been added to your wallet. You can now use these funds for purchases.',
      type: 'wallet',
      action: 'wallet_funded',
      data: {'amount': amount, 'fundingDate': DateTime.now().toIso8601String()},
    );
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get notification count
  static Future<int> getNotificationCount() async {
    // This would typically be stored in a database
    // For now, we'll return 0
    return 0;
  }

  // Admin Notification Methods
  static Future<void> createGlobalNotification({
    required String title,
    required String message,
    required NotificationType type,
    required NotificationPriority priority,
  }) async {
    try {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        priority: priority,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('admin_notifications')
          .add(notification.toMap());
      // print('Global notification created successfully');
    } catch (e) {
      // print('Error creating global notification: $e');
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .delete();
      // print('Notification deleted successfully');
    } catch (e) {
      // print('Error deleting notification: $e');
    }
  }

  static Stream<List<NotificationItem>> getUserNotifications() {
    // print('=== NOTIFICATION SERVICE DEBUG ===');
    // print('Getting user notifications from Firestore...');
    return _firestore
        .collection('admin_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          // print(
          //            'Firestore snapshot received: ${snapshot.docs.length} documents',
          //          );
          final notifications = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            // print('Processing notification: ${data['title']}');
            return NotificationItem.fromMap(data);
          }).toList();
          // print('Processed ${notifications.length} notifications');
          // print('=== END NOTIFICATION SERVICE DEBUG ===');
          return notifications;
        });
  }

  // Create sample admin notifications
  static Future<void> createSampleAdminNotifications() async {
    // print('=== CREATE SAMPLE NOTIFICATIONS DEBUG ===');
    // print('Creating sample admin notifications...');
    final sampleNotifications = [
      NotificationItem(
        id: '1',
        title: 'New Order Created',
        message:
            'Client Mbali Ngobese has created a new order for Starter Package - Logo Design',
        type: NotificationType.orderCreated,
        priority: NotificationPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        metadata: {
          'clientName': 'Mbali Ngobese',
          'orderId': 'ORD-20250810-5394',
          'package': 'Starter Package',
          'amount': 1500.0,
        },
      ),
      NotificationItem(
        id: '2',
        title: 'Payment Received Successfully',
        message:
            'Payment of R2,500.00 received from Smith Enterprises for Web Development project',
        type: NotificationType.paymentSuccess,
        priority: NotificationPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        metadata: {
          'clientName': 'Smith Enterprises',
          'orderId': 'ORD-20250810-5395',
          'amount': 2500.0,
          'paymentMethod': 'Credit Card',
        },
      ),
      NotificationItem(
        id: '3',
        title: 'Gold Tier Upgrade',
        message:
            'User palembali24@gmail.com has upgraded to Gold Tier membership',
        type: NotificationType.goldTierUpgrade,
        priority: NotificationPriority.medium,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        metadata: {
          'userEmail': 'palembali24@gmail.com',
          'previousTier': 'Silver',
          'newTier': 'Gold',
          'upgradeAmount': 299.0,
        },
      ),
      NotificationItem(
        id: '4',
        title: 'Chat Support Request',
        message:
            'New chat support request from Johnson Design Studio - Priority: High',
        type: NotificationType.chatSupport,
        priority: NotificationPriority.urgent,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        metadata: {
          'clientName': 'Johnson Design Studio',
          'issueType': 'Technical Support',
          'priority': 'High',
          'chatId': 'CHAT-20250810-001',
        },
      ),
      NotificationItem(
        id: '5',
        title: 'Project Completed',
        message:
            'Logo Design project for Williams Marketing has been completed successfully',
        type: NotificationType.projectCompleted,
        priority: NotificationPriority.medium,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        metadata: {
          'clientName': 'Williams Marketing',
          'projectName': 'Logo Design',
          'orderId': 'ORD-20250810-5396',
          'completionTime': '2 days ahead of schedule',
        },
      ),
      NotificationItem(
        id: '6',
        title: 'New User Registration',
        message:
            'New user registered: sarah@creativeagency.co.za - Creative Agency',
        type: NotificationType.userUpgrade,
        priority: NotificationPriority.low,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        metadata: {
          'userEmail': 'sarah@creativeagency.co.za',
          'companyName': 'Creative Agency',
          'registrationDate': DateTime.now()
              .subtract(const Duration(hours: 4))
              .toIso8601String(),
        },
      ),
      NotificationItem(
        id: '7',
        title: 'Invoice Generated',
        message:
            'Invoice #INV-20250810-001 generated for Premium Package - R5,000.00',
        type: NotificationType.invoiceGenerated,
        priority: NotificationPriority.medium,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        metadata: {
          'invoiceNumber': 'INV-20250810-001',
          'clientName': 'Tech Solutions Ltd',
          'amount': 5000.0,
          'package': 'Premium Package',
        },
      ),
      NotificationItem(
        id: '8',
        title: 'System Maintenance',
        message:
            'Scheduled system maintenance completed successfully. All services are operational.',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.low,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        metadata: {
          'maintenanceType': 'Scheduled',
          'duration': '30 minutes',
          'status': 'Completed',
        },
      ),
    ];

    try {
      final batch = _firestore.batch();

      for (final notification in sampleNotifications) {
        final docRef = _firestore.collection('admin_notifications').doc();
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
      // print('Sample admin notifications created successfully');
      // print('Batch committed to Firestore');
      // print('=== END CREATE SAMPLE NOTIFICATIONS DEBUG ===');
    } catch (e) {
      // print('Error creating sample admin notifications: $e');
      // print('Error stack trace: ${StackTrace.current}');
      // print('=== END CREATE SAMPLE NOTIFICATIONS DEBUG (ERROR) ===');
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isRead': true});
      // print('Notification marked as read');
    } catch (e) {
      // print('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    return _firestore
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

// App lifecycle observer
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update app state in NotificationService
    switch (state) {
      case AppLifecycleState.resumed:
        NotificationService._isAppInForeground = true;
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        NotificationService._isAppInForeground = false;
        break;
    }
    NotificationService._currentAppState = state;
    print('=== APP STATE CHANGED ===');
    print('New state: $state');
    print('Is in foreground: ${NotificationService._isAppInForeground}');
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // print('Handling background message: ${message.messageId}');
  // Background messages are handled automatically by Firebase
}
