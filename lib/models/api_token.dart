class ApiToken {
  final int id;
  final String name;
  final String token;
  final String createdAt;
  final String? lastUsed;
  final bool revoked;

  ApiToken({
    required this.id,
    required this.name,
    required this.token,
    required this.createdAt,
    this.lastUsed,
    required this.revoked,
  });

  factory ApiToken.fromJson(Map<String, dynamic> json) {
    return ApiToken(
      id: json['id'] as int,
      name: json['name'] as String,
      token: json['token'] as String,
      createdAt: json['created_at'] as String,
      lastUsed: json['last_used'] as String?,
      revoked: json['revoked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'token': token,
      'created_at': createdAt,
      if (lastUsed != null) 'last_used': lastUsed,
      'revoked': revoked,
    };
  }
}
