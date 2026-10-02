class Mensaje {
  final int id;
  final String? sala;
  final String? nombre;
  final String? mensaje;
  final String? fecha;

  Mensaje({
    required this.id,
    this.sala,
    this.nombre,
    this.mensaje,
    this.fecha,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      sala: json['sala'],
      nombre: json['nombre'],
      mensaje: json['mensaje'],
      fecha: json['fecha'],
    );
  }

  // Para SQLite (Map local)
  factory Mensaje.fromMap(Map<String, dynamic> map) => Mensaje.fromJson(map);
}
