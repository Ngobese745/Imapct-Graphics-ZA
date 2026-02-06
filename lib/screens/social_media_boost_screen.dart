import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/mailersend_service.dart';
import '../services/notification_service.dart';
import '../services/split_payment_service.dart';
import 'split_payment_screen.dart';

class SocialMediaBoostScreen extends StatefulWidget {
  const SocialMediaBoostScreen({super.key});

  @override
  State<SocialMediaBoostScreen> createState() => _SocialMediaBoostScreenState();
}

class _SocialMediaBoostScreenState extends State<SocialMediaBoostScreen> {
  String selectedPlatform = 'youtube';
  String selectedService = 'subscribers';
  int quantity = 100;
  final TextEditingController _accountLinkController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // YouTube pricing (per 100 units)
  final Map<String, double> youtubePricing = {
    'subscribers': 180.0, // R180 per 100 subscribers
    'views': 130.0, // R130 per 100 views
    'likes': 110.0, // R110 per 100 likes
    'shares': 90.0, // R90 per 100 shares
    'watch_time': 800.0, // R800 per 200 hours
  };

  // Facebook pricing (per 100 units)
  final Map<String, double> facebookPricing = {
    'likes': 110.0, // R110 per 100 likes
    'followers': 130.0, // R130 per 100 followers
    'shares': 90.0, // R90 per 100 shares
  };

