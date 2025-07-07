import 'channel.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? url;
  final List<Channel> channels;
  final DateTime? lastUpdated;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.url,
    required this.channels,
    this.lastUpdated,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      url: json['url'],
      channels: (json['channels'] as List<dynamic>?)
              ?.map((channelJson) => Channel.fromJson(channelJson))
              .toList() ??
          [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'channels': channels.map((channel) => channel.toJson()).toList(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    List<Channel>? channels,
    DateTime? lastUpdated,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      channels: channels ?? this.channels,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Playlist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, channels: ${channels.length})';
  }
} 