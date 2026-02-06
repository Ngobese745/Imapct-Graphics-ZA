import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  // Default values for all config parameters
  static const Map<String, dynamic> _defaultValues = {
    // App configuration
    'app_version_required': '2.0.0',
    'maintenance_mode': false,
    'maintenance_message':
        'We are currently performing maintenance. Please try again later.',

    // Feature flags
    'enable_gold_tier': true,
    'enable_referral_system': true,
    'enable_loyalty_points': true,
    'enable_social_media_boost': true,
    'enable_marketing_packages': true,

    // Payment configuration
    'paystack_public_key': 'pk_test_your_key_here',
    'enable_wallet_funding': true,
    'min_wallet_amount': 10.0,
    'max_wallet_amount': 10000.0,

    // Ad configuration
    'daily_ad_limit': 100,
    'ad_reward_amount': 10.0,
    'enable_daily_ads': true,

    // Email configuration
    'enable_email_notifications': true,
    'enable_welcome_emails': true,
    'enable_order_emails': true,

    // UI configuration
    'primary_color': '#8B0000',
    'secondary_color': '#00AA00',
    'enable_dark_mode': true,

    // Marketing messages
    'welcome_message': 'Welcome to Impact Graphics ZA!',
    'app_description':
        'Professional graphic design services for your business.',

    // Social media links
    'facebook_url': 'https://facebook.com/impactgraphicsza',
    'instagram_url': 'https://instagram.com/impactgraphicsza',
    'twitter_url': 'https://twitter.com/impactgraphicsza',

    // Support configuration
    'support_email': 'support@impactgraphicsza.co.za',
    'support_phone': '+27 68 367 5755',
    'business_hours': 'Mon-Fri: 9:00 AM - 5:00 PM',

    // Performance settings
    'cache_duration': 3600, // 1 hour in seconds
    'max_retry_attempts': 3,
    'request_timeout': 30, // seconds
    // Development banner configuration
    'show_development_banner': true,
    'development_banner_title': '🚧 App Under Development',
    'development_banner_message':
        'We\'re still working on improving your experience! Report any issues or suggestions via the menu.',
    'development_banner_color': '#FF6B35',
    'development_banner_text_color': '#FFFFFF',
  };

  /// Initialize Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values
      await _remoteConfig.setDefaults(_defaultValues);

      // Configure settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Fetch and activate
      await fetchAndActivate();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Remote Config initialized successfully');
        print('📋 Current config values:');
        _defaultValues.forEach((key, value) {
          print('  $key: ${getValue(key)}');
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Remote Config: $e');
      }
    }
  }

  /// Fetch and activate remote config
  Future<bool> fetchAndActivate() async {
    try {
      final bool updated = await _remoteConfig.fetchAndActivate();
      if (kDebugMode) {
        print(
          '🔄 Remote Config fetch ${updated ? "successful" : "no updates"}',
        );
      }
      return updated;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching Remote Config: $e');
      }
      return false;
    }
  }

  /// Get a string value
  String getString(String key) {
    if (!_isInitialized) {
      print('⚠️ Remote Config not initialized, using default value for $key');
      return _defaultValues[key] as String? ?? '';
    }
    return _remoteConfig.getString(key);
  }

  /// Get a boolean value
  bool getBool(String key) {
    if (!_isInitialized) {
      print('⚠️ Remote Config not initialized, using default value for $key');
      return _defaultValues[key] as bool? ?? false;
    }
    return _remoteConfig.getBool(key);
  }

  /// Get an integer value
  int getInt(String key) {
    if (!_isInitialized) {
      print('⚠️ Remote Config not initialized, using default value for $key');
      return _defaultValues[key] as int? ?? 0;
    }
    return _remoteConfig.getInt(key);
  }

  /// Get a double value
  double getDouble(String key) {
    if (!_isInitialized) {
      print('⚠️ Remote Config not initialized, using default value for $key');
      return (_defaultValues[key] as num?)?.toDouble() ?? 0.0;
    }
    return _remoteConfig.getDouble(key);
  }

  /// Get a value as dynamic (for any type)
  dynamic getValue(String key) {
    return _remoteConfig.getValue(key);
  }

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode => getBool('maintenance_mode');

  /// Get maintenance message
  String get maintenanceMessage => getString('maintenance_message');

  /// Check if Gold Tier is enabled
  bool get isGoldTierEnabled => getBool('enable_gold_tier');

  /// Check if referral system is enabled
  bool get isReferralSystemEnabled => getBool('enable_referral_system');

  /// Check if loyalty points are enabled
  bool get isLoyaltyPointsEnabled => getBool('enable_loyalty_points');

  /// Check if social media boost is enabled
  bool get isSocialMediaBoostEnabled => getBool('enable_social_media_boost');

  /// Check if marketing packages are enabled
  bool get isMarketingPackagesEnabled => getBool('enable_marketing_packages');

  /// Get daily ad limit
  int get dailyAdLimit => getInt('daily_ad_limit');

  /// Get ad reward amount
  double get adRewardAmount => getDouble('ad_reward_amount');

  /// Check if daily ads are enabled
  bool get isDailyAdsEnabled => getBool('enable_daily_ads');

  /// Get minimum wallet amount
  double get minWalletAmount => getDouble('min_wallet_amount');

  /// Get maximum wallet amount
  double get maxWalletAmount => getDouble('max_wallet_amount');

  /// Check if wallet funding is enabled
  bool get isWalletFundingEnabled => getBool('enable_wallet_funding');

  /// Check if email notifications are enabled
  bool get isEmailNotificationsEnabled => getBool('enable_email_notifications');

  /// Get support email
  String get supportEmail => getString('support_email');

  /// Get support phone
  String get supportPhone => getString('support_phone');

  /// Get business hours
  String get businessHours => getString('business_hours');

  /// Get welcome message
  String get welcomeMessage => getString('welcome_message');

  /// Get app description
  String get appDescription => getString('app_description');

  /// Get primary color
  String get primaryColor => getString('primary_color');

  /// Get secondary color
  String get secondaryColor => getString('secondary_color');

  /// Check if dark mode is enabled
  bool get isDarkModeEnabled => getBool('enable_dark_mode');

  /// Get Facebook URL
  String get facebookUrl => getString('facebook_url');

  /// Get Instagram URL
  String get instagramUrl => getString('instagram_url');

  /// Get Twitter URL
  String get twitterUrl => getString('twitter_url');

  /// Get cache duration in seconds
  int get cacheDuration => getInt('cache_duration');

  /// Get max retry attempts
  int get maxRetryAttempts => getInt('max_retry_attempts');

  /// Get request timeout in seconds
  int get requestTimeout => getInt('request_timeout');

  /// Development banner configuration
  bool get showDevelopmentBanner => getBool('show_development_banner');
  String get developmentBannerTitle => getString('development_banner_title');
  String get developmentBannerMessage =>
      getString('development_banner_message');
  String get developmentBannerColor => getString('development_banner_color');
  String get developmentBannerTextColor =>
      getString('development_banner_text_color');

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Force refresh config (for testing)
  Future<void> forceRefresh() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }

    await fetchAndActivate();
    if (kDebugMode) {
      print('🔄 Remote Config force refreshed');
    }
  }

  /// Get all config values as a map
  Map<String, dynamic> getAllValues() {
    final Map<String, dynamic> values = {};
    for (String key in _defaultValues.keys) {
      values[key] = getValue(key);
    }
    return values;
  }
}
