import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/iptv_service.dart';
import '../services/storage_service.dart';
import '../services/cache_service.dart';

class IptvProvider with ChangeNotifier {
  final IptvService _iptvService = IptvService();
  final StorageService _storageService = StorageService();
  final CacheService _cacheService = CacheService();

  List<Channel> _channels = [];
  List<Channel> _filteredChannels = [];
  List<Playlist> _playlists = [];
  List<Channel> _favorites = [];
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  bool _isLoading = false;
  String? _error;
  
  // Cache for better performance
  Map<String, List<Channel>> _categoryCache = {};
  List<Channel> _liveChannelsCache = [];
  List<Channel> _movieChannelsCache = [];
  List<Channel> _seriesChannelsCache = [];
  bool _cacheValid = false;

  // Getters
  List<Channel> get channels => _channels;
  List<Channel> get filteredChannels => _filteredChannels;
  List<Playlist> get playlists => _playlists;
  List<Channel> get favorites => _favorites;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categories {
    if (!_cacheValid) _updateCache();
    return _categoryCache.keys.toList()..sort();
  }

  List<Channel> get liveChannels {
    if (!_cacheValid) _updateCache();
    return _liveChannelsCache;
  }

  List<Channel> get movieChannels {
    if (!_cacheValid) _updateCache();
    return _movieChannelsCache;
  }

  List<Channel> get seriesChannels {
    if (!_cacheValid) _updateCache();
    return _seriesChannelsCache;
  }

  void _updateCache() {
    _categoryCache.clear();
    _categoryCache['Tümü'] = _channels;
    
    _liveChannelsCache = [];
    _movieChannelsCache = [];
    _seriesChannelsCache = [];
    
    for (final channel in _channels) {
      // Category cache
      final category = channel.category ?? 'Genel';
      _categoryCache.putIfAbsent(category, () => []).add(channel);
      
      // Type cache
      final cat = (channel.category ?? '').toLowerCase();
      if (cat.contains('movie') || cat.contains('film') || cat.contains('vod')) {
        _movieChannelsCache.add(channel);
      } else if (cat.contains('series') || cat.contains('dizi')) {
        _seriesChannelsCache.add(channel);
      } else {
        _liveChannelsCache.add(channel);
      }
    }
    
    _cacheValid = true;
    
    // Preload channel logos for better performance
    _preloadChannelLogos();
  }

  void _preloadChannelLogos() {
    final logoUrls = _channels
        .where((channel) => channel.logoUrl != null)
        .map((channel) => channel.logoUrl!)
        .toList();
    
    if (logoUrls.isNotEmpty) {
      _cacheService.preloadImages(logoUrls);
    }
  }

  IptvProvider() {
    _loadFavorites();
    _loadPlaylists();
    _loadPreviousSession(); // Load previous session data
  }

