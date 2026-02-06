import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppDialog extends StatefulWidget {
  final String title;
  final String message;
  final String phoneNumber;
  final VoidCallback? onClose;
  final VoidCallback? onReturnToApp;

  const WhatsAppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.phoneNumber,
    this.onClose,
    this.onReturnToApp,
  });

  @override
  State<WhatsAppDialog> createState() => _WhatsAppDialogState();
}

class _WhatsAppDialogState extends State<WhatsAppDialog> {
  Timer? _returnTimer;
  bool _hasOpenedWhatsApp = false;

  @override
  void dispose() {
    _returnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Project Details Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please share your project details and pictures with us via WhatsApp. This helps us understand your requirements better and deliver exactly what you need.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Include specific requirements, reference images, and any special instructions.',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
            Navigator.pop(context);
            widget.onClose?.call();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton.icon(
          onPressed: () => _openWhatsApp(),
          icon: const Icon(Icons.chat, size: 18),
          label: Text(_hasOpenedWhatsApp ? 'Return to App' : 'Open WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasOpenedWhatsApp
                ? const Color(0xFF8B0000)
                : Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openWhatsApp() async {
    try {
      if (_hasOpenedWhatsApp) {
        // User wants to return to app - redirect to app URL
        await _redirectToApp();
        return;
      }

      // Format phone number (remove any spaces, dashes, etc.)
      final cleanPhoneNumber = widget.phoneNumber.replaceAll(
        RegExp(r'[^\d+]'),
        '',
      );

      // Ensure phone number starts with country code if not already present
      String formattedPhoneNumber;
      if (cleanPhoneNumber.startsWith('+')) {
        formattedPhoneNumber = cleanPhoneNumber;
      } else if (cleanPhoneNumber.startsWith('27')) {
        // Already has South African country code
        formattedPhoneNumber = '+$cleanPhoneNumber';
      } else if (cleanPhoneNumber.startsWith('0')) {
        // Remove leading 0 and add +27
        formattedPhoneNumber = '+27${cleanPhoneNumber.substring(1)}';
      } else {
        // Assume it's a local number and add +27
        formattedPhoneNumber = '+27$cleanPhoneNumber';
      }

      // Encode the message for URL
      final encodedMessage = Uri.encodeComponent(widget.message);

      // Create WhatsApp URL
      final whatsappUrl =
          'https://wa.me/$formattedPhoneNumber?text=$encodedMessage';

      print('Opening WhatsApp with URL: $whatsappUrl');

      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        // Update button state
        setState(() {
          _hasOpenedWhatsApp = true;
        });

        if (kIsWeb) {
          // For web, open in new tab and set up return listener
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
            webOnlyWindowName: '_blank',
          );

          _setupWebReturnListener();

          // Show guidance message
          _showGuidanceMessage();
        } else {
          // For mobile, use external application
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // Set up mobile return listener
          _setupMobileReturnListener();
        }
      } else {
        print('Could not launch WhatsApp URL');
        // Fallback to opening WhatsApp without pre-filled message
        final fallbackUrl = 'https://wa.me/$formattedPhoneNumber';
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          setState(() {
            _hasOpenedWhatsApp = true;
          });
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      _showErrorSnackBar('Could not open WhatsApp. Please try again.');
    }
  }

  void _setupWebReturnListener() {
    if (!kIsWeb) return;

    // Listen for when the user returns to the app tab
    html.window.addEventListener('focus', (html.Event event) {
      print('🔄 User returned to app tab from WhatsApp');
      _handleReturnToApp();
    });

    // Also listen for visibility change (when tab becomes active)
    html.document.addEventListener('visibilitychange', (html.Event event) {
      if (!html.document.hidden!) {
        print('🔄 App tab became visible');
        _handleReturnToApp();
      }
    });

    // Listen for when the user comes back from another tab
    html.window.addEventListener('pageshow', (html.Event event) {
      print('🔄 Page shown (user returned from WhatsApp)');
      _handleReturnToApp();
    });

    // Set up a timer to periodically check if user returned
    _returnTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!html.document.hidden!) {
        _handleReturnToApp();
        timer.cancel();
      }
    });
  }

  void _setupMobileReturnListener() {
    // For mobile, set up a timer to check for return
    _returnTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // This is a simplified approach for mobile
      // In a real implementation, you might use platform-specific methods
      _handleReturnToApp();
      timer.cancel();
    });
  }

  Future<void> _redirectToApp() async {
    try {
      // App URL
      const appUrl = 'https://impact-graphics-za-266ef.web.app';

      final uri = Uri.parse(appUrl);
      if (await canLaunchUrl(uri)) {
        if (kIsWeb) {
          // For web, redirect in the same tab
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          // For mobile, open in browser
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error redirecting to app: $e');
      _showErrorSnackBar('Could not return to app. Please navigate manually.');
    }
  }

  void _handleReturnToApp() {
    _returnTimer?.cancel();

    // Show success message
    _showSuccessSnackBar();

    // Call the return callback
    widget.onReturnToApp?.call();

    // Close the dialog after a short delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        widget.onClose?.call();
      }
    });
  }

  void _showGuidanceMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'WhatsApp opened! After sending your message, return to this tab.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Return Now',
          textColor: Colors.white,
          onPressed: _handleReturnToApp,
        ),
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Welcome back! Your message has been sent successfully.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Static method to show the dialog
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required String phoneNumber,
    VoidCallback? onClose,
    VoidCallback? onReturnToApp,
  }) {
    showDialog(
      context: context,
      builder: (context) => WhatsAppDialog(
        title: title,
        message: message,
        phoneNumber: phoneNumber,
        onClose: onClose,
        onReturnToApp: onReturnToApp,
      ),
    );
  }
}
