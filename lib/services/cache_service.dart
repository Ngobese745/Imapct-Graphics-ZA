import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Advanced caching service for seamless app performance
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CachedStream> _cache = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  SharedPreferences? _prefs;

  // Performance settings
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const Duration shortCacheDuration = Duration(minutes: 1);
  static const Duration longCacheDuration = Duration(hours: 1);
  static const int maxMemoryCacheSize = 100;

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get or create a cached stream with enhanced performance
  Stream<T> getCachedStream<T>(
    String key,
    Stream<T> Function() streamFactory, {
    Duration? cacheDuration,
    bool enableMemoryCache = true,
    bool enablePersistentCache = false,
  }) {
    // Check memory cache first
    if (enableMemoryCache && _memoryCache.containsKey(key)) {
      final cached = _memoryCache[key];
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && _isCacheValid(timestamp, cacheDuration)) {
        return Stream.value(cached as T);
      }
    }

    // Check persistent cache if enabled
    if (enablePersistentCache && _prefs != null) {
      final cachedData = _prefs!.getString('cache_$key');
      if (cachedData != null) {
        try {
          final decoded = jsonDecode(cachedData);
          final timestamp = _prefs!.getInt('cache_time_$key');
          if (timestamp != null &&
              _isCacheValid(
                DateTime.fromMillisecondsSinceEpoch(timestamp),
                cacheDuration,
              )) {
            _memoryCache[key] = decoded;
            _cacheTimestamps[key] = DateTime.fromMillisecondsSinceEpoch(
              timestamp,
            );
            return Stream.value(decoded as T);
          }
        } catch (e) {
          print('Error reading persistent cache for $key: $e');
        }
      }
    }

    // Create new stream and cache it
    final stream = streamFactory();
    _cache[key] = _CachedStream<T>(stream);

    // Cache the first value from the stream
    stream.take(1).listen((data) {
      if (enableMemoryCache) {
        _cacheInMemory(key, data);
      }
      if (enablePersistentCache && _prefs != null) {
        _cachePersistently(key, data);
      }
    });

    return stream;
  }

  /// Cache data in memory
  void _cacheInMemory(String key, dynamic data) {
    // Implement LRU cache eviction
    if (_memoryCache.length >= maxMemoryCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Cache data persistently
  Future<void> _cachePersistently(String key, dynamic data) async {
    if (_prefs == null) return;

    try {
      // Convert Firestore Timestamps to serializable format
      final sanitizedData = _sanitizeForJson(data);
      await _prefs!.setString('cache_$key', jsonEncode(sanitizedData));
      await _prefs!.setInt(
        'cache_time_$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silently fail for non-serializable data, keeping memory cache only
      // print('Error caching data persistently for $key: $e');
    }
  }

  /// Sanitize data for JSON encoding by converting Firestore Timestamps
  dynamic _sanitizeForJson(dynamic data) {
    if (data == null) return null;

    // Handle Timestamp objects
    if (data.runtimeType.toString().contains('Timestamp')) {
      try {
        // Convert Timestamp to milliseconds
        final timestamp = data as dynamic;
        return timestamp.millisecondsSinceEpoch;
      } catch (e) {
        return null;
      }
    }

    // Handle List
    if (data is List) {
      return data.map((item) => _sanitizeForJson(item)).toList();
    }

    // Handle Map
    if (data is Map) {
      return data.map((key, value) => MapEntry(key, _sanitizeForJson(value)));
    }

    // Return primitive types as is
    return data;
  }

  /// Check if cache is still valid
  bool _isCacheValid(DateTime timestamp, Duration? cacheDuration) {
    final duration = cacheDuration ?? defaultCacheDuration;
    return DateTime.now().difference(timestamp) < duration;
  }

  /// Debounce a function call
  void debounce(
    String key,
    Function callback, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(duration, () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Clear specific cache entry
  void clearCache(String key) {
    _cache.remove(key);
  }

  /// Clear all caches
  void clearAllCaches() {
    _cache.clear();
  }

  /// Cancel all pending debounce timers
  void cancelAllDebounces() {
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  /// Preload data for better UX
  Future<void> preloadData<T>(
    String key,
    Future<T> Function() dataFactory, {
    Duration? cacheDuration,
    bool enablePersistentCache = false,
  }) async {
    try {
      final data = await dataFactory();
      _cacheInMemory(key, data);
      if (enablePersistentCache) {
        await _cachePersistently(key, data);
      }
    } catch (e) {
      print('Error preloading data for $key: $e');
    }
  }

  /// Get cached data synchronously (for immediate UI updates)
  T? getCachedData<T>(String key) {
    if (_memoryCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && _isCacheValid(timestamp, null)) {
        return _memoryCache[key] as T?;
      }
    }
    return null;
  }

  /// Warm up cache with critical data
  Future<void> warmUpCache() async {
    await initialize();
    // This will be called by specific services to preload their data
  }

  /// Clear old cache entries
  Future<void> cleanupOldCache() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > Duration(hours: 24)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      _cache.remove(key);
    }

    // Clean up persistent cache
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_time_')) {
          final timestamp = _prefs!.getInt(key);
          if (timestamp != null &&
              now.difference(DateTime.fromMillisecondsSinceEpoch(timestamp)) >
                  Duration(hours: 24)) {
            final dataKey = key.replaceFirst('cache_time_', 'cache_');
            await _prefs!.remove(key);
            await _prefs!.remove(dataKey);
          }
        }
      }
    }
  }

  void dispose() {
    cancelAllDebounces();
    clearAllCaches();
  }
}

class _CachedStream<T> {
  final Stream<T> stream;
  final DateTime createdAt;

  _CachedStream(this.stream) : createdAt = DateTime.now();

  bool isValid(Duration? cacheDuration) {
    if (cacheDuration == null) return true;
    return DateTime.now().difference(createdAt) < cacheDuration;
  }
}