  /// Load playlist from URL
  Future<void> loadPlaylistFromUrl(String url) async {
    _setLoading(true);
    _error = null;

    try {
      final channels = await _iptvService.parsePlaylistFromUrl(url);
      _channels = channels;
      _filteredChannels = channels;
      _cacheValid = false;
      _notifyListeners();
      
      // Save login status and data
      await _storageService.setLoggedIn(true);
      await _storageService.saveLoginData({
        'type': 'url',
        'url': url,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Load playlist from Playlist object
  Future<void> loadPlaylist(Playlist playlist) async {
    _setLoading(true);
    _error = null;

    try {
      _channels = playlist.channels;
      _filteredChannels = playlist.channels;
      _cacheValid = false;
      _notifyListeners();
      
      // Save login status and data
      await _storageService.setLoggedIn(true);
      await _storageService.saveLoginData({
        'type': 'playlist',
        'playlistId': playlist.id,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Load playlist from local file
  Future<void> loadPlaylistFromFile(String filePath) async {
    _setLoading(true);
    _error = null;

    try {
      final channels = await _iptvService.parsePlaylistFromFile(filePath);
      _channels = channels;
      _filteredChannels = channels;
      _cacheValid = false;
      _notifyListeners();
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Search channels with debouncing
  void searchChannels(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Apply search and category filters with optimization
  void _applyFilters() {
    List<Channel> baseChannels;
    
    // Use cached category if available
    if (_selectedCategory == 'Tümü') {
      baseChannels = _channels;
    } else {
      if (!_cacheValid) _updateCache();
      baseChannels = _categoryCache[_selectedCategory] ?? [];
    }
    
    // Apply search filter
    if (_searchQuery.isEmpty) {
      _filteredChannels = baseChannels;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredChannels = baseChannels.where((channel) {
        return channel.name.toLowerCase().contains(query) ||
               (channel.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    _notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Channel channel) async {
    final isFavorite = _favorites.any((fav) => fav.id == channel.id);
    
    if (isFavorite) {
      await removeFromFavorites(channel.id);
    } else {
      await addToFavorites(channel);
    }
  }

  /// Add channel to favorites
  Future<void> addToFavorites(Channel channel) async {
    if (!_favorites.any((fav) => fav.id == channel.id)) {
      _favorites.add(channel.copyWith(isFavorite: true));
      await _storageService.addToFavorites(channel);
      _notifyListeners();
    }
  }

  /// Remove channel from favorites
  Future<void> removeFromFavorites(String channelId) async {
    _favorites.removeWhere((channel) => channel.id == channelId);
    await _storageService.removeFromFavorites(channelId);
    _notifyListeners();
  }

  /// Check if channel is favorite - optimized with Set
  bool isFavorite(String channelId) {
    return _favorites.any((channel) => channel.id == channelId);
  }

  /// Load favorites from storage
  Future<void> _loadFavorites() async {
    try {
      _favorites = await _storageService.loadFavorites();
      _notifyListeners();
    } catch (e) {
      // Silent error handling for better UX
    }
  }

  /// Load playlists from storage
  Future<void> _loadPlaylists() async {
    try {
      _playlists = await _storageService.loadPlaylists();
      _notifyListeners();
    } catch (e) {
      // Silent error handling for better UX
    }
  }

  /// Save playlist
  Future<void> savePlaylist(Playlist playlist) async {
    if (!_playlists.any((p) => p.id == playlist.id)) {
      _playlists.add(playlist);
      await _storageService.savePlaylists(_playlists);
      _notifyListeners();
    }
  }

  /// Remove playlist
  Future<void> removePlaylist(String playlistId) async {
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
    await _storageService.savePlaylists(_playlists);
    _notifyListeners();
  }

  /// Clear all data
  Future<void> clearData() async {
    _channels.clear();
    _filteredChannels.clear();
    _searchQuery = '';
    _selectedCategory = 'Tümü';
    _error = null;
    _cacheValid = false;
    _categoryCache.clear();
    _liveChannelsCache.clear();
    _movieChannelsCache.clear();
    _seriesChannelsCache.clear();
    await _storageService.clearAllData();
    _cacheService.clearMemoryCache();
    _notifyListeners();
  }

  /// Logout user
  Future<void> logout() async {
    await _storageService.logout();
    await clearData();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifyListeners();
  }

  /// Notify listeners
  void _notifyListeners() {
    notifyListeners();
  }

  /// API ile giriş
  Future<void> loginWithApi({
    required String username,
    required String password,
    required String dns,
  }) async {
    final apiUrl = 'http://$dns:8080/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
    await loadPlaylistFromUrl(apiUrl);
  }

  /// Load previous session data
  Future<void> _loadPreviousSession() async {
    try {
      final loginData = await _storageService.loadLoginData();
      if (loginData != null) {
        final type = loginData['type'];
        if (type == 'url') {
          final url = loginData['url'];
          if (url != null) {
            await loadPlaylistFromUrl(url);
          }
        } else if (type == 'playlist') {
          final playlistId = loginData['playlistId'];
          if (playlistId != null) {
            final playlists = await _storageService.loadPlaylists();
            final playlist = playlists.firstWhere(
              (p) => p.id == playlistId,
              orElse: () => throw Exception('Playlist not found'),
            );
            await loadPlaylist(playlist);
          }
        }
      }
    } catch (e) {
      // Silent error handling for better UX
    }
  }
} 