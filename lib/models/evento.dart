class Evento {
  final int id;
  final String detalles;
  final String ubicacion;
  final String fechaPublicacion;
  final int? usuarioId;

  Evento({
    required this.id,
    required this.detalles,
    required this.ubicacion,
    required this.fechaPublicacion,
    this.usuarioId,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      detalles: json['detalles'] ?? '',
      ubicacion: json['ubicacion'] ?? '',
      fechaPublicacion: json['fecha_publicacion'] ?? '',
      usuarioId: json['usuario_id'] is int ? json['usuario_id'] : (json['usuario_id'] != null ? int.tryParse(json['usuario_id'].toString()) : null),
    );
  }
}