  @override
  void dispose() {
    _accountLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _calculatePrice() {
    final pricing = selectedPlatform == 'youtube'
        ? youtubePricing
        : facebookPricing;
    final basePrice = pricing[selectedService] ?? 0.0;

    // For watch_time, the base unit is 200 hours
    if (selectedService == 'watch_time') {
      return (quantity / 200) * basePrice;
    }

    // For all other services, calculate based on quantity / 100
    return (quantity / 100) * basePrice;
  }

  List<String> _getAvailableServices() {
    if (selectedPlatform == 'youtube') {
      return ['subscribers', 'views', 'likes', 'shares', 'watch_time'];
    } else {
      return ['likes', 'followers', 'shares'];
    }
  }

  String _getServiceDisplayName(String service) {
    switch (service) {
      case 'subscribers':
        return 'Subscribers';
      case 'views':
        return 'Views';
      case 'likes':
        return 'Likes';
      case 'shares':
        return 'Shares';
      case 'watch_time':
        return 'Watch Time (Hours)';
      case 'followers':
        return 'Followers';
      default:
        return service;
    }
  }

  int _getMinQuantity() {
    return selectedService == 'watch_time' ? 200 : 100;
  }

  int _getMaxQuantity() {
    return selectedService == 'watch_time' ? 2000 : 10000;
  }

  int _getStepSize() {
    return selectedService == 'watch_time' ? 200 : 100;
  }

  Future<void> _addToCart() async {
    // Validate account link
    if (_accountLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide your account link'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    // Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Show dialog for guest users
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: const Color(0xFF8B0000),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Account Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To add items to cart, you need to create an account or sign in.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[800],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create an account to access all features and save your progress!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.login, size: 18),
                label: const Text(
                  'Sign In / Create Account',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    // Get user profile data for proper customer name
    final userProfile = AuthService.instance?.userProfile;
    final userName = userProfile?['name'] as String?;
    final userEmail = userProfile?['email'] as String?;

    final price = _calculatePrice();
    final platform = selectedPlatform == 'youtube' ? 'YouTube' : 'Facebook';
    final serviceName =
        'Social Media Boost - $platform - ${_getServiceDisplayName(selectedService)}';
    final projectDescription =
        'Account: ${_accountLinkController.text.trim()}\nNotes: ${_notesController.text.trim()}\nQuantity: $quantity';

    // Create cart item
    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: serviceName,
      description: projectDescription,
      price: price,
      quantity: 1,
      image: 'assets/images/logo.png',
      serviceId: 'social_media_boost',
      projectDescription: projectDescription,
      orderId: null,
      orderStatus: 'pending',
      timestamp: DateTime.now(),
    );

    try {
      // Add to cart
      await CartService.addItem(cartItem, currentUser.uid);
      print('Cart item added successfully');
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: $e'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    // Try to create order in Firestore
    try {
      final orderData = {
        'userId': currentUser.uid,
        'customerName':
            userName ?? currentUser.displayName ?? 'Unknown Customer',
        'customerEmail': userEmail ?? currentUser.email ?? 'No email',
        'serviceId': 'social_media_boost',
        'serviceName': serviceName,
        'title': serviceName,
        'serviceType': 'Social Media Boost',
        'platform': platform,
        'boostService': selectedService,
        'quantity': quantity,
        'accountLink': _accountLinkController.text.trim(),
        'notes': _notesController.text.trim(),
        'serviceDescription':
            'Platform: $platform | Service: ${_getServiceDisplayName(selectedService)} | Quantity: $quantity',
        'projectDescription': projectDescription,
        'originalPrice': price,
        'finalPrice': price,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final orderId = await FirebaseService.createOrder(orderData);
      print('Order created in Firestore with ID: $orderId');

      // Update cart item with order ID
      try {
        await CartService.updateCartItemOrderId(
          cartItem.id,
          orderId,
          currentUser.uid,
        );
        print('Cart item updated with order ID: $orderId');
      } catch (e) {
        print('Error updating cart item with order ID: $e');
      }

      // Send notification to admin about new order
      await NotificationService.sendNewOrderNotificationToAdmin(
        orderId: orderId,
        customerName: currentUser.displayName ?? 'Customer',
        serviceName: serviceName,
        amount: price,
      );

      // Create update notification for admin
      await FirebaseService.createUpdate(
        title: 'New Order Created',
        message:
            '$serviceName order created with price: R${price.toStringAsFixed(2)}',
        type: 'order_created',
        userId: currentUser.uid,
        orderId: orderId,
      );

      // Send notification to user about cart addition
      await NotificationService.sendNotificationToUser(
        userId: currentUser.uid,
        title: 'Order Added to Cart! 🛒',
        body: 'Your $serviceName order has been added to cart successfully.',
        type: 'order',
        action: 'order_added',
        data: {'orderId': orderId, 'serviceName': serviceName, 'amount': price},
      );
    } catch (e) {
      print('Error creating order: $e');
      // Cart item was added successfully, order creation is optional
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$serviceName added to cart'),
          backgroundColor: const Color(0xFF8B0000),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to cart - will be handled by main app
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _payNow() async {
    // Validate account link
    if (_accountLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide your account link'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    // Check Firebase Auth first (this persists on web)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to make a payment'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    final userId = currentUser.uid;

    // Get user profile - if not loaded yet, fetch directly from Firestore
    var userProfile = AuthService.instance?.userProfile;
    if (userProfile == null) {
      print('⚠️ User profile not loaded yet, fetching from Firestore...');
      try {
        final profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (profileDoc.exists) {
          userProfile = profileDoc.data();
        }
      } catch (e) {
        print('❌ Error loading user profile: $e');
      }
    }

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load user information. Please try again.'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    final userEmail = userProfile['email'] as String?;
    final userName = userProfile['name'] as String?;
    final userPhone = userProfile['phone'] as String?;

    if (userEmail == null || userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User information incomplete. Please try again.'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    final price = _calculatePrice();
    final platform = selectedPlatform == 'youtube' ? 'YouTube' : 'Facebook';
    final serviceName =
        'Social Media Boost - $platform - ${_getServiceDisplayName(selectedService)}';
    final projectDescription =
        'Account: ${_accountLinkController.text.trim()}\nNotes: ${_notesController.text.trim()}\nQuantity: $quantity';

    // Apply Gold Tier discount if applicable
    final isGoldTierActive = userProfile['goldTierActive'] ?? false;
    final goldTierStatus = userProfile['goldTierStatus'] ?? 'inactive';
    final hasGoldTierDiscount =
        isGoldTierActive &&
        (goldTierStatus == 'active' || goldTierStatus == 'trial');

    double finalPrice = price;
    if (hasGoldTierDiscount) {
      final discountAmount = finalPrice * 0.10;
      finalPrice = finalPrice - discountAmount;
    }

    // Create cart item for the service (order will be created after payment)
    final cartItem = CartItem(
      id: 'social_boost_${DateTime.now().millisecondsSinceEpoch}',
      name: serviceName,
      price: finalPrice,
      quantity: 1,
      description: projectDescription,
      image: 'assets/images/logo.png',
      timestamp: DateTime.now(),
      orderId: null, // Will be set after successful payment
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF8B0000)),
              SizedBox(width: 20),
              Text(
                'Processing payment...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );

    // Process split payment
    final splitResult = await SplitPaymentService.processSplitPayment(
      totalAmount: finalPrice,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone ?? '',
      cartItems: [cartItem],
    );

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    if (!splitResult.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(splitResult.error ?? 'Payment failed'),
            backgroundColor: const Color(0xFF8B0000),
          ),
        );
      }
      return;
    }

    // Handle different payment scenarios
    if (splitResult.isWalletOnly) {
      // Wallet payment only - create order after payment verification
      try {
        final transactionId = 'WALLET-${DateTime.now().millisecondsSinceEpoch}';

        // Create order after successful wallet payment
        final orderData = {
          'userId': currentUser.uid,
          'customerName':
              userName ?? currentUser.displayName ?? 'Unknown Customer',
          'customerEmail': userEmail ?? currentUser.email ?? 'No email',
          'serviceId': 'social_media_boost',
          'serviceName': serviceName,
          'title': serviceName,
          'serviceType': 'Social Media Boost',
          'platform': platform,
          'boostService': selectedService,
          'quantity': quantity,
          'accountLink': _accountLinkController.text.trim(),
          'notes': _notesController.text.trim(),
          'serviceDescription':
              'Platform: $platform | Service: ${_getServiceDisplayName(selectedService)} | Quantity: $quantity',
          'projectDescription': projectDescription,
          'originalPrice': price,
          'finalPrice': finalPrice,
          'status': 'completed',
          'paymentStatus': 'completed',
          'transactionId': transactionId,
          'paidAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final orderId = await FirebaseService.createOrder(orderData);
        print('Order created after wallet payment with ID: $orderId');

        // Create wallet transaction record for recent transactions
        await FirebaseFirestore.instance.collection('wallet_transactions').add({
          'userId': currentUser.uid,
          'type': 'debit',
          'amount': finalPrice,
          'description': 'Payment for $serviceName',
          'status': 'completed',
          'orderId': orderId,
          'transactionId': transactionId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('💰 Wallet transaction created for recent transactions');

        // Send notifications
        await NotificationService.sendNewOrderNotificationToAdmin(
          orderId: orderId,
          customerName: currentUser.displayName ?? 'Customer',
          serviceName: serviceName,
          amount: finalPrice,
        );

        await NotificationService.sendPaymentSuccessWithWhatsApp(
          userId: currentUser.uid,
          transactionId: transactionId,
          amount: finalPrice,
          orderId: orderId,
          serviceName: serviceName,
        );

        // Send payment confirmation email
        try {
          if (currentUser.email != null) {
            await MailerSendService.sendPaymentConfirmation(
              toEmail: currentUser.email!,
              toName: currentUser.displayName ?? 'Customer',
              transactionId: transactionId,
              amount: finalPrice,
              serviceName: serviceName,
              orderNumber: orderId,
              paymentMethod: 'Wallet',
            );
            print('📧 Payment confirmation email sent successfully');
          }
        } catch (e) {
          print('📧 Error sending payment confirmation email: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Order placed.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        print('Error creating order after wallet payment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment processed but order creation failed: $e'),
              backgroundColor: const Color(0xFF8B0000),
            ),
          );
        }
      }
    } else {
      // Requires Paystack payment - navigate to split payment screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SplitPaymentScreen(
              paystackAuthorizationUrl:
                  splitResult.paystackAuthorizationUrl ?? '',
              paystackReference: splitResult.paystackReference ?? '',
              paystackAmount: splitResult.paystackAmount,
              walletAmount: splitResult.walletAmount,
              userId: userId,
              userEmail: userEmail,
              userName: userName,
              userPhone: userPhone ?? '',
              totalAmount: finalPrice,
              cartItems: [cartItem],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Media Boost'),
        backgroundColor: const Color(0xFF8B0000),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Selection
            const Text(
              'Select Platform',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPlatformButton(
                    'youtube',
                    'YouTube',
                    Icons.play_circle_filled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlatformButton(
                    'facebook',
                    'Facebook',
                    Icons.facebook,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Service Selection
            const Text(
              'Select Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildServiceDropdown(),

            const SizedBox(height: 24),

            // Pricing Information
            _buildPricingInfo(),

            const SizedBox(height: 24),

            // Quantity Selector
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildQuantitySelector(),

            const SizedBox(height: 24),

            // Total Price Display
            _buildTotalPrice(),

            const SizedBox(height: 24),

            // Account Link Input
            const Text(
              'Account Link',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildAccountLinkInfo(),
            const SizedBox(height: 12),
            TextField(
              controller: _accountLinkController,
              decoration: InputDecoration(
                hintText: selectedPlatform == 'youtube'
                    ? 'https://youtube.com/@yourchannel or video link'
                    : 'https://facebook.com/yourpage or post link',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 24),

            // Additional Notes
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Any specific requirements or preferences',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Delivery Timeline Info
            _buildDeliveryInfo(),

            const SizedBox(height: 24),

            // Action Buttons Row
            Row(
              children: [
                // Add to Cart Button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addToCart,
                      icon: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Pay Now Button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _payNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Pay Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton(String platform, String label, IconData icon) {
    final isSelected = selectedPlatform == platform;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlatform = platform;
          // Reset to first available service when platform changes
          selectedService = _getAvailableServices().first;
          // Reset quantity to minimum
          quantity = _getMinQuantity();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B0000) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B0000) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedService,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _getAvailableServices().map((service) {
            return DropdownMenuItem(
              value: service,
              child: Text(_getServiceDisplayName(service)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedService = value!;
              // Reset quantity to minimum for the new service
              quantity = _getMinQuantity();
            });
          },
        ),
      ),
    );
  }

  Widget _buildPricingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B0000).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF8B0000)),
              const SizedBox(width: 8),
              const Text(
                'Pricing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedPlatform == 'youtube') ...[
            _buildPriceRow('R180', '100 Subscribers'),
            _buildPriceRow('R130', '100 Views'),
            _buildPriceRow('R110', '100 Likes'),
            _buildPriceRow('R90', '100 Shares'),
            _buildPriceRow('R800', '200 Watch Time Hours'),
          ] else ...[
            _buildPriceRow('R110', '100 Likes'),
            _buildPriceRow('R130', '100 Followers'),
            _buildPriceRow('R90', '100 Shares'),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String price, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(description, style: const TextStyle(fontSize: 14)),
          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    final minQty = _getMinQuantity();
    final maxQty = _getMaxQuantity();
    final step = _getStepSize();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: quantity > minQty
                    ? () {
                        setState(() {
                          quantity = (quantity - step).clamp(minQty, maxQty);
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove_circle),
                color: const Color(0xFF8B0000),
                iconSize: 32,
              ),
              Text(
                quantity.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
              IconButton(
                onPressed: quantity < maxQty
                    ? () {
                        setState(() {
                          quantity = (quantity + step).clamp(minQty, maxQty);
                        });
                      }
                    : null,
                icon: const Icon(Icons.add_circle),
                color: const Color(0xFF8B0000),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: quantity.toDouble(),
            min: minQty.toDouble(),
            max: maxQty.toDouble(),
            divisions: (maxQty - minQty) ~/ step,
            activeColor: const Color(0xFF8B0000),
            label: quantity.toString(),
            onChanged: (value) {
              setState(() {
                quantity = (value ~/ step) * step;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: $minQty',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Max: $maxQty',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPrice() {
    final price = _calculatePrice();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB22222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Price',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'R${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getServiceDisplayName(selectedService),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountLinkInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to get your link:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (selectedPlatform == 'youtube') ...[
                  Text(
                    selectedService == 'subscribers'
                        ? '• Go to your YouTube channel\n• Copy the channel URL (e.g., youtube.com/@yourname)'
                        : '• Open the video you want to boost\n• Copy the video URL from the address bar',
                    style: TextStyle(color: Colors.blue[800], fontSize: 12),
                  ),
                ] else ...[
                  Text(
                    selectedService == 'followers'
                        ? '• Go to your Facebook page\n• Copy the page URL from the address bar'
                        : '• Open the post you want to boost\n• Click the three dots (...) > Copy link',
                    style: TextStyle(color: Colors.blue[800], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Delivery Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.check_circle,
            'Count starts within 24 hours of order confirmation',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.timer, 'Completion time: 24 hours - 7 days'),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.speed,
            'Delivery speed depends on quantity requested',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.verified,
            'All services are organic and platform-compliant',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.orange[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.orange[900]),
          ),
        ),
      ],
    );
  }
}
