import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'paystack_payment_screen.dart';
import '../main.dart' show CartItem;

class PackageManagementScreen extends StatefulWidget {
  const PackageManagementScreen({super.key});

  @override
  State<PackageManagementScreen> createState() =>
      _PackageManagementScreenState();
}

class _PackageManagementScreenState extends State<PackageManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Package Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _currentUserId == null
          ? const Center(
              child: Text(
                'Please log in to manage your package',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      'User data not found',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final activePackage = userData['activePackage'] ?? 'Starter';
                final packageStatus = userData['packageStatus'] ?? 'pending';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Package Card
                      _buildCurrentPackageCard(
                        activePackage,
                        packageStatus,
                        userData,
                      ),
                      const SizedBox(height: 24),

                      // Available Packages Section
                      const Text(
                        'Available Packages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAvailablePackages(activePackage),

                      const SizedBox(height: 24),

                      // Billing History Section
                      _buildBillingHistorySection(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCurrentPackageCard(
    String activePackage,
    String packageStatus,
    Map<String, dynamic> userData,
  ) {
    final packageDetails = _getPackageDetails(activePackage);
    final statusColor = _getStatusColor(packageStatus);
    final statusText = packageStatus.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            packageDetails['color'] as Color,
            (packageDetails['color'] as Color).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: packageDetails['color'] as Color, width: 2),
        boxShadow: [
          BoxShadow(
            color: (packageDetails['color'] as Color).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  packageDetails['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '📦 Active Package',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activePackage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Package Details
          _buildPackageDetail(
            'Monthly Cost',
            packageDetails['monthlyPrice'] as String,
            Icons.payments,
          ),
          const SizedBox(height: 12),
          _buildPackageDetail(
            'Setup Fee',
            packageDetails['setupFee'] as String,
            Icons.sell,
          ),
          const SizedBox(height: 12),
          _buildPackageDetail(
            'Next Billing',
            _getNextBillingDate(userData),
            Icons.calendar_today,
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelPackageDialog(activePackage),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUpgradeDialog(activePackage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: packageDetails['color'] as Color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.upgrade, size: 18),
                  label: const Text(
                    'Upgrade',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailablePackages(String currentPackage) {
    final packages = ['Starter', 'Growth', 'Premium'];

    return Column(
      children: packages.map((packageName) {
        final isActive = packageName == currentPackage;
        final details = _getPackageDetails(packageName);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPackageCard(packageName, details, isActive),
        );
      }).toList(),
    );
  }

  Widget _buildPackageCard(
    String packageName,
    Map<String, dynamic> details,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? details['color'] as Color : Colors.white10,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: (details['color'] as Color).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (details['color'] as Color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  details['icon'] as IconData,
                  color: details['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          packageName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      details['description'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pricing
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Setup Fee',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    details['setupFee'] as String,
                    style: TextStyle(
                      color: details['color'] as Color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    details['monthlyPrice'] as String,
                    style: TextStyle(
                      color: details['color'] as Color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Features
          ...((details['features'] as List<String>).take(3).map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: details['color'] as Color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),

          if (!isActive) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _switchPackage(packageName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: details['color'] as Color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _getUpgradeDowngradeText(packageName),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('billing_history')
              .orderBy('date', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                ),
              );
            }

            final bills = snapshot.data?.docs ?? [];

            if (bills.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white54, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No billing history yet',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: bills.map((bill) {
                final data = bill.data() as Map<String, dynamic>;
                return _buildBillingHistoryItem(data);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBillingHistoryItem(Map<String, dynamic> billData) {
    final amount = billData['amount'] ?? 0.0;
    final date = (billData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = billData['status'] ?? 'pending';
    final packageName = billData['packageName'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: status == 'paid'
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                  : const Color(0xFFFF9800).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status == 'paid' ? Icons.check_circle : Icons.pending,
              color: status == 'paid'
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packageName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'R${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF8B0000),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPackageDetails(String packageName) {
    switch (packageName) {
      case 'Starter':
        return {
          'color': const Color(0xFF4CAF50),
          'icon': Icons.rocket_launch,
          'description': 'Perfect for small businesses',
          'setupFee': 'R1500',
          'monthlyPrice': 'R500',
          'features': [
            'Basic social media management',
            'Monthly content calendar',
            'Email support',
            'Basic analytics',
          ],
        };
      case 'Growth':
        return {
          'color': const Color(0xFF8B0000),
          'icon': Icons.trending_up,
          'description': 'Ideal for growing businesses',
          'setupFee': 'R3000',
          'monthlyPrice': 'R800',
          'features': [
            'Advanced social media management',
            'Weekly content planning',
            'Priority support',
            'Advanced analytics & reporting',
            'SEO optimization',
          ],
        };
      case 'Premium':
        return {
          'color': const Color(0xFFFFD700),
          'icon': Icons.stars,
          'description': 'For established businesses',
          'setupFee': 'R5000',
          'monthlyPrice': 'R1500',
          'features': [
            'Full-service marketing',
            'Daily content management',
            '24/7 priority support',
            'Real-time analytics dashboard',
            'Dedicated account manager',
            'Custom campaigns',
          ],
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help,
          'description': 'Unknown package',
          'setupFee': 'N/A',
          'monthlyPrice': 'N/A',
          'features': <String>[],
        };
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getNextBillingDate(Map<String, dynamic> userData) {
    final nextBilling = userData['nextBillingDate'] as Timestamp?;
    if (nextBilling != null) {
      return _formatDate(nextBilling.toDate());
    }

    // Calculate from start date if available
    final createdAt = userData['createdAt'] as Timestamp?;
    if (createdAt != null) {
      final nextDate = createdAt.toDate().add(const Duration(days: 30));
      return _formatDate(nextDate);
    }

    return 'Not set';
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

  String _getUpgradeDowngradeText(String targetPackage) {
    return 'Switch to $targetPackage';
  }

  void _switchPackage(String newPackage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz, color: Color(0xFF8B0000)),
            SizedBox(width: 12),
            Text('Switch Package', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to switch to $newPackage package?\n\n'
          'Your current billing cycle will be adjusted accordingly.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performPackageSwitch(newPackage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Switch'),
          ),
        ],
      ),
    );
  }

  Future<void> _performPackageSwitch(String newPackage) async {
    try {
      // Get package pricing
      final packageDetails = _getPackageDetails(newPackage);
      final setupFee = double.parse(
        (packageDetails['setupFee'] as String).replaceAll('R', ''),
      );
      final monthlyPrice = double.parse(
        (packageDetails['monthlyPrice'] as String).replaceAll('R', ''),
      );

      // Only setup fee is required for payment
      final totalAmount = setupFee;

      // Show payment instructions dialog
      await _showPaymentInstructionsDialog(
        newPackage,
        setupFee,
        monthlyPrice,
        totalAmount,
      );
    } catch (e) {
      // print('Error initiating package switch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _proceedToPayment(
    String packageName,
    double setupFee,
    double monthlyPrice,
  ) async {
    try {
      // First, cancel the current active package
      await _cancelCurrentPackage();

      // Navigate to Paystack payment screen
      final paymentResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaystackPaymentScreen(
            cartItems: [
              CartItem(
                id: 'package_setup_${packageName.toLowerCase()}',
                name: '$packageName Package Setup',
                description:
                    'Setup fee for $packageName package. Monthly billing (R${monthlyPrice.toStringAsFixed(2)}) starts next month.',
                price: setupFee,
                quantity: 1,
                image: '',
              ),
            ],
            totalAmount: setupFee,
            userEmail: FirebaseAuth.instance.currentUser?.email ?? '',
            userName: FirebaseAuth.instance.currentUser?.displayName,
            userPhone: null,
            userId: _currentUserId,
            paymentType: 'package_setup',
          ),
        ),
      );

      // If payment was successful, activate the package
      if (paymentResult == true && mounted) {
        // Get transaction reference from latest payment
        await _activatePackageAfterPayment(packageName, monthlyPrice);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$packageName package activated! Monthly billing starts next month.',
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        // Payment was cancelled or failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled. Package switch not completed.'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // print('Error processing payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activatePackageAfterPayment(
    String packageName,
    double monthlyPrice,
  ) async {
    try {
      // Calculate monthly billing start date (first day of next month)
      final now = DateTime.now();
      final nextMonth = DateTime(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        1,
      );

      // Create delayed subscription for monthly billing
      final subscriptionRef = await _firestore
          .collection('delayed_subscriptions')
          .add({
            'userId': _currentUserId,
            'packageName': packageName,
            'monthlyAmount': monthlyPrice,
            'status': 'pending_activation',
            'activationDate': Timestamp.fromDate(nextMonth),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update user's active package
      await _firestore.collection('users').doc(_currentUserId).update({
        'activePackage': packageName,
        'packageStatus': 'active',
        'packageActivationDate': FieldValue.serverTimestamp(),
        'monthlyBillingStartDate': Timestamp.fromDate(nextMonth),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print(
      //        'Package activated: $packageName. Monthly billing starts ${_formatDate(nextMonth)}',
      //      );

      // Grant monthly credits immediately upon activation with 30-day expiration
      if (_currentUserId != null) {
        final creditAmount = _getCreditAmount(packageName);
        final expirationDate = DateTime.now().add(const Duration(days: 30));

        await _grantPackageCreditsWithExpiry(
          packageName,
          creditAmount,
          monthlyPrice,
          expirationDate,
        );

        // Show credit notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 R${creditAmount.toStringAsFixed(0)} credited! Expires in 30 days.',
              ),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // print('Error activating package after payment: $e');
      rethrow;
    }
  }

  double _getCreditAmount(String packageName) {
    switch (packageName) {
      case 'Starter':
        return 750.0;
      case 'Growth':
        return 1500.0;
      case 'Premium':
        return 2500.0;
      default:
        return 0.0;
    }
  }

  Future<void> _grantPackageCreditsWithExpiry(
    String packageName,
    double creditAmount,
    double monthlyPrice,
    DateTime expirationDate,
  ) async {
    try {
      // Get current wallet balance
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();
      final newBalance = currentBalance + creditAmount;

      // Update wallet balance
      await _firestore.collection('users').doc(_currentUserId).update({
        'walletBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create wallet transaction with expiration
      await _firestore.collection('wallet_transactions').add({
        'userId': _currentUserId,
        'type': 'package_credit',
        'amount': creditAmount,
        'description': 'Monthly credit for $packageName package',
        'packageName': packageName,
        'monthlyAmount': monthlyPrice,
        'status': 'completed',
        'isExpirable': true,
        'expiresAt': Timestamp.fromDate(expirationDate),
        'isExpired': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create expiring credit record for tracking
      await _firestore.collection('expiring_credits').add({
        'userId': _currentUserId,
        'packageName': packageName,
        'creditAmount': creditAmount,
        'grantedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expirationDate),
        'isExpired': false,
        'isUsed': false,
        'remainingAmount': creditAmount,
      });

      // print(
      //        '✅ Package credits granted: R${creditAmount.toStringAsFixed(2)}. Expires: ${_formatDate(expirationDate)}',
      //      );
    } catch (e) {
      // print('Error granting package credits: $e');
      rethrow;
    }
  }

  Future<void> _showPaymentInstructionsDialog(
    String packageName,
    double setupFee,
    double monthlyPrice,
    double totalAmount,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Color(0xFF8B0000)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment Required',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To activate $packageName package, payment is required:',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildPaymentDetailRow(
                      'Setup Fee (Pay Now)',
                      'R${setupFee.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _buildPaymentDetailRow(
                      'Monthly (From Next Month)',
                      'R${monthlyPrice.toStringAsFixed(2)}/month',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info,
                          color: Color(0xFF8B0000),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Instructions',
                          style: const TextStyle(
                            color: Color(0xFF8B0000),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Your current package will be cancelled\n'
                      '2. Pay setup fee to activate new package\n'
                      '3. Monthly billing starts next month\n'
                      '4. Admin will contact you for payment',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _proceedToPayment(packageName, setupFee, monthlyPrice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(
    String label,
    String amount, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              color: isBold ? const Color(0xFF8B0000) : Colors.white,
              fontSize: isBold ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelCurrentPackage() async {
    try {
      // Get current package subscriptions
      final subscriptions = await _firestore
          .collection('delayed_subscriptions')
          .where('userId', isEqualTo: _currentUserId)
          .where('status', whereIn: ['pending_activation', 'active'])
          .get();

      // Cancel all active subscriptions
      final batch = _firestore.batch();
      for (var sub in subscriptions.docs) {
        batch.update(sub.reference, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Update user's package status
      await _firestore.collection('users').doc(_currentUserId).update({
        'packageStatus': 'cancelled',
        'packageCancellationDate': FieldValue.serverTimestamp(),
      });

      // print('Current package cancelled successfully');
    } catch (e) {
      // print('Error cancelling current package: $e');
      rethrow;
    }
  }

  Future<void> _markPackageAsPendingPayment(
    String newPackage,
    double setupFee,
    double monthlyPrice,
  ) async {
    try {
      // Calculate activation date (first day of next month)
      final now = DateTime.now();
      final nextMonth = DateTime(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        1,
      );

      // Create pending package switch record
      await _firestore.collection('pending_package_switches').add({
        'userId': _currentUserId,
        'newPackage': newPackage,
        'setupFee': setupFee,
        'monthlyPrice': monthlyPrice,
        'totalAmountDue': setupFee, // Only setup fee to pay now
        'status': 'pending_payment',
        'monthlyActivationDate': Timestamp.fromDate(nextMonth),
        'requestedAt': FieldValue.serverTimestamp(),
        'userEmail': FirebaseAuth.instance.currentUser?.email,
        'userName': FirebaseAuth.instance.currentUser?.displayName,
      });

      // Send notification to admin
      await _firestore.collection('admin_notifications').add({
        'type': 'package_switch_request',
        'userId': _currentUserId,
        'userName': FirebaseAuth.instance.currentUser?.displayName,
        'userEmail': FirebaseAuth.instance.currentUser?.email,
        'packageName': newPackage,
        'setupFee': setupFee,
        'monthlyPrice': monthlyPrice,
        'monthlyStartDate': Timestamp.fromDate(nextMonth),
        'message':
            '${FirebaseAuth.instance.currentUser?.displayName ?? 'User'} requested to switch to $newPackage package. Setup fee: R${setupFee.toStringAsFixed(2)}',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // print(
      //        'Package switch request created. Setup fee payment required. Monthly billing starts ${_formatDate(nextMonth)}',
      //      );
    } catch (e) {
      // print('Error marking package as pending payment: $e');
      rethrow;
    }
  }

  Future<void> _activateNewPackage(
    String newPackage,
    String transactionId,
  ) async {
    try {
      final packageDetails = _getPackageDetails(newPackage);
      final monthlyPrice = double.parse(
        (packageDetails['monthlyPrice'] as String).replaceAll('R', ''),
      );

      // Calculate activation date (22 days from now)
      final activationDate = DateTime.now().add(const Duration(days: 22));

      // Create delayed subscription record
      await _firestore.collection('delayed_subscriptions').add({
        'userId': _currentUserId,
        'packageName': newPackage,
        'monthlyAmount': monthlyPrice,
        'status': 'pending_activation',
        'activationDate': Timestamp.fromDate(activationDate),
        'transactionId': transactionId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user's package in Firestore
      await _firestore.collection('users').doc(_currentUserId).update({
        'activePackage': newPackage,
        'packageStatus': 'pending_activation',
        'packageSwitchDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('Package switch completed: $newPackage');
    } catch (e) {
      // print('Error activating new package: $e');
      rethrow;
    }
  }

  void _showCancelPackageDialog(String packageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Cancel Package', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your $packageName package?\n\n'
          'You will lose access to all premium features at the end of your current billing cycle.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep Package',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCancelPackage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Package'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelPackage() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B0000)),
        ),
      );

      // Update package status
      await _firestore.collection('users').doc(_currentUserId).update({
        'packageStatus': 'cancelled',
        'packageCancellationDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Package cancelled. Access until end of billing cycle.',
            ),
            backgroundColor: Color(0xFFFF9800),
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpgradeDialog(String currentPackage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Row(
          children: [
            Icon(Icons.upgrade, color: Color(0xFF8B0000)),
            SizedBox(width: 12),
            Text('Upgrade Package', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Choose a package below to upgrade.\n\n'
          'You\'ll get immediate access to new features, and billing will be prorated.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
