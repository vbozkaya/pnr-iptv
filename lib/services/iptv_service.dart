import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/playlist.dart';

class IptvService {
  static const String _favoritesKey = 'favorites';

  /// Fetch playlist from URL and return Playlist object
  static Future<Playlist> fetchPlaylist(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final iptvService = IptvService();
        final playlist = iptvService._parseM3uContent(content, url);
        return playlist;
      } else {
        throw Exception('Failed to load playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading playlist: $e');
    }
  }

  /// Parse M3U playlist from URL
  Future<List<Channel>> parsePlaylistFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final playlist = _parseM3uContent(content, url);
        return playlist.channels;
      } else {
        throw Exception('Failed to load playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading playlist: $e');
    }
  }

  /// Parse M3U playlist from file
  Future<List<Channel>> parsePlaylistFromFile(String filePath) async {
    try {
      // This would need file reading implementation
      // For now, we'll throw an exception
      throw Exception('File parsing not implemented yet');
    } catch (e) {
      throw Exception('Error loading playlist from file: $e');
    }
  }

  /// Parse M3U content string
  Playlist _parseM3uContent(String content, String url) {
    final lines = content.split('\n');
    final channels = <Channel>[];
    String? currentName;
    String? currentLogo;
    String? currentGroup;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('#EXTINF:')) {
        // Parse channel info
        final info = _parseExtinf(line);
        currentName = info['name'];
        currentLogo = info['logo'];
        currentGroup = info['group'];
      } else if (line.isNotEmpty && !line.startsWith('#') && currentName != null) {
        // This is a stream URL - validate it
        if (line.isNotEmpty) {
          final channel = Channel(
            id: _generateChannelId(currentName, line),
            name: currentName,
            streamUrl: line,
            logoUrl: currentLogo,
            category: currentGroup,
          );
          channels.add(channel);
        }
        
        // Reset for next channel
        currentName = null;
        currentLogo = null;
        currentGroup = null;
      }
    }

    return Playlist(
      id: _generatePlaylistId(url),
      name: 'Playlist',
      url: url,
      channels: channels,
      lastUpdated: DateTime.now(),
    );
  }

  /// Parse EXTINF line to extract channel information
  Map<String, String?> _parseExtinf(String line) {
    final result = <String, String?>{};
    
    // Extract name - try multiple patterns
    String? name;
    
    // Pattern 1: tvg-name attribute
    final nameMatch = RegExp(r'tvg-name="([^"]*)"').firstMatch(line);
    if (nameMatch != null) {
      name = nameMatch.group(1);
    }
    
    // Pattern 2: name after the last comma (fallback)
    if (name == null || name.isEmpty) {
      final commaIndex = line.lastIndexOf(',');
      if (commaIndex != -1) {
        name = line.substring(commaIndex + 1).trim();
      }
    }
    
    // Pattern 3: extract from quotes if no comma
    if (name == null || name.isEmpty) {
      final quoteMatch = RegExp(r'"([^"]*)"').firstMatch(line);
      if (quoteMatch != null) {
        name = quoteMatch.group(1);
      }
    }
    
    result['name'] = name ?? 'Unknown Channel';

    // Extract logo
    final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
    result['logo'] = logoMatch?.group(1);

    // Extract group
    final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
    result['group'] = groupMatch?.group(1);

    return result;
  }

  /// Generate unique channel ID
  String _generateChannelId(String name, String url) {
    return '${name.hashCode}_${url.hashCode}';
  }

  /// Generate unique playlist ID
  String _generatePlaylistId(String url) {
    return url.hashCode.toString();
  }

  /// Get channels by category
  List<Channel> getChannelsByCategory(List<Channel> channels, String category) {
    return channels.where((channel) => channel.category == category).toList();
  }

  /// Get all unique categories from channels
  List<String> getCategories(List<Channel> channels) {
    final categories = channels
        .where((channel) => channel.category != null)
        .map((channel) => channel.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Search channels by name
  List<Channel> searchChannels(List<Channel> channels, String query) {
    if (query.isEmpty) return channels;
    
    return channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Check if stream URL is valid
  bool _isValidStreamUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
} 