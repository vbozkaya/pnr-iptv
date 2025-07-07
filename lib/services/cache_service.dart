import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final Map<String, dynamic> _memoryCache = {};

  /// Cache data in memory
  void cacheData(String key, dynamic data) {
    _memoryCache[key] = data;
  }

  /// Get cached data from memory
  dynamic getCachedData(String key) {
    return _memoryCache[key];
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// Check if data is cached
  bool isCached(String key) {
    return _memoryCache.containsKey(key);
  }

  /// Get cache manager for images
  DefaultCacheManager get cacheManager => _cacheManager;

  /// Clear all caches
  Future<void> clearAllCaches() async {
    _memoryCache.clear();
    await _cacheManager.emptyCache();
  }

  /// Check network connectivity
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> imageUrls) async {
    if (!await isConnected()) return;
    
    for (final url in imageUrls) {
      try {
        await _cacheManager.getSingleFile(url);
      } catch (e) {
        // Silent fail for preloading
      }
    }
  }
} 