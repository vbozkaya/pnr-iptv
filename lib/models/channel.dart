class Channel {
  final String id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? category;
  final String? description;
  final bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.category,
    this.description,
    this.isFavorite = false,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      streamUrl: json['stream_url'] ?? '',
      logoUrl: json['logo_url'],
      category: json['category'],
      description: json['description'],
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'logo_url': logoUrl,
      'category': category,
      'description': description,
      'is_favorite': isFavorite,
    };
  }

  Channel copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? logoUrl,
    String? category,
    String? description,
    bool? isFavorite,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Channel(id: $id, name: $name, streamUrl: $streamUrl)';
  }
} 