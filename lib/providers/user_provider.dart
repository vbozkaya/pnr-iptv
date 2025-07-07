import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/iptv_service.dart';
import '../models/playlist.dart';
import '../providers/iptv_provider.dart';
import 'dart:math';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  List<User> _sessions = [];
  User? _activeUser;
  Playlist? _playlist;
  bool _isLoading = false;
  String? _error;
  IptvProvider? _iptvProvider;

  List<User> get users => _users;
  List<User> get sessions => _sessions;
  User? get activeUser => _activeUser;
  Playlist? get playlist => _playlist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider();

  Future<void> initializeWithIptvProvider(IptvProvider iptvProvider) async {
    _iptvProvider = iptvProvider;
    await StorageService.init();
    await loadUsers();
    await loadSessions();
    await loadActiveUserFromStorage();
  }

  Future<void> loadUsers() async {
    try {
      _users = await StorageService().loadUsers();
      notifyListeners();
    } catch (e) {
      _users = [];
      notifyListeners();
    }
  }

  Future<void> loadSessions() async {
    try {
      _sessions = await StorageService().loadSessions();
      notifyListeners();
    } catch (e) {
      _sessions = [];
      notifyListeners();
    }
  }

  // Aktif kullanıcı ve playlist'i storage'dan yükle
  Future<void> loadActiveUserFromStorage() async {
    try {
      _activeUser = await StorageService().loadActiveUser();
      if (_activeUser != null) {
        final playlist = await IptvService.fetchPlaylist(_activeUser!.m3uUrl);
        _playlist = playlist;
        if (_iptvProvider != null) {
          await _iptvProvider!.loadPlaylist(playlist);
        }
      }
      notifyListeners();
    } catch (e) {
      // Silent error
    }
  }

  Future<void> addUser(String name, String m3uUrl) async {
    try {
      final user = User(
        id: UniqueKey().toString() + Random().nextInt(99999).toString(),
        name: name,
        m3uUrl: m3uUrl,
      );
      _users.add(user);
      await StorageService().saveUsers(_users);
      await StorageService().addSession(user);
      await StorageService().saveActiveUser(user); // Yeni kullanıcıyı aktif yap
      _activeUser = user;
      final playlist = await IptvService.fetchPlaylist(user.m3uUrl);
      _playlist = playlist;
      if (_iptvProvider != null) {
        await _iptvProvider!.loadPlaylist(playlist);
      }
      await loadSessions();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> selectUser(User user, {IptvProvider? iptvProvider}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final playlist = await IptvService.fetchPlaylist(user.m3uUrl);
      _playlist = playlist;
      _activeUser = user;
      await StorageService().saveActiveUser(user); // Aktif kullanıcıyı kaydet
      if (iptvProvider != null) {
        await iptvProvider.loadPlaylist(playlist);
      } else if (_iptvProvider != null) {
        await _iptvProvider!.loadPlaylist(playlist);
      }
      if (!_sessions.any((session) => session.id == user.id)) {
        await StorageService().addSession(user);
        await loadSessions();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadActiveUserPlaylist({IptvProvider? iptvProvider}) async {
    try {
      if (_activeUser != null) {
        final playlist = await IptvService.fetchPlaylist(_activeUser!.m3uUrl);
        _playlist = playlist;
        if (iptvProvider != null) {
          await iptvProvider.loadPlaylist(playlist);
        } else if (_iptvProvider != null) {
          await _iptvProvider!.loadPlaylist(playlist);
        }
        notifyListeners();
      }
    } catch (e) {
      // Silent error handling for better UX
    }
  }

  Future<void> logout() async {
    try {
      _activeUser = null;
      _playlist = null;
      await StorageService().saveActiveUser(null);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeUser(String id) async {
    try {
      _users.removeWhere((user) => user.id == id);
      await StorageService().saveUsers(_users);
      await StorageService().removeSession(id);
      await loadSessions();
      if (_activeUser?.id == id) {
        _activeUser = null;
        _playlist = null;
        await StorageService().saveActiveUser(null);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateUser(String id, String newName, String newM3uUrl) async {
    try {
      final userIndex = _users.indexWhere((user) => user.id == id);
      if (userIndex != -1) {
        final updatedUser = User(
          id: id,
          name: newName,
          m3uUrl: newM3uUrl,
        );
        _users[userIndex] = updatedUser;
        await StorageService().saveUsers(_users);
        if (_activeUser?.id == id) {
          _activeUser = updatedUser;
          await StorageService().saveActiveUser(updatedUser);
        }
        final sessionIndex = _sessions.indexWhere((session) => session.id == id);
        if (sessionIndex != -1) {
          _sessions[sessionIndex] = updatedUser;
          await StorageService().saveSessions(_sessions);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearAllSessions() async {
    try {
      _sessions.clear();
      await StorageService().clearSessions();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> debugStorage() async {
    try {
      final allData = await StorageService().getAllStoredData();
    } catch (e) {}
  }

  Future<void> refreshAllData() async {
    await loadUsers();
    await loadSessions();
  }
} 