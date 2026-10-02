class Asamblea {
  int? id;
  String nombre;
  String ciudad;
  String estado;
  String pastor;
  String telefono;
  String horario;
  int miembros;
  String direccion;
  double? latitud;
  double? longitud;
  String? email;
  String? sitioWeb;
  String? horariosAdicionales;
  DateTime? fechaFundacion;

  Asamblea({
    this.id,
    required this.nombre,
    required this.ciudad,
    required this.estado,
    required this.pastor,
    required this.telefono,
    required this.horario,
    required this.miembros,
    required this.direccion,
    this.latitud,
    this.longitud,
    this.email,
    this.sitioWeb,
    this.horariosAdicionales,
    this.fechaFundacion,
  });

  // Convertir de JSON a objeto
  factory Asamblea.fromJson(Map<String, dynamic> json) {
    return Asamblea(
      id: json['id'],
      nombre: json['nombre'],
      ciudad: json['ciudad'],
      estado: json['estado'],
      pastor: json['pastor'],
      telefono: json['telefono'],
      horario: json['horario'],
      miembros: json['miembros'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      email: json['email'],
      sitioWeb: json['sitioWeb'],
      horariosAdicionales: json['horariosAdicionales'],
      fechaFundacion: json['fechaFundacion'] != null 
          ? DateTime.parse(json['fechaFundacion']) 
          : null,
    );
  }

  // Convertir de objeto a JSON para guardar en BD
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ciudad': ciudad,
      'estado': estado,
      'pastor': pastor,
      'telefono': telefono,
      'horario': horario,
      'miembros': miembros,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'email': email,
      'sitioWeb': sitioWeb,
      'horariosAdicionales': horariosAdicionales,
      'fechaFundacion': fechaFundacion?.toIso8601String(),
    };
  }

  // Para mostrar en logs o depuración
  @override
  String toString() {
    return 'Asamblea{id: $id, nombre: $nombre, ciudad: $ciudad, estado: $estado}';
  }
}