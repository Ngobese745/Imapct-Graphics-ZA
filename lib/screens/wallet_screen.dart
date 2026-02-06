import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart' hide User;
import '../services/cache_service.dart';
import '../services/simple_reward_service.dart';
import '../services/wallet_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/smart_loading_widget.dart';
import 'invoice_screen.dart';
import 'paystack_payment_screen.dart';
import 'rewards_tracking_screen.dart';

class WalletScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const WalletScreen({super.key, this.onBackPressed});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with AutomaticKeepAliveClientMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final CacheService _cacheService = CacheService();

  // Cache data to prevent jumpy reloads
  double? _cachedBalance;
  String? _cachedStatus;
  List<WalletTransaction>? _cachedTransactions;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to access your wallet')),
      );
    }

    // Check if device is in landscape mode
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        // Ensure back button is always visible
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Use callback if provided (from bottom nav), otherwise try to pop
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // If no route to pop, navigate to dashboard
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              );
            }
          },
          tooltip: 'Back',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWallet,
        color: const Color(0xFF8B0000),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Balance Card with smooth loading
              StreamBuilder<DocumentSnapshot>(
                stream: _cacheService.getCachedStream(
                  'wallet_${_currentUser.uid}',
                  () => FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser.uid)
                      .snapshots(),
                  cacheDuration: const Duration(seconds: 30),
                ),
                builder: (context, snapshot) {
                  // Show cached data immediately while loading new data
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _cachedBalance == null) {
                    return const SkeletonBalanceCard();
                  }

                  if (snapshot.hasData) {
                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    _cachedBalance =
                        userData?['walletBalance']?.toDouble() ?? 0.0;
                    _cachedStatus = userData?['isActive'] == true
                        ? 'active'
                        : 'inactive';
                  }

                  // Always show cached data or latest data
                  return _buildBalanceCard(
                    _cachedBalance ?? 0.0,
                    _cachedStatus ?? 'active',
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Transactions List with smart loading
              SmartStreamWidget<List<WalletTransaction>>(
                cacheKey: 'transactions_${_currentUser.uid}',
                streamFactory: () =>
                    WalletService.getWalletTransactions(_currentUser.uid),
                cacheDuration: const Duration(seconds: 30),
                enableMemoryCache: true,
                showSkeletonWhileLoading: true,
                builder: (context, transactions) {
                  if (transactions.isEmpty) {
                    return _buildEmptyTransactions();
                  }

                  // Limit to 10 most recent transactions for performance
                  final displayTransactions = transactions.take(10).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(displayTransactions[index]);
                    },
                  );
                },
                errorWidget: (context, error) =>
                    _buildErrorWidget('Failed to load transactions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFF660000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFF660000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            WalletService.formatCurrency(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPaystackWalletFunding(),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'Add Funds',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRewardsScreen(),
                  icon: const Icon(Icons.card_giftcard, color: Colors.white),
                  label: const Text('Rewards'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Daily Ad Progress Section
          _buildDailyAdProgress(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    final isDebit =
        transaction.type == 'payment' || transaction.type == 'debit';

    // Determine icon based on transaction type
    IconData transactionIcon;
    Color transactionColor;

    switch (transaction.type) {
      case 'payment':
      case 'debit':
        transactionIcon = Icons.shopping_cart;
        transactionColor = const Color(0xFF8B0000);
        break;
      case 'refund':
        transactionIcon = Icons.money_off;
        transactionColor = Colors.orange;
        break;
      case 'wallet_funding':
      case 'credit':
        transactionIcon = Icons.add_circle;
        transactionColor = Colors.green;
        break;
      case 'ad_reward':
        transactionIcon = Icons.play_circle_fill;
        transactionColor = Colors.purple;
        break;
      case 'invoice_received':
        transactionIcon = Icons.receipt;
        transactionColor = Colors.blue;
        break;
      default:
        transactionIcon = isDebit ? Icons.arrow_upward : Icons.arrow_downward;
        transactionColor = isDebit ? const Color(0xFF8B0000) : Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: InkWell(
        onTap: () => _showTransactionInvoice(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: transactionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: transactionColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(transactionIcon, color: transactionColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          WalletService.formatDate(transaction.date),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (transaction.reference != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.tag, size: 12, color: Colors.white54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Ref: ${transaction.reference}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'}${WalletService.formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      color: isDebit ? const Color(0xFF8B0000) : Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: transaction.status == 'completed'
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: transaction.status == 'completed'
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: TextStyle(
                        color: transaction.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Invoice button
                      InkWell(
                        onTap: () => _showTransactionInvoice(transaction),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF8B0000,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xFF8B0000,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 12,
                                color: Color(0xFF8B0000),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Invoice',
                                style: TextStyle(
                                  color: Color(0xFF8B0000),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Pay button for invoice transactions
                      if (transaction.isInvoice == true &&
                          transaction.status != 'completed') ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _payInvoice(transaction),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.payment,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Pay',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, color: Colors.white54, size: 48),
          SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Error loading transactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshWallet() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    _isRefreshing = true;

    // Debounce refresh to prevent rapid rebuilds
    _cacheService.debounce('refresh_wallet', () async {
      // Clear caches to force fresh data
      _cacheService.clearCache('wallet_${_currentUser!.uid}');
      _cacheService.clearCache('transactions_${_currentUser.uid}');

      // Wait a bit for Firebase to sync
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }, duration: const Duration(milliseconds: 500));

    // Return immediately to allow pull-to-refresh to complete
    await Future.delayed(const Duration(milliseconds: 300));
    _isRefreshing = false;
  }

  Widget _buildDailyAdProgress() {
    if (_currentUser == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: SimpleRewardService().getDailyProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Error loading ad progress',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        }

        final progress = snapshot.data!;
        final adsWatched = progress['adsWatched'] as int;
        final maxAds = progress['maxAds'] as int;
        final canWatchMore = progress['canWatchMore'] as bool;
        final remainingAds = progress['remainingAds'] as int? ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Color(0xFF00AA00)),
                  const SizedBox(width: 8),
                  const Text(
                    'Daily Ad Rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$adsWatched/$maxAds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: adsWatched / maxAds,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00AA00), Color(0xFF00CC00)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Status text
              Text(
                _getAdProgressText(adsWatched, maxAds, remainingAds),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canWatchMore
                          ? () => _watchAdForCredit()
                          : null,
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: Text(
                        canWatchMore ? 'Watch Ad' : 'Daily Limit Reached',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canWatchMore
                            ? const Color(0xFF00AA00)
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAdProgressText(int adsWatched, int maxAds, int remainingAds) {
    if (adsWatched == 0) {
      return 'Watch 100 ads to earn R10.00! Reward given after completing all 100 ads.';
    } else if (remainingAds > 0) {
      return 'Watch $remainingAds more ads to unlock R10.00 reward! ($adsWatched/100 completed)';
    } else {
      return '✅ Congratulations! You\'ve completed 100 ads and earned R10.00 today!';
    }
  }

  Future<void> _watchAdForCredit() async {
    if (_currentUser == null) return;

    // Check if running on web platform
    if (kIsWeb) {
      _showWebAdMessage();
      return;
    }

    final simpleRewardService = SimpleRewardService();

    // Check if ad is ready
    if (!simpleRewardService.isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad is loading... Please try again in a few seconds'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user can watch more ads today
    final canWatchMore = await simpleRewardService.canWatchMoreAds();
    if (!canWatchMore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily ad limit reached! Come back tomorrow.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00AA00)),
      ),
    );

    bool dialogClosed = false;

    try {
      print('🎬 Starting ad watch process...');

      // Show the rewarded ad and process everything
      final result = await simpleRewardService.showRewardedAd();

      print('🔍 Ad result: $result');

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        final adsWatched = result['adsWatched'] as int;
        final maxAds = result['maxAds'] as int;
        final rewardClaimed = result['rewardClaimed'] as bool? ?? false;

        // Show success message
        if (mounted) {
          if (rewardClaimed) {
            // User just completed 20 ads and got rewarded
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🎉 Congratulations! R${result['rewardAmount']} credited to wallet for completing $maxAds ads!',
                ),
                backgroundColor: const Color(0xFFFFD700),
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            // User watched an ad but hasn't reached 20 yet
            final remaining = maxAds - adsWatched;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ad watched! ($adsWatched/$maxAds today) - Watch $remaining more to earn R10',
                ),
                backgroundColor: const Color(0xFF00AA00),
              ),
            );
          }
        }

        // Refresh the UI
        if (mounted) setState(() {});
      } else {
        print('❌ Ad failed: ${result['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'Failed to show ad. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show Paystack-integrated wallet funding dialog
  void _showPaystackWalletFunding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Funds to Wallet',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the amount you want to add to your wallet:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount (R)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A3A3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8B0000)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _amountController.clear();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => _processPaystackWalletFunding(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
              ),
              child: const Text('Continue to Payment'),
            ),
          ],
        );
      },
    );
  }

  /// Process Paystack wallet funding
  Future<void> _processPaystackWalletFunding() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('=== WALLET FUNDING INITIATED ===');
    print('Amount: R$amount');
    print('User Email: ${_currentUser?.email}');
    print('User Name: ${_currentUser?.displayName}');
    print('User Phone: ${_currentUser?.phoneNumber}');
    print('User ID: ${_currentUser?.uid}');

    // Close dialog
    Navigator.pop(context);

    // Navigate to Paystack payment screen
    if (mounted) {
      print('🚀 Navigating to PaystackPaymentScreen...');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaystackPaymentScreen(
            cartItems: [], // Empty cart for wallet funding
            totalAmount: amount,
            userEmail: _currentUser?.email ?? '',
            userName: _currentUser?.displayName,
            userPhone: _currentUser?.phoneNumber,
            userId: _currentUser?.uid,
            paymentType: 'wallet_funding', // Specify this is wallet funding
          ),
        ),
      );
      print('✅ Navigation completed');
    } else {
      print('❌ Widget not mounted, cannot navigate');
    }
  }

  // Old fake wallet funding dialog removed - now using Paystack integration

  void _showRewardsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RewardsTrackingScreen()),
    );
  }

  // Old fake addFunds method removed - now using Paystack integration

  void _showTransactionInvoice(WalletTransaction transaction) {
    // Determine service name and invoice status based on transaction type
    String serviceName;
    String invoiceStatus;

    switch (transaction.type) {
      case 'payment':
      case 'debit':
        serviceName = transaction.description.replaceAll('Payment for ', '');
        invoiceStatus = 'PAID';
        break;
      case 'refund':
        serviceName = transaction.description;
        invoiceStatus = 'REFUNDED';
        break;
      case 'wallet_funding':
        serviceName = 'Wallet Top-Up';
        invoiceStatus = 'COMPLETED';
        break;
      case 'credit':
      case 'ad_reward':
        serviceName = transaction.description;
        invoiceStatus = 'COMPLETED';
        break;
      default:
        serviceName = transaction.description;
        invoiceStatus = 'COMPLETED';
    }

    // Navigate to Invoice screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceScreen(
          transactionId: transaction.transactionId ?? transaction.id,
          customerName: _currentUser?.displayName ?? 'Customer',
          customerEmail: _currentUser?.email ?? 'customer@example.com',
          serviceName: serviceName,
          amount: transaction.amount,
          status: invoiceStatus,
          date: transaction.date,
          reference:
              transaction.reference ??
              transaction.transactionId ??
              transaction.id,
          phone: _currentUser?.phoneNumber,
          orderNumber: transaction.orderId,
        ),
      ),
    );
  }

  /// Pay invoice using Paystack
  Future<void> _payInvoice(WalletTransaction transaction) async {
    if (transaction.isInvoice != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is not an invoice transaction'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B0000)),
      ),
    );

    try {
      // Generate Paystack payment URL for invoice
      final paymentUrl = await _generateInvoicePaymentUrl(transaction);

      Navigator.pop(context); // Close loading dialog

      if (paymentUrl != null) {
        // Open Paystack payment URL
        await _launchPaystackUrl(paymentUrl, transaction);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate payment link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Generate Paystack payment URL for invoice
  Future<String?> _generateInvoicePaymentUrl(
    WalletTransaction transaction,
  ) async {
    try {
      // Use Paystack service to generate payment URL
      final paymentData = {
        'amount': (transaction.amount * 100).toInt(), // Convert to kobo
        'email': _currentUser?.email ?? '',
        'reference':
            'INV_${transaction.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}',
        'callback_url': 'https://your-app.com/payment/callback',
        'metadata': {
          'invoice_id': transaction.invoiceId,
          'invoice_number': transaction.invoiceNumber,
          'customer_name': _currentUser?.displayName ?? 'Customer',
          'description': transaction.description,
          'payment_type': 'invoice_payment',
        },
      };

      // Here you would typically call your Paystack service
      // For now, we'll create a simple payment URL
      final baseUrl = 'https://paystack.com/pay';
      final params = Uri(
        queryParameters: {
          'amount': paymentData['amount'].toString(),
          'email': paymentData['email'],
          'reference': paymentData['reference'],
        },
      );

      return '$baseUrl${params.toString()}';
    } catch (e) {
      print('Error generating payment URL: $e');
      return null;
    }
  }

  /// Launch Paystack payment URL
  Future<void> _launchPaystackUrl(
    String paymentUrl,
    WalletTransaction transaction,
  ) async {
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to payment page...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open payment page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening payment page: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWebAdMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.smartphone, color: Color(0xFF00AA00), size: 28),
              SizedBox(width: 12),
              Text(
                'Mobile App Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📱 Ads are a mobile-only feature!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'The Daily Ad Rewards feature is available exclusively on our mobile apps.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.rocket_launch, color: Color(0xFF00AA00), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We are launching our mobile apps soon! Stay tuned for iOS and Android releases.',
                      style: TextStyle(
                        color: Color(0xFF00AA00),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Color(0xFF00AA00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
