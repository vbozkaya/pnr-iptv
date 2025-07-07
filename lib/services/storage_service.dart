import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../models/user.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _playlistsKey = 'playlists';
  static const String _settingsKey = 'settings';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _loginDataKey = 'login_data';
  static const String _usersKey = 'users';
  static const String _activeUserKey = 'active_user';
  static const String _sessionsKey = 'sessions';

  static SharedPreferences? _prefs;
  
  // Initialize SharedPreferences
  static Future<void> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // Ensure SharedPreferences is initialized
  static Future<SharedPreferences> get _instance async {
    await init();
    return _prefs!;
  }

  /// Save favorite channels
  Future<void> saveFavorites(List<Channel> favorites) async {
    try {
      final prefs = await _instance;
      final favoritesJson = favorites.map((channel) => channel.toJson()).toList();
      await prefs.setString(_favoritesKey, jsonEncode(favoritesJson));
    } catch (e) {
      throw e;
    }
  }

  /// Load favorite channels
  Future<List<Channel>> loadFavorites() async {
    try {
      final prefs = await _instance;
      final favoritesString = prefs.getString(_favoritesKey);
      
      if (favoritesString == null) {
        return [];
      }
      
      final favoritesJson = jsonDecode(favoritesString) as List<dynamic>;
      final favorites = favoritesJson.map((json) => Channel.fromJson(json)).toList();
      return favorites;
    } catch (e) {
      return [];
    }
  }

  /// Add channel to favorites
  Future<void> addToFavorites(Channel channel) async {
    final favorites = await loadFavorites();
    if (!favorites.any((fav) => fav.id == channel.id)) {
      favorites.add(channel.copyWith(isFavorite: true));
      await saveFavorites(favorites);
    }
  }

  /// Remove channel from favorites
  Future<void> removeFromFavorites(String channelId) async {
    final favorites = await loadFavorites();
    favorites.removeWhere((channel) => channel.id == channelId);
    await saveFavorites(favorites);
  }

  /// Check if channel is favorite
  Future<bool> isFavorite(String channelId) async {
    final favorites = await loadFavorites();
    return favorites.any((channel) => channel.id == channelId);
  }

  /// Save playlists
  Future<void> savePlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await _instance;
      final playlistsJson = playlists.map((playlist) => playlist.toJson()).toList();
      final result = await prefs.setString(_playlistsKey, jsonEncode(playlistsJson));
      print('Save playlists result: $result, count: ${playlists.length}');
    } catch (e) {
      print('Error saving playlists: $e');
      throw e;
    }
  }

  /// Load playlists
  Future<List<Playlist>> loadPlaylists() async {
    try {
      final prefs = await _instance;
      final playlistsString = prefs.getString(_playlistsKey);
      
      if (playlistsString == null) {
        print('No playlists found in storage');
        return [];
      }
      
      final playlistsJson = jsonDecode(playlistsString) as List<dynamic>;
      final playlists = playlistsJson.map((json) => Playlist.fromJson(json)).toList();
      print('Loaded ${playlists.length} playlists from storage');
      return playlists;
    } catch (e) {
      print('Error loading playlists: $e');
      return [];
    }
  }

  /// Save settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await _instance;
      final result = await prefs.setString(_settingsKey, jsonEncode(settings));
      print('Save settings result: $result');
    } catch (e) {
      print('Error saving settings: $e');
      throw e;
    }
  }

  /// Load settings
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await _instance;
      final settingsString = prefs.getString(_settingsKey);
      
      if (settingsString == null) {
        return {
          'autoPlay': false,
          'quality': 'auto',
          'bufferSize': 10,
          'theme': 'dark',
        };
      }
      
      final settings = Map<String, dynamic>.from(jsonDecode(settingsString));
      print('Loaded settings: $settings');
      return settings;
    } catch (e) {
      print('Error loading settings: $e');
      return {
        'autoPlay': false,
        'quality': 'auto',
        'bufferSize': 10,
        'theme': 'dark',
      };
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await _instance;
      final result = prefs.getBool(_isLoggedInKey) ?? false;
      print('Is logged in: $result');
      return result;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Save login status
  Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      final prefs = await _instance;
      final result = await prefs.setBool(_isLoggedInKey, isLoggedIn);
      print('Set logged in result: $result, value: $isLoggedIn');
    } catch (e) {
      print('Error setting login status: $e');
      throw e;
    }
  }

  /// Save login data
  Future<void> saveLoginData(Map<String, dynamic> loginData) async {
    try {
      final prefs = await _instance;
      final result = await prefs.setString(_loginDataKey, jsonEncode(loginData));
      print('Save login data result: $result');
    } catch (e) {
      print('Error saving login data: $e');
      throw e;
    }
  }

  /// Load login data
  Future<Map<String, dynamic>?> loadLoginData() async {
    try {
      final prefs = await _instance;
      final loginDataString = prefs.getString(_loginDataKey);
      
      if (loginDataString == null) {
        print('No login data found');
        return null;
      }
      
      final loginData = Map<String, dynamic>.from(jsonDecode(loginDataString));
      print('Loaded login data: $loginData');
      return loginData;
    } catch (e) {
      print('Error loading login data: $e');
      return null;
    }
  }

  /// Save users list
  Future<void> saveUsers(List<User> users) async {
    try {
      final prefs = await _instance;
      final usersJson = users.map((user) => user.toJson()).toList();
      final result = await prefs.setString(_usersKey, jsonEncode(usersJson));
      print('Save users result: $result, count: ${users.length}');
      print('Users to save: ${users.map((u) => '${u.name}(${u.id})').join(', ')}');
    } catch (e) {
      print('Error saving users: $e');
      throw e;
    }
  }

  /// Load users list
  Future<List<User>> loadUsers() async {
    try {
      final prefs = await _instance;
      final usersString = prefs.getString(_usersKey);
      
      if (usersString == null) {
        print('No users found in storage');
        return [];
      }
      
      final usersJson = jsonDecode(usersString) as List<dynamic>;
      final users = usersJson.map((json) => User.fromJson(json)).toList();
      print('Loaded ${users.length} users from storage');
      print('Users loaded: ${users.map((u) => '${u.name}(${u.id})').join(', ')}');
      return users;
    } catch (e) {
      print('Error loading users: $e');
      return [];
    }
  }

  /// Save active user
  Future<void> saveActiveUser(User? user) async {
    try {
      final prefs = await _instance;
      if (user != null) {
        final result = await prefs.setString(_activeUserKey, jsonEncode(user.toJson()));
        print('Save active user result: $result, user: ${user.name}');
      } else {
        final result = await prefs.remove(_activeUserKey);
        print('Clear active user result: $result');
      }
    } catch (e) {
      print('Error saving active user: $e');
      throw e;
    }
  }

  /// Load active user
  Future<User?> loadActiveUser() async {
    try {
      final prefs = await _instance;
      final userString = prefs.getString(_activeUserKey);
      
      if (userString == null) {
        print('No active user found in storage');
        return null;
      }
      
      final userJson = jsonDecode(userString);
      final user = User.fromJson(userJson);
      print('Loaded active user: ${user.name}');
      return user;
    } catch (e) {
      print('Error loading active user: $e');
      return null;
    }
  }

  /// Save user sessions
  Future<void> saveSessions(List<User> sessions) async {
    try {
      final prefs = await _instance;
      final sessionsJson = sessions.map((user) => user.toJson()).toList();
      final result = await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
      print('Save sessions result: $result, count: ${sessions.length}');
      print('Sessions to save: ${sessions.map((s) => '${s.name}(${s.id})').join(', ')}');
    } catch (e) {
      print('Error saving sessions: $e');
      throw e;
    }
  }

  /// Load user sessions
  Future<List<User>> loadSessions() async {
    try {
      final prefs = await _instance;
      final sessionsString = prefs.getString(_sessionsKey);
      
      if (sessionsString == null) {
        print('No sessions found in storage');
        return [];
      }
      
      final sessionsJson = jsonDecode(sessionsString) as List<dynamic>;
      final sessions = sessionsJson.map((json) => User.fromJson(json)).toList();
      print('Loaded ${sessions.length} sessions from storage');
      print('Sessions loaded: ${sessions.map((s) => '${s.name}(${s.id})').join(', ')}');
      return sessions;
    } catch (e) {
      print('Error loading sessions: $e');
      return [];
    }
  }

  /// Add user to sessions
  Future<void> addSession(User user) async {
    try {
      final sessions = await loadSessions();
      // Remove existing session with same name if exists
      sessions.removeWhere((session) => session.name == user.name);
      sessions.add(user);
      await saveSessions(sessions);
      print('Added session for user: ${user.name}');
    } catch (e) {
      print('Error adding session: $e');
      throw e;
    }
  }

  /// Remove session
  Future<void> removeSession(String userId) async {
    try {
      final sessions = await loadSessions();
      sessions.removeWhere((session) => session.id == userId);
      await saveSessions(sessions);
      print('Removed session for user ID: $userId');
    } catch (e) {
      print('Error removing session: $e');
      throw e;
    }
  }

  /// Clear all sessions
  Future<void> clearSessions() async {
    try {
      final prefs = await _instance;
      final result = await prefs.remove(_sessionsKey);
      print('Clear sessions result: $result');
    } catch (e) {
      print('Error clearing sessions: $e');
      throw e;
    }
  }

  /// Get all stored data for debugging
  Future<Map<String, dynamic>> getAllStoredData() async {
    try {
      final prefs = await _instance;
      final keys = prefs.getKeys();
      final data = <String, dynamic>{};
      
      for (final key in keys) {
        final value = prefs.get(key);
        data[key] = value;
      }
      
      print('All stored data: $data');
      return data;
    } catch (e) {
      print('Error getting debug data: $e');
      return {};
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final prefs = await _instance;
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_loginDataKey);
      print('User logged out');
    } catch (e) {
      print('Error during logout: $e');
      throw e;
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      final prefs = await _instance;
      final result = await prefs.clear();
      print('Clear all data result: $result');
    } catch (e) {
      print('Error clearing all data: $e');
      throw e;
    }
  }
} 