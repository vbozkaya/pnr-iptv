class User {
  final String id;
  final String name;
  final String m3uUrl;

  User({required this.id, required this.name, required this.m3uUrl});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        m3uUrl: json['m3uUrl'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'm3uUrl': m3uUrl,
      };
} 