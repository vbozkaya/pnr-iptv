import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  // Bellek kullanımını sınırla
  static const int maxMemoryCacheSize = 10; // Maksimum 10 öğe
  static const int maxDiskCacheSize = 10 * 1024 * 1024; // 10MB disk cache
  final Map<String, dynamic> _memoryCache = {};

  /// Cache data in memory
  void cacheData(String key, dynamic data) {
    // Bellek cache boyutunu sınırla
    if (_memoryCache.length >= maxMemoryCacheSize) {
      // En eski öğeyi kaldır
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
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
    // Resim yükleme devre dışı (performans için)
    // Gelecekte optimize edilmiş resim sistemi eklenecek
  }
} 