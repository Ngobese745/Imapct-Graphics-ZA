import 'package:flutter/material.dart';

import '../services/remote_config_service.dart';

class DevelopmentBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const DevelopmentBanner({super.key, this.onTap, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();

    // Check if banner should be shown
    if (!remoteConfig.showDevelopmentBanner) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseColor(remoteConfig.developmentBannerColor),
            _parseColor(remoteConfig.developmentBannerColor).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _parseColor(
              remoteConfig.developmentBannerColor,
            ).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.construction,
                    color: _parseColor(remoteConfig.developmentBannerTextColor),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remoteConfig.developmentBannerTitle,
                        style: TextStyle(
                          color: _parseColor(
                            remoteConfig.developmentBannerTextColor,
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remoteConfig.developmentBannerMessage,
                        style: TextStyle(
                          color: _parseColor(
                            remoteConfig.developmentBannerTextColor,
                          ).withOpacity(0.9),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action button
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Report',
                      style: TextStyle(
                        color: _parseColor(
                          remoteConfig.developmentBannerTextColor,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                // Dismiss button
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close,
                        color: _parseColor(
                          remoteConfig.developmentBannerTextColor,
                        ),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Parse color from hex string
  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      String cleanColor = colorString.replaceAll('#', '');

      // Add FF for alpha if not present
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }

      return Color(int.parse(cleanColor, radix: 16));
    } catch (e) {
      // Fallback to orange if parsing fails
      return const Color(0xFFFF6B35);
    }
  }
}

/// Persistent development banner that can be dismissed
class PersistentDevelopmentBanner extends StatefulWidget {
  final VoidCallback? onTap;

  const PersistentDevelopmentBanner({super.key, this.onTap});

  @override
  State<PersistentDevelopmentBanner> createState() =>
      _PersistentDevelopmentBannerState();
}

class _PersistentDevelopmentBannerState
    extends State<PersistentDevelopmentBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return DevelopmentBanner(
      onTap: widget.onTap,
      onDismiss: () {
        setState(() {
          _isDismissed = true;
        });
      },
    );
  }
}


