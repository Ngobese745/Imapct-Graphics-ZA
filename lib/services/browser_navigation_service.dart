import 'dart:html' as html;

import 'package:flutter/material.dart';

class BrowserNavigationService {
  static final BrowserNavigationService _instance =
      BrowserNavigationService._internal();
  factory BrowserNavigationService() => _instance;
  BrowserNavigationService._internal();

  static BrowserNavigationService get instance => _instance;

  final List<String> _navigationStack = [];
  final List<VoidCallback> _backHandlers = [];
  bool _isInitialized = false;

  /// Initialize browser navigation service
  void initialize() {
    if (_isInitialized) return;

    print('🌐 Initializing browser navigation service');

    // Listen for browser back/forward button
    html.window.addEventListener('popstate', _handlePopState);

    // Add initial route to history
    _pushToHistory('/');

    _isInitialized = true;
    print('✅ Browser navigation service initialized');
  }

  /// Handle browser back/forward button
  void _handlePopState(html.Event event) {
    print('🔙 Browser back/forward button pressed');

    if (_navigationStack.isNotEmpty) {
      _navigationStack.removeLast();
    }

    // Call the most recent back handler
    if (_backHandlers.isNotEmpty) {
      final handler = _backHandlers.removeLast();
      handler();
    } else {
      // Fallback: go to dashboard
      _navigateToDashboard();
    }
  }

  /// Push a new route to browser history
  void pushRoute(String routeName, {VoidCallback? onBack}) {
    print('📍 Pushing route to browser history: $routeName');

    _navigationStack.add(routeName);

    if (onBack != null) {
      _backHandlers.add(onBack);
    }

    // Add to browser history
    html.window.history.pushState(null, '', routeName);
  }

  /// Replace current route in browser history
  void replaceRoute(String routeName, {VoidCallback? onBack}) {
    print('🔄 Replacing route in browser history: $routeName');

    if (_navigationStack.isNotEmpty) {
      _navigationStack.removeLast();
    }

    _navigationStack.add(routeName);

    if (onBack != null) {
      if (_backHandlers.isNotEmpty) {
        _backHandlers.removeLast();
      }
      _backHandlers.add(onBack);
    }

    // Replace in browser history
    html.window.history.replaceState(null, '', routeName);
  }

  /// Add route to browser history without navigation
  void _pushToHistory(String routeName) {
    html.window.history.pushState(null, '', routeName);
  }

  /// Navigate to dashboard (fallback)
  void _navigateToDashboard() {
    print('🏠 Navigating to dashboard (fallback)');

    // This will be handled by the main app navigation
    html.window.dispatchEvent(html.CustomEvent('navigateToDashboard'));
  }

  /// Get current route
  String get currentRoute =>
      _navigationStack.isNotEmpty ? _navigationStack.last : '/';

  /// Check if we can go back
  bool get canGoBack => _navigationStack.length > 1;

  /// Go back programmatically
  void goBack() {
    if (canGoBack) {
      html.window.history.back();
    }
  }

  /// Clear navigation stack
  void clearStack() {
    _navigationStack.clear();
    _backHandlers.clear();
    print('🗑️ Navigation stack cleared');
  }

  /// Dispose the service
  void dispose() {
    html.window.removeEventListener('popstate', _handlePopState);
    _isInitialized = false;
    print('🔌 Browser navigation service disposed');
  }
}
