class Institucion {
  final int id;
  final String institucion;
  final String? detalles;
  final String tipoInstitucion;
  final String? direccion;
  final String? postal;
  final String? banco;
  final String? telefono;
  final String correo;
  final String? ciRif;
  final String? director;

  Institucion({
    required this.id,
    required this.institucion,
    this.detalles,
    required this.tipoInstitucion,
    this.direccion,
    this.postal,
    this.banco,
    this.telefono,
    required this.correo,
    this.ciRif,
    this.director,
  });

  factory Institucion.fromJson(Map<String, dynamic> json) {
    return Institucion(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      institucion: json['institucion'] ?? '',
      detalles: json['detalles'],
      tipoInstitucion: json['Tipo_Institucion'] ?? '',
      direccion: json['direccion'],
      postal: json['postal'],
      banco: json['banco'],
      telefono: json['telefono'],
      correo: json['Correo'] ?? '',
      ciRif: json['ci_rif'],
      director: json['director'],
    );
  }

  // Para SQLite (Map local)
  factory Institucion.fromMap(Map<String, dynamic> map) => Institucion.fromJson(map);
}
