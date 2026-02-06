import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdService {
  // Singleton pattern
  static final BannerAdService _instance = BannerAdService._internal();
  factory BannerAdService() => _instance;
  BannerAdService._internal();

  // Live banner ad unit IDs
  static const String bannerAdUnitIdAndroid =
      'ca-app-pub-2168762108450116/3439935252'; // Portfolio banner ad
  static const String bannerAdUnitIdIOS =
      'ca-app-pub-2168762108450116/3439935252'; // Portfolio banner ad (same for now)

  // Guest screen banner ad unit IDs
  static const String guestBannerAdUnitIdAndroid =
      'ca-app-pub-2168762108450116/2757269359'; // Guest screen banner ad
  static const String guestBannerAdUnitIdIOS =
      'ca-app-pub-2168762108450116/2757269359'; // Guest screen banner ad (same for now)

  BannerAd? _bannerAd;
  final ValueNotifier<bool> isAdReady = ValueNotifier<bool>(false);

  /// Check if ads are supported on this platform
  bool get isSupported => !kIsWeb;

  /// Initialize the banner ad service
  Future<void> initialize() async {
    // Skip initialization on web - AdMob is not supported
    if (kIsWeb) {
      print('⚠️ BannerAdService: AdMob not supported on web platform');
      return;
    }

    print('🎯 Initializing BannerAdService...');

    // Initialize MobileAds first
    await MobileAds.instance.initialize();
    print('✅ MobileAds initialized for BannerAdService');

    // Configure test devices for debugging
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: [
          '675ECB61A19EF31A46D5A40B064A203C',
        ], // Test device ID from logs
      ),
    );

    await _loadBannerAd();
  }

  /// Get the appropriate ad unit ID based on platform
  String get _bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return bannerAdUnitIdAndroid;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return bannerAdUnitIdIOS;
    } else {
      // Fallback to Android ID for other platforms (though they won't be supported)
      return bannerAdUnitIdAndroid;
    }
  }

  /// Load a banner ad
  Future<void> _loadBannerAd() async {
    try {
      print('🔄 Loading banner ad...');
      print('🔍 Using banner ad unit ID: $_bannerAdUnitId');

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('✅ Banner ad loaded successfully');
            isAdReady.value = true;
          },
          onAdFailedToLoad: (ad, error) {
            print('❌ Banner ad failed to load: $error');
            print('❌ Error code: ${error.code}');
            print('❌ Error domain: ${error.domain}');
            print('❌ Error message: ${error.message}');
            isAdReady.value = false;
            ad.dispose();
            // Try to reload after a delay
            Future.delayed(const Duration(seconds: 10), () {
              print('🔄 Retrying banner ad load...');
              _loadBannerAd();
            });
          },
          onAdOpened: (ad) {
            print('📖 Banner ad opened');
          },
          onAdClosed: (ad) {
            print('✅ Banner ad closed');
          },
        ),
      );

      print('📞 Calling load() on banner ad...');
      await _bannerAd!.load();
      print('📞 load() call completed');
    } catch (e) {
      print('❌ Exception loading banner ad: $e');
    }
  }

  /// Get banner ad widget
  Widget? getBannerAdWidget() {
    if (isAdReady.value && _bannerAd != null) {
      return SizedBox(height: 50, child: AdWidget(ad: _bannerAd!));
    }
    return null;
  }

  /// Dispose banner ad
  void dispose() {
    print('🗑️ Disposing banner ad');
    _bannerAd?.dispose();
    _bannerAd = null;
    isAdReady.value = false;
  }

  /// Reload banner ad
  Future<void> reload() async {
    dispose();
    await _loadBannerAd();
  }

  /// Create a guest screen banner ad widget
  Widget? getGuestBannerAdWidget() {
    if (isAdReady.value && _bannerAd != null) {
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    return null;
  }

  /// Load guest screen banner ad
  Future<void> loadGuestBannerAd() async {
    try {
      print('🔄 Loading guest screen banner ad...');
      print('🔍 Using guest banner ad unit ID: $_guestBannerAdUnitId');

      _bannerAd = BannerAd(
        adUnitId: _guestBannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('✅ Guest banner ad loaded successfully');
            isAdReady.value = true;
          },
          onAdFailedToLoad: (ad, error) {
            print('❌ Guest banner ad failed to load: $error');
            print('❌ Error code: ${error.code}');
            print('❌ Error domain: ${error.domain}');
            print('❌ Error message: ${error.message}');
            isAdReady.value = false;
            ad.dispose();
            // Try to reload after a delay
            Future.delayed(const Duration(seconds: 10), () {
              print('🔄 Retrying guest banner ad load...');
              loadGuestBannerAd();
            });
          },
          onAdOpened: (ad) {
            print('📖 Guest banner ad opened');
          },
          onAdClosed: (ad) {
            print('✅ Guest banner ad closed');
          },
        ),
      );

      print('📞 Calling load() on guest banner ad...');
      await _bannerAd!.load();
      print('📞 Guest banner ad load() call completed');
    } catch (e) {
      print('❌ Exception loading guest banner ad: $e');
    }
  }

  /// Get the guest banner ad unit ID based on platform
  String get _guestBannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return guestBannerAdUnitIdAndroid;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return guestBannerAdUnitIdIOS;
    } else {
      // Fallback to Android ID for other platforms (though they won't be supported)
      return guestBannerAdUnitIdAndroid;
    }
  }
}
