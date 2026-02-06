import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/auth_service.dart';
import '../services/gold_tier_trial_service.dart';
import '../services/mailersend_service.dart';
import '../services/notification_service.dart';
import '../services/paystack_subscription_service.dart';

class GoldTierSubscriptionScreen extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String userId;

  const GoldTierSubscriptionScreen({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.userId,
  });

  @override
  State<GoldTierSubscriptionScreen> createState() =>
      _GoldTierSubscriptionScreenState();
}

class _GoldTierSubscriptionScreenState
    extends State<GoldTierSubscriptionScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  WebViewController? _webViewController;
  String? _planCode;
  String? _transactionReference;

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  Future<void> _initializeSubscription() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create or get Gold Tier plan
      print('🔄 Creating Gold Tier plan...');
      final planResponse =
          await PaystackSubscriptionService.createGoldTierPlan();

      print(
        '📋 Plan Response - Success: ${planResponse.success}, Message: ${planResponse.message}',
      );

      if (!planResponse.success) {
        throw Exception('Failed to create plan: ${planResponse.message}');
      }

      _planCode = planResponse.planCode;
      // print('Plan created successfully: $_planCode');

      // Step 2: Create or get customer
      print('🔄 Creating/getting customer...');
      final nameParts = widget.userName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      print(
        '👤 Customer details - Email: ${widget.userEmail}, Name: $firstName $lastName',
      );

      final customerResponse =
          await PaystackSubscriptionService.createOrGetCustomer(
            email: widget.userEmail,
            firstName: firstName,
            lastName: lastName,
          );

      print(
        '📋 Customer Response - Success: ${customerResponse.success}, Message: ${customerResponse.message}, Code: ${customerResponse.customerCode}',
      );

      if (!customerResponse.success) {
        print('❌ Customer creation failed: ${customerResponse.message}');
        throw Exception(
          'Failed to create customer: ${customerResponse.message}',
        );
      }

      // print(
      //        'Customer created/found successfully: ${customerResponse.customerCode}',
      //      );

      // print('Customer ready: ${customerResponse.customerCode}');

      // Step 3: Create subscription
      print('🔄 Creating subscription...');

      // Check for null values before proceeding
      if (customerResponse.customerCode == null) {
        print('❌ Customer code is null!');
        throw Exception('Customer code is null - customer creation failed');
      }

      if (_planCode == null) {
        print('❌ Plan code is null!');
        throw Exception('Plan code is null - plan creation failed');
      }

      print(
        '💳 Creating subscription with customer: ${customerResponse.customerCode}, plan: $_planCode',
      );

      final subscriptionResponse =
          await PaystackSubscriptionService.createSubscription(
            customerCode: customerResponse.customerCode!,
            planCode: _planCode!,
            userEmail: widget.userEmail,
          );

      print(
        '📋 Subscription Response - Success: ${subscriptionResponse.success}, Message: ${subscriptionResponse.message}',
      );
      print('🔗 Authorization URL: ${subscriptionResponse.authorizationUrl}');

      if (!subscriptionResponse.success) {
        print(
          '❌ Subscription creation failed: ${subscriptionResponse.message}',
        );
        throw Exception(
          'Failed to create subscription: ${subscriptionResponse.message}',
        );
      }

      _transactionReference = subscriptionResponse
          .subscriptionCode; // This is the transaction reference
      // print('Subscription created: ${subscriptionResponse.subscriptionCode}');
      // print('Transaction reference: $_transactionReference');

      // Step 4: Initialize payment UI based on platform
      if (subscriptionResponse.authorizationUrl != null &&
          subscriptionResponse.authorizationUrl!.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });

        if (kIsWeb) {
          // For web: open in popup and show dialog
          print('🌐 Opening Gold Tier payment in popup (web)...');
          _handleWebPayment(subscriptionResponse.authorizationUrl!);
        } else {
          // For mobile: use WebView
          print('📱 Initializing WebView (mobile)...');
          _initializeWebView(subscriptionResponse.authorizationUrl!);
        }
      } else {
        throw Exception(
          'No authorization URL received from subscription response',
        );
      }
    } catch (e) {
      print('❌❌❌ Subscription initialization error: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Handle web payment by opening in popup
  Future<void> _handleWebPayment(String authorizationUrl) async {
    try {
      final uri = Uri.parse(authorizationUrl);

      // Open Paystack payment in popup
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
        print('✅ Gold Tier payment window opened');
      } catch (e) {
        print('⚠️ Popup failed: $e, trying external mode');
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        throw Exception('Cannot open payment URL');
      }

      // Show dialog with instructions
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.payment, color: Color(0xFFFFD700)),
                  SizedBox(width: 8),
                  Text(
                    'Complete Gold Tier Payment',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Payment window opened in a new tab.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📝 Instructions:',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Complete payment in the popup window\n'
                          '2. Return to this page after payment\n'
                          '3. Click "Verify Payment" below',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'If popup didn\'t open, check browser popup blocker.',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.platformDefault,
                        webOnlyWindowName: '_blank',
                      );
                    } catch (e) {
                      print('Error reopening payment: $e');
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text(
                    'Reopen Payment',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close dialog
                    await _verifyWebPayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Verify Payment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error handling web payment: $e');
      setState(() {
        _errorMessage = 'Failed to open payment: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Verify web payment
  Future<void> _verifyWebPayment() async {
    if (_transactionReference == null) {
      _showErrorDialog('No transaction reference found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Verifying Gold Tier payment...');
      print('🔍 Transaction reference: $_transactionReference');

      // Verify the transaction with Paystack
      final verificationResponse =
          await PaystackSubscriptionService.verifyTransaction(
            _transactionReference!,
          );

      print(
        '📋 Verification response: ${verificationResponse.success} - ${verificationResponse.message}',
      );

      setState(() {
        _isLoading = false;
      });

      if (verificationResponse.success) {
        // Double-check: Make sure the transaction was actually paid
        print('✅ Gold Tier payment verified! Activating subscription...');
        await _handleSubscriptionSuccess();
      } else {
        print('❌ Payment verification failed: ${verificationResponse.message}');
        _showErrorDialog(
          'Payment verification failed: ${verificationResponse.message}\n\nPlease ensure you completed the payment in the popup window.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Verification error: $e');
      _showErrorDialog('Verification error: ${e.toString()}');
    }
  }

  void _initializeWebView(String authorizationUrl) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // print('Navigation to: ${request.url}');

            // Check for success callback
            if (request.url.contains('success') ||
                request.url.contains('callback') ||
                request.url.contains('subscription')) {
              _handleSubscriptionSuccess();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(authorizationUrl));

    setState(() {
      _isLoading = false;
    });
  }

  /// Refresh user profile to update UI
  Future<void> _refreshUserProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.refreshUserProfile();
      print('✅ User profile refreshed after Gold Tier activation');
    } catch (e) {
      print('⚠️ Error refreshing user profile: $e');
    }
  }

  Future<void> _handleSubscriptionSuccess() async {
    // print('Subscription success detected!');

    try {
      // Verify the transaction since we're using transaction initialization
      if (_transactionReference != null) {
        // print('Verifying transaction: $_transactionReference');
        final verificationResponse =
            await PaystackSubscriptionService.verifyTransaction(
              _transactionReference!,
            );

        if (verificationResponse.success) {
          // print('Transaction verified successfully, activating Gold Tier...');

          // Check if user is already on trial
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();

          bool isCurrentlyOnTrial = false;
          Map<String, dynamic>? userData;

          if (userDoc.exists) {
            userData = userDoc.data();
            if (userData != null) {
              final goldTierStatus = userData['goldTierStatus'] as String?;
              isCurrentlyOnTrial = goldTierStatus == 'trial';
            }
          }

          if (isCurrentlyOnTrial) {
            // Convert existing trial to active subscription (only on successful payment)
            await GoldTierTrialService.convertTrialToActiveOnPayment(
              widget.userId,
            );

            // Refresh user profile to update UI
            await _refreshUserProfile();

            // Show success dialog for upgrade
            _showUpgradeSuccessDialog();
          } else if (userData != null) {
            // Check if user has expired trial
            final goldTierStatus = userData['goldTierStatus'] as String?;

            if (goldTierStatus == 'expired') {
              // Upgrade expired trial to active subscription
              await GoldTierTrialService.upgradeExpiredTrialToActive(
                widget.userId,
              );
              _showUpgradeSuccessDialog();
            } else {
              // Check if user has ever had a trial before
              final hasHadTrial =
                  userData['hasHadGoldTierTrial'] as bool? ?? false;

              if (hasHadTrial) {
                // User has had trial before - show upgrade options instead of auto-activating
                print('🔄 User has had trial before - showing upgrade options');
                // Don't auto-activate - let user choose to upgrade
                _showUpgradeOptions();
              } else {
                // New user - start trial
                print('🆕 New user - starting Gold Tier trial');
                await _updateUserGoldTierStatus(true, isTrial: true);

                // Refresh user profile to update UI
                await _refreshUserProfile();

                // Send success notification
                await NotificationService.sendNotificationToUser(
                  userId: widget.userId,
                  title: 'Gold Tier Trial Started! 🏆',
                  body:
                      'Your 7-day Gold Tier trial has begun! Enjoy premium features and 10% discount on all services.',
                  type: 'upgrade',
                  action: 'gold_tier_trial_started',
                );

                // Show success dialog
                _showSuccessDialog();
              }
            }
          }
        } else {
          throw Exception(
            'Transaction verification failed: ${verificationResponse.message}',
          );
        }
      } else {
        throw Exception('Transaction reference not found');
      }
    } catch (e) {
      // print('Error handling subscription success: $e');
      _showErrorDialog('Failed to activate Gold Tier: $e');
    }
  }

  Future<void> _updateUserGoldTierStatus(
    bool isActive, {
    bool isTrial = false,
  }) async {
    try {
      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 7)); // 7-day trial

      final updateData = {
        'isGoldTier': isActive,
        'goldTierActive': isActive,
        'goldTierStatus': isActive
            ? (isTrial ? 'trial' : 'active')
            : 'inactive',
        'accountStatus': isActive
            ? (isTrial ? 'Gold Tier user (Trial)' : 'Gold Tier user')
            : 'Silver Tier user',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isActive && isTrial) {
        // Set up 7-day trial
        updateData['goldTierTrialStartDate'] = FieldValue.serverTimestamp();
        updateData['goldTierTrialEndDate'] = Timestamp.fromDate(trialEndDate);
        updateData['goldTierActivationDate'] =
            FieldValue.delete(); // No activation date for trial
      } else if (isActive && !isTrial) {
        // Convert from trial to active subscription
        updateData['goldTierActivationDate'] = FieldValue.serverTimestamp();
        updateData['goldTierTrialStartDate'] = FieldValue.delete();
        updateData['goldTierTrialEndDate'] = FieldValue.delete();
      } else {
        // Deactivate
        updateData['goldTierActivationDate'] = FieldValue.delete();
        updateData['goldTierTrialStartDate'] = FieldValue.delete();
        updateData['goldTierTrialEndDate'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(updateData);

      print('User Gold tier status updated successfully - Trial: $isTrial');
    } catch (e) {
      print('Error updating user Gold tier status: $e');
      rethrow;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFFD700),
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Gold Tier Trial Started! 🏆',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              const Text(
                'Welcome to your 7-day Gold Tier trial! You now have access to:\n\n• 10% discount on all services\n• Priority support\n• Exclusive premium features\n• Trial ends in 7 days - upgrade to continue',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(
                      context,
                    ).pop(true); // Return to previous screen with success
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(
                'Subscription Failed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _initializeSubscription(); // Retry
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                      ),
                      child: const Text('Retry'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        title: const Text('Gold Tier Subscription'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_webViewController != null) {
      return _buildWebViewScreen();
    }

    return _buildLoadingScreen();
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Setting up your Gold Tier subscription...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we prepare your premium experience',
            style: TextStyle(color: Colors.white70, fontSize: 14),
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
            const Text(
              'Subscription Setup Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _initializeSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewScreen() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Complete Your Gold Tier Subscription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // WebView
        Expanded(
          child: _webViewController != null
              ? WebViewWidget(controller: _webViewController!)
              : const Center(
                  child: Text(
                    'Loading payment interface...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: const Text(
            'Secure payment powered by Paystack • R299/month',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _sendGoldTierActivationEmail() async {
    try {
      // Get user details for email
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData == null) return;
        final userEmail = userData['email'] as String?;
        final userName =
            userData['name'] as String? ??
            userData['username'] as String? ??
            'Valued Client';

        if (userEmail != null && userEmail.isNotEmpty) {
          print('📧 Sending Gold Tier activation email to: $userEmail');

          final emailResult =
              await MailerSendService.sendGoldTierActivationEmail(
                toEmail: userEmail,
                toName: userName,
                monthlyAmount: 'R299.00',
              );

          if (emailResult.success) {
            print('✅ Gold Tier activation email sent successfully!');
          } else {
            print(
              '❌ Failed to send Gold Tier activation email: ${emailResult.message}',
            );
          }
        } else {
          print('❌ User email not found for Gold Tier activation email');
        }
      }
    } catch (e) {
      print('❌ Error sending Gold Tier activation email: $e');
    }
  }

  void _showUpgradeSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFFD700),
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Gold Tier Activated! 🏆',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              const Text(
                'Congratulations! Your Gold Tier subscription is now active. You now have unlimited access to:\n\n• 10% discount on all services\n• Priority support\n• Exclusive premium features\n• Unlimited access to all Gold Tier benefits',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(
                      context,
                    ).pop(true); // Return to previous screen with success
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpgradeOptions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gold Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Upgrade to Gold Tier! 🏆',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              const Text(
                'You\'ve had a Gold Tier trial before. Choose an option below to upgrade:',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Upgrade Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // User can manually choose to upgrade
                    // The existing UI will handle this
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Choose Upgrade Option',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
