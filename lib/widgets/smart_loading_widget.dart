import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/performance_service.dart';
import 'skeleton_loader.dart';

/// Smart loading widget that provides seamless data loading with caching
class SmartLoadingWidget<T> extends StatefulWidget {
  final String cacheKey;
  final Future<T> Function() dataFactory;
  final Stream<T> Function()? streamFactory;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, String error)? errorWidget;
  final Duration? cacheDuration;
  final bool enablePersistentCache;
  final bool enableMemoryCache;
  final bool showSkeletonWhileLoading;
  final Duration fadeInDuration;

  const SmartLoadingWidget({
    super.key,
    required this.cacheKey,
    required this.dataFactory,
    this.streamFactory,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.cacheDuration,
    this.enablePersistentCache = false,
    this.enableMemoryCache = true,
    this.showSkeletonWhileLoading = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SmartLoadingWidget<T>> createState() => _SmartLoadingWidgetState<T>();
}

class _SmartLoadingWidgetState<T> extends State<SmartLoadingWidget<T>>
    with TickerProviderStateMixin {
  final PerformanceService _performanceService = PerformanceService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  T? _cachedData;
  T? _streamData;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadData() async {
    // Try to get cached data first for instant UI update
    _cachedData = _performanceService.getCachedData<T>(widget.cacheKey);

    if (_cachedData != null) {
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();
    }

    // Load fresh data in background
    try {
      final data = await widget.dataFactory();

      if (mounted) {
        setState(() {
          _cachedData = data;
          _isLoading = false;
          _hasError = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show cached data immediately if available
    if (_cachedData != null && !_hasError) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: widget.builder(context, _cachedData as T),
      );
    }

    // Show error state
    if (_hasError) {
      return widget.errorWidget?.call(
            context,
            _errorMessage ?? 'Unknown error',
          ) ??
          _buildDefaultErrorWidget();
    }

    // Show loading state
    if (_isLoading) {
      return widget.loadingWidget ??
          (widget.showSkeletonWhileLoading
              ? _buildSkeletonWidget()
              : _buildDefaultLoadingWidget());
    }

    // This should not be reached, but just in case
    return _buildDefaultLoadingWidget();
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _loadData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
      ),
    );
  }

  Widget _buildSkeletonWidget() {
    // Return appropriate skeleton based on context
    return const SkeletonList(itemCount: 3);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

/// Smart stream widget with caching and seamless updates
class SmartStreamWidget<T> extends StatefulWidget {
  final String cacheKey;
  final Stream<T> Function() streamFactory;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, String error)? errorWidget;
  final Duration? cacheDuration;
  final bool enablePersistentCache;
  final bool enableMemoryCache;
  final bool showSkeletonWhileLoading;
  final Duration fadeInDuration;

  const SmartStreamWidget({
    super.key,
    required this.cacheKey,
    required this.streamFactory,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.cacheDuration,
    this.enablePersistentCache = false,
    this.enableMemoryCache = true,
    this.showSkeletonWhileLoading = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SmartStreamWidget<T>> createState() => _SmartStreamWidgetState<T>();
}

class _SmartStreamWidgetState<T> extends State<SmartStreamWidget<T>>
    with TickerProviderStateMixin {
  final PerformanceService _performanceService = PerformanceService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  T? _cachedData;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCachedData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  void _loadCachedData() {
    _cachedData = _performanceService.getCachedData<T>(widget.cacheKey);
    if (_cachedData != null) {
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: _performanceService.getOptimizedStream<T>(
        widget.cacheKey,
        widget.streamFactory,
        cacheDuration: widget.cacheDuration,
        enableMemoryCache: widget.enableMemoryCache,
        enablePersistentCache: widget.enablePersistentCache,
      ),
      builder: (context, snapshot) {
        // Show cached data immediately if stream is loading
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedData != null) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: widget.builder(context, _cachedData as T),
          );
        }

        // Show error state
        if (snapshot.hasError) {
          return widget.errorWidget?.call(context, snapshot.error.toString()) ??
              _buildDefaultErrorWidget(snapshot.error.toString());
        }

        // Show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ??
              (widget.showSkeletonWhileLoading
                  ? const SkeletonList(itemCount: 3)
                  : _buildDefaultLoadingWidget());
        }

        // Show data
        if (snapshot.hasData) {
          _fadeController.forward();
          return FadeTransition(
            opacity: _fadeAnimation,
            child: widget.builder(context, snapshot.data as T),
          );
        }

        return _buildDefaultLoadingWidget();
      },
    );
  }

  Widget _buildDefaultErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
