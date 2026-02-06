import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage navigation state across page reloads (especially for web)
class NavigationStateService {
  static const String _lastRouteKey = 'last_route';
  static const String _lastTabIndexKey = 'last_tab_index';
  static const String _lastScreenDataKey = 'last_screen_data';

  /// Save the current route/screen state
  static Future<void> saveNavigationState({
    required String route,
    int? tabIndex,
    Map<String, dynamic>? screenData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastRouteKey, route);

      if (tabIndex != null) {
        await prefs.setInt(_lastTabIndexKey, tabIndex);
      }

      if (screenData != null) {
        // Store additional screen-specific data if needed
        // For now, we'll keep it simple
      }

      print('✅ Navigation state saved: $route (tab: $tabIndex)');
    } catch (e) {
      print('❌ Error saving navigation state: $e');
    }
  }

  /// Get the last saved route
  static Future<String?> getLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastRouteKey);
    } catch (e) {
      print('❌ Error getting last route: $e');
      return null;
    }
  }

  /// Get the last saved tab index
  static Future<int?> getLastTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastTabIndexKey);
    } catch (e) {
      print('❌ Error getting last tab index: $e');
      return null;
    }
  }

  /// Clear navigation state (e.g., on logout)
  static Future<void> clearNavigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastRouteKey);
      await prefs.remove(_lastTabIndexKey);
      await prefs.remove(_lastScreenDataKey);
      print('✅ Navigation state cleared');
    } catch (e) {
      print('❌ Error clearing navigation state: $e');
    }
  }

  /// Check if we have a saved state
  static Future<bool> hasSavedState() async {
    final route = await getLastRoute();
    return route != null && route.isNotEmpty;
  }

  /// Get complete navigation state
  static Future<NavigationState> getNavigationState() async {
    final route = await getLastRoute();
    final tabIndex = await getLastTabIndex();

    return NavigationState(route: route ?? 'home', tabIndex: tabIndex ?? 0);
  }
}

/// Class to hold navigation state
class NavigationState {
  final String route;
  final int tabIndex;

  NavigationState({required this.route, required this.tabIndex});
}
