import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/firebase_service.dart';
import '../services/mailersend_service.dart';
import '../services/notification_service.dart';

class MyOrdersScreen extends StatefulWidget {
  final String? orderId;
  final VoidCallback? onBackPressed;

  const MyOrdersScreen({super.key, this.orderId, this.onBackPressed});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All Orders';

  final List<String> _filterOptions = [
    'All Orders',
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    // If orderId is provided, show order details after the widget is built
    if (widget.orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchAndShowOrderDetails(widget.orderId!);
      });
    }
  }

  Future<void> _fetchAndShowOrderDetails(String orderId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final orderDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists && mounted) {
        final orderData = orderDoc.data();
        if (orderData == null) return;
        _showOrderDetailsDialog(orderId, orderData);
      }
    } catch (e) {
      // print('Error fetching order details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading order details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your orders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If onBackPressed callback is provided (tab navigation), use it
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              // Always navigate to dashboard and clear navigation stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              );
            }
          },
          tooltip: 'Back to Dashboard',
        ),
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _filterOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      if (_selectedFilter == option) ...[
                        const Icon(Icons.check, color: Color(0xFF8B0000)),
                        const SizedBox(width: 8),
                      ],
                      Text(option),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Orders list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allOrders = snapshot.data?.docs ?? [];

                // Apply client-side filtering
                List<QueryDocumentSnapshot> orders;
                if (_selectedFilter == 'All Orders') {
                  orders = allOrders;
                } else {
                  String status = _selectedFilter.toLowerCase().replaceAll(
                    ' ',
                    '_',
                  );
                  orders = allOrders.where((order) {
                    final orderData = order.data() as Map<String, dynamic>;
                    return orderData['status'] == status;
                  }).toList();
                }

                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your orders will appear here once you place them',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    return _buildOrderCard(order.id, orderData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream(String userId) {
    // First get all orders for the user, then filter client-side
    Query query = _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> orderData) {
    final status = orderData['status'] ?? 'pending';
    final serviceName = orderData['serviceName'] ?? 'Unknown Service';
    final finalPrice = orderData['finalPrice'] ?? orderData['price'] ?? 0.0;
    final createdAt = orderData['createdAt'] as Timestamp?;
    final orderNumber = orderData['orderNumber'] ?? orderId;
    final pictureCount = orderData['pictureCount'];

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status.toUpperCase();
    }

    return GestureDetector(
      onTap: () => _showOrderDetailsDialog(orderId, orderData),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'R${finalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Order details
              Text(
                'Order: $orderNumber',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                serviceName,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              // Picture count for Poster Design
              if (pictureCount != null && pictureCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Pictures: $pictureCount',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Text(
                createdAt != null
                    ? 'Ordered: ${_formatDate(createdAt.toDate())}'
                    : 'Date: Unknown',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              // Cancel button for pending, accepted, and in_progress orders
              if (status == 'pending' ||
                  status == 'accepted' ||
                  status == 'in_progress') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelOrderDialog(
                      orderId,
                      orderNumber,
                      finalPrice,
                      status,
                      orderData, // Pass full order data
                    ),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showCancelOrderDialog(
    String orderId,
    String orderNumber,
    double finalPrice,
    String status,
    Map<String, dynamic> orderData,
  ) {
    // print('=== CANCEL ORDER DIALOG ===');
    // print('Order ID: $orderId');
    // print('Order Number: $orderNumber');
    // print('Final Price: R${finalPrice.toStringAsFixed(2)}');
    // print('Status: $status');
    // print('Payment Status: ${orderData['paymentStatus']}');

    // Check if order has been paid - check both status and paymentStatus field
    final String? paymentStatus = orderData['paymentStatus'];
    final bool isPaidOrder =
        (status == 'accepted' ||
        status == 'in_progress' ||
        paymentStatus == 'completed');

    // print(
    //      'Is Paid Order: $isPaidOrder (based on status: $status, paymentStatus: $paymentStatus)',
    //    );

    final double cancellationFee = isPaidOrder ? finalPrice * 0.25 : 0.0;
    final double refundAmount = isPaidOrder ? finalPrice * 0.75 : finalPrice;

    // print('Cancellation Fee: R${cancellationFee.toStringAsFixed(2)}');
    // print('Refund Amount: R${refundAmount.toStringAsFixed(2)}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel order $orderNumber?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Show cancellation fee warning for paid orders
              if (isPaidOrder) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Cancellation Fee',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Since this order is ${status == 'in_progress' ? 'in progress' : 'accepted'}, a 25% cancellation fee will be applied.',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order Amount:'),
                          Text(
                            'R${finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cancellation Fee (25%):'),
                          Text(
                            '-R${cancellationFee.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Refund Amount:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'R${refundAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The refund amount will be credited to your wallet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ] else ...[
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelOrder(
                  orderId,
                  orderNumber,
                  finalPrice,
                  isPaidOrder,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOrder(
    String orderId,
    String orderNumber,
    double finalPrice,
    bool isPaidOrder,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Calculate refund if it's a paid order
      double refundAmount = 0.0;
      double cancellationFee = 0.0;

      if (isPaidOrder) {
        cancellationFee = finalPrice * 0.25;
        refundAmount = finalPrice * 0.75;

        // print('=== PROCESSING REFUND ===');
        // print('User ID: ${currentUser.uid}');
        // print('Order ID: $orderId');
        // print('Original Amount: R${finalPrice.toStringAsFixed(2)}');
        // print('Cancellation Fee (25%): R${cancellationFee.toStringAsFixed(2)}');
        // print('Refund Amount (75%): R${refundAmount.toStringAsFixed(2)}');

        // Process refund to wallet
        // print('Updating wallet balance...');
        // print('Wallet path: wallets/${currentUser.uid}');

        try {
          print('=== PROCESSING ORDER CANCELLATION REFUND ===');
          print('User ID: ${currentUser.uid}');
          print('Order ID: $orderId');
          print('Original Amount: R${finalPrice.toStringAsFixed(2)}');
          print(
            'Cancellation Fee (25%): R${cancellationFee.toStringAsFixed(2)}',
          );
          print('Refund Amount (75%): R${refundAmount.toStringAsFixed(2)}');
          print('=== STARTING ORDER CANCELLATION REFUND PROCESS ===');

          // Update both wallets and users collections for consistency
          final batch = _firestore.batch();

          // Update wallets collection
          final walletRef = _firestore
              .collection('wallets')
              .doc(currentUser.uid);
          batch.set(walletRef, {
            'balance': FieldValue.increment(refundAmount),
            'lastUpdated': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Update users collection (this is what the wallet screen reads from)
          final userRef = _firestore.collection('users').doc(currentUser.uid);
          batch.update(userRef, {
            'walletBalance': FieldValue.increment(refundAmount),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('💰 MY ORDERS: About to commit wallet refund batch');
          print('💰 MY ORDERS: Refund amount: R$refundAmount');
          print('💰 MY ORDERS: User ID: ${currentUser.uid}');
          print('💰 MY ORDERS: Order ID: $orderId');
          await batch.commit();
          print(
            '✅ MY ORDERS: Wallet balance updated in both collections successfully',
          );

          // Verify the update
          final userDoc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            print(
              'Current user wallet balance: R${userData?['walletBalance']}',
            );
          } else {
            print('⚠️ User document does not exist!');
          }
        } catch (walletError) {
          print('❌ Error updating wallet: $walletError');
          rethrow;
        }

        // Record the refund transaction in MAIN transactions collection (not subcollection)
        // print('Recording refund transaction...');
        final transactionRef = await _firestore.collection('transactions').add({
          'userId': currentUser.uid,
          'type': 'refund',
          'amount': refundAmount,
          'description':
              'Refund for cancelled order $orderNumber (25% cancellation fee applied)',
          'orderId': orderId,
          'orderNumber': orderNumber,
          'cancellationFee': cancellationFee,
          'originalAmount': finalPrice,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'completed',
          'reference': 'REFUND-${DateTime.now().millisecondsSinceEpoch}',
          'transactionId':
              'REFUND-$orderId-${DateTime.now().millisecondsSinceEpoch}',
          // Invoice data
          'customerName': currentUser.displayName ?? 'Customer',
          'customerEmail': currentUser.email,
          'hasInvoice': true,
          'invoiceType': 'refund',
        });

        // print(
        //          '✅ Refund transaction recorded successfully with ID: ${transactionRef.id}',
        //        );

        // Send refund notification to user
        await NotificationService.sendNotificationToUser(
          userId: currentUser.uid,
          title: 'Order Cancelled - Refund Processed 💰',
          body:
              'Your order has been cancelled. R${refundAmount.toStringAsFixed(2)} has been refunded to your wallet (25% cancellation fee applied).',
          type: 'refund',
          action: 'order_cancelled_refund',
          data: {
            'orderId': orderId,
            'orderNumber': orderNumber,
            'refundAmount': refundAmount,
            'cancellationFee': cancellationFee,
            'originalAmount': finalPrice,
          },
        );

        // Send refund confirmation email
        try {
          print('📧 Refund: Sending refund confirmation email...');
          if (currentUser.email != null) {
            // Get order details for email
            final orderDoc = await _firestore
                .collection('orders')
                .doc(orderId)
                .get();

            String serviceName = 'Service';
            if (orderDoc.exists) {
              final data = orderDoc.data() as Map<String, dynamic>;
              serviceName = data['serviceName'] ?? data['title'] ?? 'Service';
            }

            await MailerSendService.sendRefundConfirmation(
              toEmail: currentUser.email!,
              toName: currentUser.displayName ?? 'Customer',
              orderNumber: orderNumber,
              refundAmount: refundAmount,
              originalAmount: finalPrice,
              cancellationFee: cancellationFee,
              serviceName: serviceName,
              reason: 'Cancelled by customer',
            );
            print('📧 ✅ Refund: Email sent successfully');
          }
        } catch (e) {
          print('📧 ❌ Refund: Error sending email: $e');
          // Don't throw - email failure shouldn't fail the cancellation
        }
      }

      // Cancel the order
      print('🛑 MY ORDERS: Cancelling order $orderId');
      print('🛑 MY ORDERS: Order amount: R$finalPrice');
      print('🛑 MY ORDERS: Refund amount: R$refundAmount');
      print('🛑 MY ORDERS: Cancellation fee: R$cancellationFee');
      await FirebaseService.cancelOrder(orderId, reason: 'Cancelled by user');
      print('🛑 MY ORDERS: Order cancelled successfully');

      // Remove corresponding cart item if it exists
      try {
        final cartSnapshot = await _firestore
            .collection('carts')
            .doc(currentUser.uid)
            .collection('items')
            .where('orderId', isEqualTo: orderId)
            .get();

        for (final cartDoc in cartSnapshot.docs) {
          await cartDoc.reference.delete();
          print(
            '=== MY ORDERS: Removed cart item ${cartDoc.id} for cancelled order $orderId ===',
          );
        }
      } catch (e) {
        print(
          '=== MY ORDERS: Error removing cart item for order $orderId: $e ===',
        );
        // Don't fail the cancellation if cart removal fails
      }

      // Send notification to admin
      await NotificationService.sendAdminNotification(
        title: 'Order Cancelled',
        body: isPaidOrder
            ? '${currentUser.displayName ?? 'User'} cancelled order $orderNumber. R${refundAmount.toStringAsFixed(2)} refunded (R${cancellationFee.toStringAsFixed(2)} cancellation fee)'
            : '${currentUser.displayName ?? 'User'} cancelled order $orderNumber',
        action: 'order_cancelled',
        data: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'userId': currentUser.uid,
          'isPaidOrder': isPaidOrder,
          if (isPaidOrder) ...{
            'refundAmount': refundAmount,
            'cancellationFee': cancellationFee,
            'originalAmount': finalPrice,
          },
        },
      );

      // Send cancellation confirmation to user (if not paid, since paid orders already got refund notification)
      if (!isPaidOrder) {
        await NotificationService.sendNotificationToUser(
          userId: currentUser.uid,
          title: 'Order Cancelled',
          body: 'Your order $orderNumber has been cancelled successfully.',
          type: 'order',
          action: 'order_cancelled',
          data: {'orderId': orderId, 'orderNumber': orderNumber},
        );
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPaidOrder
                  ? 'Order cancelled. R${refundAmount.toStringAsFixed(2)} refunded to wallet'
                  : 'Order cancelled successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetailsDialog(String orderId, Map<String, dynamic> orderData) {
    final status = orderData['status'] ?? 'pending';
    final serviceName = orderData['serviceName'] ?? 'Unknown Service';
    final description =
        orderData['description'] ??
        orderData['projectDescription'] ??
        'No description provided';
    final finalPrice = orderData['finalPrice'] ?? orderData['price'] ?? 0.0;
    final createdAt = orderData['createdAt'] as Timestamp?;
    final orderNumber = orderData['orderNumber'] ?? orderId;
    final pictureCount = orderData['pictureCount'];

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status.toUpperCase();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B0000),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              orderNumber,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Status Section
                        _buildDialogSection(
                          'Order Status',
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Order Information Section
                        _buildDialogSection(
                          'Order Information',
                          Column(
                            children: [
                              _buildInfoRow('Order Number', orderNumber),
                              _buildInfoRow('Order ID', orderId),
                              _buildInfoRow(
                                'Order Date',
                                createdAt != null
                                    ? _formatDate(createdAt.toDate())
                                    : 'Unknown',
                              ),
                              _buildInfoRow('Service', serviceName),
                              _buildInfoRow('Description', description),
                              if (pictureCount != null && pictureCount > 0)
                                _buildInfoRow(
                                  'Pictures',
                                  pictureCount.toString(),
                                ),
                              _buildInfoRow(
                                'Amount',
                                'R${finalPrice.toStringAsFixed(2)}',
                                isAmount: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Cancel button for pending, accepted, and in_progress orders
                      if (status == 'pending' ||
                          status == 'accepted' ||
                          status == 'in_progress') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop(); // Close details dialog
                              _showCancelOrderDialog(
                                orderId,
                                orderNumber,
                                finalPrice,
                                status,
                                orderData, // Pass full order data
                              );
                            },
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Cancel Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Close button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF8B0000),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isAmount ? const Color(0xFF8B0000) : Colors.white,
                fontSize: 14,
                fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
