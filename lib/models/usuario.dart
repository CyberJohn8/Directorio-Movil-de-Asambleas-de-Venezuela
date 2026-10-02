class Usuario {
  final int id;
  final String username;
  final String email;
  final String rol;
  final String? resetToken;
  final int? tokenExpira;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.rol,
    this.resetToken,
    this.tokenExpira,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
      resetToken: json['reset_token'],
      tokenExpira: json['token_expira'] is int ? json['token_expira'] : (json['token_expira'] != null ? int.tryParse(json['token_expira'].toString()) : null),
    );
  }

  // Para SQLite (Map local)
  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario.fromJson(map);
}
