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
      // Smart category detection
      final smartCategory = _getSmartCategory(channel);
      _categoryCache.putIfAbsent(smartCategory, () => []).add(channel);
      
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

    // --- KANAL LİSTESİNİ TERMİNALE YAZDIR ---
    print('--- CANLI KANALLAR LİSTESİ ---');
    for (final channel in _liveChannelsCache) {
      print('Kanal: ${channel.name} | Açıklama: ${channel.description ?? "Yok"} | Kategori: ${_getSmartCategory(channel)}');
    }
    print('--- TOPLAM: ${_liveChannelsCache.length} KANAL ---');
  }

  /// Get the smart category for a channel (public method)
  String getChannelCategory(Channel channel) {
    return _getSmartCategory(channel);
  }

  /// Smart category detection based on channel description and original category
  String _getSmartCategory(Channel channel) {
    final name = channel.name.toLowerCase();
    final originalCategory = (channel.category ?? '').toLowerCase();
    final description = (channel.description ?? '').toLowerCase();

    // TR Ulusal Kanalları
    if (description.contains('tr ∞ ulusal') || description.contains('tr ulusal') || description.contains('ulusal') ||
        name.contains('trt') || name.contains('atv') || name.contains('show') || name.contains('kanal d') ||
        name.contains('tv8') || name.contains('habertürk') || name.contains('cnn türk') || name.contains('ntv') ||
        name.contains('fox') || name.contains('star') || name.contains('kanal 7') || name.contains('samanyolu') ||
        name.contains('tgrthaber') || name.contains('a haber') || name.contains('ulusal') ||
        name.contains('a2 tv') || name.contains('teve2') || name.contains('beyaz tv') || name.contains('360 tv')) {
      return 'TR Ulusal';
    }

    // TR Yerel Kanallar
    if (description.contains('tr ∞ yerel') || description.contains('tr yerel') || description.contains('yerel') ||
        name.contains('yerel') || name.contains('bursa') || name.contains('izmir') || name.contains('antalya') ||
        name.contains('adana') || name.contains('ankara') || name.contains('konya') || name.contains('trabzon') ||
        name.contains('gaziantep') || name.contains('kayseri') || name.contains('samsun') || name.contains('eskişehir')) {
      return 'TR Yerel';
    }

    // TR Magazin
    if (name.contains('magazin') || name.contains('magazine')) {
      return 'TR Magazin';
    }

    // TR Dini
    if (name.contains('dini') || name.contains('ilahiyat') || name.contains('mevlana') || name.contains('diyanet') ||
        name.contains('islam') || name.contains('kur-an') || name.contains('kuran') || name.contains('imam')) {
      return 'TR Dini';
    }

    // TR Alışveriş
    if (name.contains('alışveriş') || name.contains('alisveris') || name.contains('shopping') || name.contains('shop')) {
      return 'TR Alışveriş';
    }

    // TR Eğitim
    if (name.contains('eğitim') || name.contains('egitim') || name.contains('okul') || name.contains('üniversite') ||
        name.contains('universite') || name.contains('ders') || name.contains('education') || name.contains('school')) {
      return 'TR Eğitim';
    }

    // TR Motospor
    if (name.contains('moto') || name.contains('motorsport') || name.contains('motorspor') || name.contains('formula') ||
        name.contains('f1') || name.contains('ralli') || name.contains('rally')) {
      return 'TR Motospor';
    }

    // TR Talk Show
    if (name.contains('talk show') || name.contains('sohbet') || name.contains('talkshow')) {
      return 'TR Talk Show';
    }

    // TR Yemek
    if (name.contains('yemek') || name.contains('mutfak') || name.contains('lezzet') || name.contains('food') ||
        name.contains('chef') || name.contains('aşçı') || name.contains('asci')) {
      return 'TR Yemek';
    }

    // TR Moda
    if (name.contains('moda') || name.contains('fashion')) {
      return 'TR Moda';
    }

    // TR Sağlık
    if (name.contains('sağlık') || name.contains('saglik') || name.contains('health') || name.contains('doktor') ||
        name.contains('hastane') || name.contains('hospital')) {
      return 'TR Sağlık';
    }

    // TR Hava Durumu
    if (name.contains('hava durumu') || name.contains('weather')) {
      return 'TR Hava Durumu';
    }

    // TR Oyun
    if (name.contains('oyun') || name.contains('game') || name.contains('gaming') || name.contains('e-spor') ||
        name.contains('espor')) {
      return 'TR Oyun';
    }

    // TR Ekonomi
    if (name.contains('ekonomi') || name.contains('economy') || name.contains('borsa') || name.contains('finans') ||
        name.contains('finance') || name.contains('para')) {
      return 'TR Ekonomi';
    }

    // TR Kültür
    if (name.contains('kültür') || name.contains('kultur') || name.contains('culture')) {
      return 'TR Kültür';
    }

    // TR Tarih
    if (name.contains('tarih') || name.contains('history')) {
      return 'TR Tarih';
    }

    // TR Otomobil
    if (name.contains('otomobil') || name.contains('araba') || name.contains('auto') || name.contains('car')) {
      return 'TR Otomobil';
    }

    // TR Hobi
    if (name.contains('hobi') || name.contains('hobby')) {
      return 'TR Hobi';
    }

    // TR Tatil
    if (name.contains('tatil') || name.contains('holiday') || name.contains('turizm') || name.contains('tourism')) {
      return 'TR Tatil';
    }

    // TR Spor (genel)
    if (description.contains('tr ∞ spor') || description.contains('tr spor') || description.contains('spor') ||
        name.contains('spor') || name.contains('sport') || originalCategory.contains('spor') || originalCategory.contains('sport')) {
      return 'TR Spor';
    }

    // TR Belgesel
    if (description.contains('tr ∞ belgesel') || description.contains('tr belgesel') || description.contains('belgesel') ||
        name.contains('belgesel') || name.contains('documentary') || originalCategory.contains('belgesel') || originalCategory.contains('documentary')) {
      return 'TR Belgesel';
    }

    // TR Çocuk
    if (description.contains('tr ∞ çocuk') || description.contains('tr çocuk') || description.contains('çocuk') ||
        name.contains('çocuk') || name.contains('cocuk') || name.contains('kids') || name.contains('cartoon') ||
        name.contains('disney') || originalCategory.contains('çocuk') || originalCategory.contains('kids')) {
      return 'TR Çocuk';
    }

    // TR Müzik
    if (description.contains('tr ∞ müzik') || description.contains('tr müzik') || description.contains('müzik') ||
        name.contains('müzik') || name.contains('muzik') || name.contains('music') || name.contains('kral') ||
        name.contains('powertürk') || originalCategory.contains('müzik') || originalCategory.contains('music')) {
      return 'TR Müzik';
    }

    // TR Eğlence
    if (description.contains('tr ∞ eğlence') || description.contains('tr eğlence') || description.contains('eğlence') ||
        name.contains('eğlence') || name.contains('eglence') || name.contains('entertainment') ||
        originalCategory.contains('eğlence') || originalCategory.contains('entertainment')) {
      return 'TR Eğlence';
    }

    // TR Haber
    if (description.contains('tr ∞ haber') || description.contains('tr haber') || description.contains('haber') ||
        name.contains('haber') || name.contains('news') || originalCategory.contains('haber') || originalCategory.contains('news')) {
      return 'TR Haber';
    }

    // TR Beinsport
    if (name.contains('beinsport') || name.contains('bein sport') || name.contains('s sport') ||
        name.contains('tivibu spor')) {
      return 'TR Beinsport';
    }

    // Yabancı Kanallar
    if (name.contains('bbc') || name.contains('cnn') || name.contains('sky') || name.contains('eurosport') ||
        name.contains('discovery') || name.contains('national geographic')) {
      return 'Yabancı Kanallar';
    }

    // Varsayılan olarak TR Genel
    return 'TR Genel';
  }

  void _preloadChannelLogos() {
    // Resim yükleme devre dışı (performans için)
    // Gelecekte optimize edilmiş resim sistemi eklenecek
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
    // Only clear current session data, not all stored data
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
    _cacheService.clearMemoryCache();
    _notifyListeners();
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