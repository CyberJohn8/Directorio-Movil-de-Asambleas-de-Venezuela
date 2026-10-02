class Iglesia {
  final int id;
  final String asamblea;
  final String numero;
  final String estado;
  final String ciudad;
  final String? direccion;
  final String? telefono;
  final String? email;
  final double? latitud;
  final double? longitud;

  Iglesia({
    required this.id,
    required this.asamblea,
    required this.numero,
    required this.estado,
    required this.ciudad,
    this.direccion,
    this.telefono,
    this.email,
    this.latitud,
    this.longitud,
  });

  // Para JSON (servidor)
  factory Iglesia.fromJson(Map<String, dynamic> json) {
    return Iglesia(
      id: json['id'] ?? 0,
      asamblea: json['asamblea'] ?? '',
      numero: json['numero'] ?? '',
      estado: json['estado'] ?? '',
      ciudad: json['ciudad'] ?? '',
      direccion: json['direccion'],
      telefono: json['telefono'],
      email: json['email'],
      latitud: json['latitud'] != null ? double.tryParse(json['latitud'].toString()) : null,
      longitud: json['longitud'] != null ? double.tryParse(json['longitud'].toString()) : null,
    );
  }

  // Para SQLite (local)
  factory Iglesia.fromMap(Map<String, dynamic> map) {
    return Iglesia(
      id: map['id'] ?? 0,
      asamblea: map['asamblea'] ?? '',
      numero: map['numero'] ?? '',
      estado: map['estado'] ?? '',
      ciudad: map['ciudad'] ?? '',
      direccion: map['direccion'],
      telefono: map['telefono'],
      email: map['email'],
      latitud: map['latitud'] != null ? double.tryParse(map['latitud'].toString()) : null,
      longitud: map['longitud'] != null ? double.tryParse(map['longitud'].toString()) : null,
    );
  }

  // Para convertir a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asamblea': asamblea,
      'numero': numero,
      'estado': estado,
      'ciudad': ciudad,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'latitud': latitud,
      'longitud': longitud,
    };
  }
}