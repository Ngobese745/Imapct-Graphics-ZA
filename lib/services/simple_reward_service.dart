import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SimpleRewardService {
  static final SimpleRewardService _instance = SimpleRewardService._internal();
  factory SimpleRewardService() => _instance;
  SimpleRewardService._internal();

  // Live rewarded ad unit IDs
  static const String rewardedAdUnitIdAndroid =
      'ca-app-pub-2168762108450116/5929980186';
  static const String rewardedAdUnitIdIOS =
      'ca-app-pub-2168762108450116/6988583430';

  // Daily limits
  static const int MAX_ADS_PER_DAY = 100;
  static const double TOTAL_DAILY_REWARD =
      10.0; // R10 for completing all 100 ads

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  bool _isInitialized = false;

  bool get isRewardedAdReady => _isRewardedAdReady;
  // AdMob is not supported on web - only on mobile platforms
  bool get isSupported => !kIsWeb;

  // Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isSupported) {
      print('⚠️ AdMob not supported on this platform');
      return;
    }

    try {
      print('=== INITIALIZING SIMPLE REWARD SERVICE ===');

      // Check if MobileAds is already initialized
      try {
        await MobileAds.instance.initialize();
        print('✅ MobileAds initialized for SimpleRewardService');
      } catch (e) {
        print('⚠️ MobileAds may already be initialized: $e');
      }

      await _loadRewardedAd();
      _isInitialized = true;
      print('✅ Simple Reward Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Simple Reward Service: $e');
    }
  }

  // Load rewarded ad
  Future<void> _loadRewardedAd() async {
    try {
      print('🔄 Loading live rewarded ad...');

      final adUnitId = defaultTargetPlatform == TargetPlatform.android
          ? rewardedAdUnitIdAndroid
          : rewardedAdUnitIdIOS;
      print('🔍 Using live rewarded ad unit ID: $adUnitId');

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('✅ Live rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isRewardedAdReady = true;

            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) {
                print('🎬 Live rewarded ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                print('✅ Live rewarded ad dismissed');
                ad.dispose();
                _isRewardedAdReady = false;
                _loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent:
                  (RewardedAd ad, AdError error) {
                    print('❌ Live rewarded ad failed to show: $error');
                    ad.dispose();
                    _isRewardedAdReady = false;
                    _loadRewardedAd();
                  },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('❌ Live rewarded ad failed to load: $error');
            _isRewardedAdReady = false;
          },
        ),
      );
    } catch (e) {
      print('❌ Error loading live rewarded ad: $e');
      _isRewardedAdReady = false;
    }
  }

  // Check if user can watch more ads today
  Future<bool> canWatchMoreAds() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final today = _getTodayString();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return true;

      final userData = userDoc.data() as Map<String, dynamic>;
      final dailyAdData =
          userData['dailyAdData'] as Map<String, dynamic>? ?? {};
      final todayData = dailyAdData[today] as Map<String, dynamic>? ?? {};
      final adsWatched = todayData['adsWatched'] as int? ?? 0;

      return adsWatched < MAX_ADS_PER_DAY;
    } catch (e) {
      print('❌ Error checking daily limit: $e');
      return true;
    }
  }

  // Get today's date string
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Show rewarded ad and handle everything
  Future<Map<String, dynamic>> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      return {'success': false, 'error': 'Ad not ready'};
    }

    if (!await canWatchMoreAds()) {
      return {'success': false, 'error': 'Daily limit reached'};
    }

    try {
      print('🎬 Showing live rewarded ad...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Show the ad
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('🎉 USER EARNED REWARD FROM LIVE AD!');
          print('Reward amount: ${reward.amount}');
          print('Reward type: ${reward.type}');
        },
      );

      // Process the reward (always credit if ad was shown)
      final result = await _processAdReward(user.uid);

      return result;
    } catch (e) {
      print('❌ Error showing live rewarded ad: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Process ad reward and update daily tracking
  Future<Map<String, dynamic>> _processAdReward(String userId) async {
    try {
      print('💰 Processing ad reward...');

      final today = _getTodayString();
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);

      // Get current user data
      final userDoc = await userRef.get();
      final userData = userDoc.exists
          ? userDoc.data() as Map<String, dynamic>
          : {};
      final dailyAdData =
          userData['dailyAdData'] as Map<String, dynamic>? ?? {};
      final todayData = dailyAdData[today] as Map<String, dynamic>? ?? {};

      // Update counters
      final currentAdsWatched = todayData['adsWatched'] as int? ?? 0;
      final newAdsWatched = currentAdsWatched + 1;
      final currentBalance = (userData['walletBalance'] ?? 0.0).toDouble();
      final isRewardClaimed = todayData['isRewardClaimed'] as bool? ?? false;

      // Check if user reached 20 ads and hasn't claimed yet
      final reachedLimit = newAdsWatched >= MAX_ADS_PER_DAY;
      final shouldCreditWallet = reachedLimit && !isRewardClaimed;

      // Calculate reward only if claiming all 20 ads
      final rewardAmount = shouldCreditWallet ? TOTAL_DAILY_REWARD : 0.0;
      final newBalance = currentBalance + rewardAmount;

      // Update today's data
      final updatedTodayData = {
        'adsWatched': newAdsWatched,
        'lastAdWatched': FieldValue.serverTimestamp(),
        'date': today,
        'isRewardClaimed': shouldCreditWallet ? true : isRewardClaimed,
        if (shouldCreditWallet) 'rewardClaimedAt': FieldValue.serverTimestamp(),
      };

      dailyAdData[today] = updatedTodayData;

      // Update user document - only credit wallet if reached 20 ads
      if (shouldCreditWallet) {
        await userRef.update({
          'dailyAdData': dailyAdData,
          'walletBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create transaction record for the full R10 reward
        await FirebaseFirestore.instance.collection('walletTransactions').add({
          'userId': userId,
          'amount': TOTAL_DAILY_REWARD,
          'type': 'credit',
          'description': 'Daily ad reward - watched $MAX_ADS_PER_DAY ads',
          'balance': newBalance,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print(
          '🎉 DAILY LIMIT REACHED! Wallet credited with R$TOTAL_DAILY_REWARD',
        );
        print('New balance: R$newBalance');
      } else {
        // Just update ad count, no wallet credit
        await userRef.update({
          'dailyAdData': dailyAdData,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Ad watch recorded (no wallet credit yet)');
        print('Ads watched today: $newAdsWatched/$MAX_ADS_PER_DAY');
        print(
          'Watch ${MAX_ADS_PER_DAY - newAdsWatched} more ads to earn R$TOTAL_DAILY_REWARD',
        );
      }

      return {
        'success': true,
        'adsWatched': newAdsWatched,
        'maxAds': MAX_ADS_PER_DAY,
        'rewardAmount': rewardAmount,
        'newBalance': newBalance,
        'canWatchMore': newAdsWatched < MAX_ADS_PER_DAY,
        'rewardClaimed': shouldCreditWallet,
      };
    } catch (e) {
      print('❌ Error processing ad reward: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get daily progress
  Future<Map<String, dynamic>> getDailyProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'adsWatched': 0,
          'maxAds': MAX_ADS_PER_DAY,
          'canWatchMore': true,
        };
      }

      final today = _getTodayString();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return {
          'adsWatched': 0,
          'maxAds': MAX_ADS_PER_DAY,
          'canWatchMore': true,
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final dailyAdData =
          userData['dailyAdData'] as Map<String, dynamic>? ?? {};
      final todayData = dailyAdData[today] as Map<String, dynamic>? ?? {};
      final adsWatched = todayData['adsWatched'] as int? ?? 0;

      return {
        'adsWatched': adsWatched,
        'maxAds': MAX_ADS_PER_DAY,
        'canWatchMore': adsWatched < MAX_ADS_PER_DAY,
        'remainingAds': MAX_ADS_PER_DAY - adsWatched,
      };
    } catch (e) {
      print('❌ Error getting daily progress: $e');
      return {'adsWatched': 0, 'maxAds': MAX_ADS_PER_DAY, 'canWatchMore': true};
    }
  }

  // Dispose resources
  void dispose() {
    _rewardedAd?.dispose();
    _isRewardedAdReady = false;
  }
}
