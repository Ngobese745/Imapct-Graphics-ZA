import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cache_service.dart';
import '../services/firebase_service.dart';
import '../services/wallet_service.dart';
import '../services/banner_ad_service.dart';

/// Advanced performance service for seamless app experience
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final CacheService _cacheService = CacheService();
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  Timer? _backgroundRefreshTimer;
  Timer? _cacheCleanupTimer;

  // Lazy getter for Firestore instance
  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Initialize performance optimizations
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _cacheService.initialize();
    await _cacheService.warmUpCache();

    // Preload critical data
    await _preloadCriticalData();

    // Start background refresh timer
    _startBackgroundRefresh();

    // Start cache cleanup timer
    _startCacheCleanup();

    _isInitialized = true;
    print('🚀 Performance service initialized');
  }

  /// Preload critical data for instant UI updates
  Future<void> _preloadCriticalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final futures = <Future>[];

    // Preload user wallet data
    futures.add(
      _cacheService.preloadData(
        'user_wallet_${user.uid}',
        () => WalletService.getUserWallet(user.uid),
        enablePersistentCache: true,
      ),
    );

    // Preload portfolio data (accessible to all users)
    futures.add(
      _cacheService.preloadData(
        'portfolio_data',
        () async {
          final snapshot = await firestore
              .collection('shared_links')
              .orderBy('createdAt', descending: true)
              .get();
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        },
        cacheDuration: CacheService.longCacheDuration,
        enablePersistentCache: true,
      ),
    );

    // Preload services data
    futures.add(
      _cacheService.preloadData(
        'services_data',
        () async {
          final snapshot = await firestore.collection('services').get();
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        },
        cacheDuration: CacheService.longCacheDuration,
        enablePersistentCache: true,
      ),
    );

    // Preload categories data
    futures.add(
      _cacheService.preloadData(
        'categories_data',
        () async {
          final snapshot = await firestore.collection('categories').get();
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        },
        cacheDuration: CacheService.longCacheDuration,
        enablePersistentCache: true,
      ),
    );

    // Initialize banner ads in background
    futures.add(_preloadBannerAds());

    // Wait for all preloading to complete
    await Future.wait(futures);
    print('✅ Critical data preloaded successfully');
  }

  /// Preload banner ads for smoother experience
  Future<void> _preloadBannerAds() async {
    try {
      final bannerAdService = BannerAdService();
      await bannerAdService.initialize();
      print('✅ Banner ads preloaded');
    } catch (e) {
      print('⚠️ Banner ad preloading failed: $e');
    }
  }

  /// Start background refresh timer
  void _startBackgroundRefresh() {
    _backgroundRefreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _refreshBackgroundData(),
    );
  }

  /// Refresh background data
  Future<void> _refreshBackgroundData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Refresh wallet data in background
      final wallet = await WalletService.getUserWallet(user.uid);
      if (wallet != null) {
        // Cache the wallet data using the public method
        await _cacheService.preloadData(
          'user_wallet_${user.uid}',
          () async => wallet,
        );
      }

      // Refresh portfolio data in background
      final portfolioSnapshot = await firestore
          .collection('shared_links')
          .orderBy('createdAt', descending: true)
          .get();
      final portfolioData = portfolioSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      await _cacheService.preloadData(
        'portfolio_data',
        () async => portfolioData,
      );

      print('🔄 Background data refreshed');
    } catch (e) {
      print('⚠️ Background refresh failed: $e');
    }
  }

  /// Start cache cleanup timer
  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cacheService.cleanupOldCache(),
    );
  }

  /// Get cached data for immediate UI updates
  T? getCachedData<T>(String key) {
    return _cacheService.getCachedData<T>(key);
  }

  /// Get cached stream with performance optimizations
  Stream<T> getOptimizedStream<T>(
    String key,
    Stream<T> Function() streamFactory, {
    Duration? cacheDuration,
    bool enableMemoryCache = true,
    bool enablePersistentCache = false,
  }) {
    return _cacheService.getCachedStream<T>(
      key,
      streamFactory,
      cacheDuration: cacheDuration,
      enableMemoryCache: enableMemoryCache,
      enablePersistentCache: enablePersistentCache,
    );
  }

  /// Debounce function calls
  void debounce(
    String key,
    Function callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    _cacheService.debounce(key, callback, duration: duration);
  }

  /// Clear specific cache
  void clearCache(String key) {
    _cacheService.clearCache(key);
  }

  /// Force refresh data
  Future<void> forceRefresh<T>(
    String key,
    Future<T> Function() dataFactory,
  ) async {
    await _cacheService.preloadData<T>(key, dataFactory);
  }

  /// Dispose of resources
  void dispose() {
    _backgroundRefreshTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    _cacheService.dispose();
    _isInitialized = false;
  }
}
