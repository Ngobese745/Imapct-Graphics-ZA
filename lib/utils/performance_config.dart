import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Global performance configuration for the app
class PerformanceConfig {
  /// Initialize performance optimizations
  static void initialize() {
    // Enable hardware acceleration
    debugProfileBuildsEnabled = false;
    debugProfilePaintsEnabled = false;

    // Performance optimizations are now initialized
    // Note: Overscroll behavior is handled via ScrollPhysics
  }

  /// Get optimized scroll physics
  static ScrollPhysics get optimizedScrollPhysics {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// Get clamping scroll physics (prevents overscroll)
  static ScrollPhysics get clampingScrollPhysics {
    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// Default animation duration for smooth transitions
  static const Duration animationDuration = Duration(milliseconds: 250);

  /// Fast animation duration for quick transitions
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  /// Slow animation duration for emphasized transitions
  static const Duration slowAnimationDuration = Duration(milliseconds: 400);

  /// Debounce duration for search and input fields
  static const Duration debounceDuration = Duration(milliseconds: 500);

  /// Cache duration for Firebase streams
  static const Duration cacheDuration = Duration(seconds: 30);

  /// Refresh indicator displacement
  static const double refreshIndicatorDisplacement = 40.0;

  /// Default page transition
  static Widget buildPageTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  /// Custom page route with smooth transition
  static PageRoute<T> createRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return buildPageTransition(child: child, animation: animation);
      },
      transitionDuration: animationDuration,
      settings: settings,
    );
  }
}

/// Mixin for screens that should maintain their state
mixin KeepAliveMixin<T extends StatefulWidget> on State<T>
    implements AutomaticKeepAliveClientMixin<T> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    throw UnimplementedError();
  }
}
