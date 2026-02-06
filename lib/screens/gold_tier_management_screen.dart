import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/gold_tier_trial_service.dart';
import '../services/paystack_subscription_service.dart';
import 'gold_tier_subscription_screen.dart';

class GoldTierManagementScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;

  const GoldTierManagementScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<GoldTierManagementScreen> createState() =>
      _GoldTierManagementScreenState();
}

class _GoldTierManagementScreenState extends State<GoldTierManagementScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  String get _goldTierStatus {
    return _userData?['goldTierStatus'] as String? ?? 'inactive';
  }

  bool get _isGoldTierActive {
    return _userData?['goldTierActive'] as bool? ?? false;
  }

  bool get _isOnTrial {
    return _goldTierStatus == 'trial';
  }

  bool get _isActive {
    return _goldTierStatus == 'active';
  }

  bool get _isCancelled {
    return _goldTierStatus == 'cancelled';
  }

  bool get _isExpired {
    return _goldTierStatus == 'expired';
  }

  DateTime? get _trialEndDate {
    final timestamp = _userData?['goldTierTrialEndDate'] as Timestamp?;
    return timestamp?.toDate();
  }

  DateTime? get _activationDate {
    final timestamp = _userData?['goldTierActivationDate'] as Timestamp?;
    return timestamp?.toDate();
  }

  DateTime? get _cancellationDate {
    final timestamp = _userData?['goldTierCancellationDate'] as Timestamp?;
    return timestamp?.toDate();
  }

  int get _daysRemaining {
    if (_trialEndDate == null) return 0;
    final now = DateTime.now();
    final difference = _trialEndDate!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        title: const Text('Gold Tier Management'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _errorMessage != null
          ? _buildErrorScreen()
          : _buildContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Gold Tier status...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildStatusCard(),
          const SizedBox(height: 20),
          _buildBenefitsCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
          _buildSubscriptionDetails(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 60),
          const SizedBox(height: 15),
          const Text(
            'Gold Tier',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_isOnTrial) {
      return 'Trial - $_daysRemaining days remaining';
    } else if (_isActive) {
      return 'Active Subscription';
    } else if (_isCancelled) {
      return 'Cancelled';
    } else if (_isExpired) {
      return 'Trial Expired';
    } else {
      return 'Not Active';
    }
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildStatusRow('Status', _getDetailedStatus()),
          if (_isOnTrial && _daysRemaining > 0)
            _buildStatusRow('Trial Ends', _formatDate(_trialEndDate)),
          if (_isActive)
            _buildStatusRow('Activated', _formatDate(_activationDate)),
          if (_isCancelled)
            _buildStatusRow('Cancelled', _formatDate(_cancellationDate)),
          _buildStatusRow('Monthly Cost', 'R299.00'),
        ],
      ),
    );
  }

  String _getDetailedStatus() {
    if (_isOnTrial) {
      return '7-Day Free Trial';
    } else if (_isActive) {
      return 'Active Subscription';
    } else if (_isCancelled) {
      return 'Cancelled';
    } else if (_isExpired) {
      return 'Trial Expired';
    } else {
      return 'Not Subscribed';
    }
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: _isActive ? const Color(0xFF4CAF50) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gold Tier Benefits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildBenefitItem('🎨', '10% Discount', 'On all services and orders'),
          _buildBenefitItem('⚡', 'Priority Support', 'Faster response times'),
          _buildBenefitItem(
            '👑',
            'Premium Features',
            'Exclusive access to new tools',
          ),
          _buildBenefitItem(
            '💯',
            'Unlimited Access',
            'No restrictions on usage',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isOnTrial || _isExpired || !_isGoldTierActive) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isOnTrial ? 'Upgrade to Full Gold Tier' : 'Start Gold Tier',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        if (_isActive || _isOnTrial) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isOnTrial ? 'Cancel Trial' : 'Cancel Subscription',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        if (_isCancelled || _isExpired) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleReactivate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reactivate Gold Tier',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubscriptionDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '• Subscription managed through Paystack\n'
            '• Automatic monthly billing\n'
            '• Cancel anytime with immediate effect\n'
            '• No hidden fees or charges\n'
            '• Full access to all premium features',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => GoldTierSubscriptionScreen(
            userEmail: widget.userEmail,
            userName: widget.userName,
            userId: widget.userId,
          ),
        ),
      );

      if (result == true) {
        await _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gold Tier subscription activated successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await _showCancelConfirmationDialog();
    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);

      if (_isOnTrial) {
        // Cancel trial
        await GoldTierTrialService.cancelTrial(widget.userId);
      } else if (_isActive) {
        // Cancel active subscription and Paystack subscription
        await _cancelPaystackSubscription();
        await GoldTierTrialService.cancelSubscription(widget.userId);
      }

      await _loadUserData();

      // IMPORTANT: Refresh AuthService user profile to update dashboard
      final authService = AuthService.instance;
      if (authService != null) {
        await authService.refreshUserProfile();
        print('✅ AuthService user profile refreshed after trial cancellation');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isOnTrial
                  ? 'Gold Tier trial cancelled successfully'
                  : 'Gold Tier subscription cancelled successfully',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReactivate() async {
    await _handleUpgrade();
  }

  Future<bool> _showCancelConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                _isOnTrial ? 'Cancel Trial?' : 'Cancel Subscription?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                _isOnTrial
                    ? 'Are you sure you want to cancel your Gold Tier trial? You will lose access to premium features immediately.'
                    : 'Are you sure you want to cancel your Gold Tier subscription? You will lose access to premium features at the end of your current billing period.',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Keep Subscription',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isOnTrial ? 'Cancel Trial' : 'Cancel'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _cancelPaystackSubscription() async {
    try {
      // Get user's Paystack customer code
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final customerCode = userData['paystackCustomerCode'] as String?;

        if (customerCode != null) {
          // Cancel Paystack subscription
          await PaystackSubscriptionService.cancelSubscription(customerCode);
        }
      }
    } catch (e) {
      print('Error cancelling Paystack subscription: $e');
      // Don't throw error as we still want to cancel the app subscription
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
