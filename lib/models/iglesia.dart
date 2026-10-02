// lib/models/iglesia.dart
class Iglesia {
  final int id;
  final String asamblea;
  final String numero;
  final String ciudad;
  final String estado;
  final String direccion;
  final String? domingo;
  final String? lunes;
  final String? martes;
  final String? miercoles;
  final String? jueves;
  final String? viernes;
  final String? sabado;
  final String? obras;
  final String googleMaps;
  final String? coordenadas;
  final String fechaFundacion; // ← Nuevo campo

  Iglesia({
    required this.id,
    required this.asamblea,
    required this.numero,
    required this.ciudad,
    required this.estado,
    required this.direccion,
    this.domingo,
    this.lunes,
    this.martes,
    this.miercoles,
    this.jueves,
    this.viernes,
    this.sabado,
    this.obras,
    required this.googleMaps,
    this.coordenadas,
    required this.fechaFundacion,
  });

  factory Iglesia.fromMap(Map<String, dynamic> map) {
    return Iglesia(
      id: map['id'] as int,
      asamblea: map['asamblea'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      ciudad: map['ciudad'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      domingo: map['domingo'] as String?,
      lunes: map['lunes'] as String?,
      martes: map['martes'] as String?,
      miercoles: map['miercoles'] as String?,
      jueves: map['jueves'] as String?,
      viernes: map['viernes'] as String?,
      sabado: map['sabado'] as String?,
      obras: map['obras'] as String?,
      googleMaps: map['GoogleMaps'] as String? ?? '',
      coordenadas: map['coordenadas'] as String?,
      fechaFundacion: map['Fehca_Fundacion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asamblea': asamblea,
      'numero': numero,
      'ciudad': ciudad,
      'estado': estado,
      'direccion': direccion,
      'domingo': domingo,
      'lunes': lunes,
      'martes': martes,
      'miercoles': miercoles,
      'jueves': jueves,
      'viernes': viernes,
      'sabado': sabado,
      'obras': obras,
      'GoogleMaps': googleMaps,
      'coordenadas': coordenadas,
      'Fehca_Fundacion': fechaFundacion,
    };
  }

  factory Iglesia.fromJson(Map<String, dynamic> json) {
    return Iglesia(
      id: json['id'] as int? ?? 0,
      asamblea: json['asamblea'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      ciudad: json['ciudad'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      domingo: json['domingo'] as String?,
      lunes: json['lunes'] as String?,
      martes: json['martes'] as String?,
      miercoles: json['miercoles'] as String?,
      jueves: json['jueves'] as String?,
      viernes: json['viernes'] as String?,
      sabado: json['sabado'] as String?,
      obras: json['obras'] as String?,
      googleMaps: json['GoogleMaps'] as String? ?? '',
      coordenadas: json['coordenadas'] as String?,
      fechaFundacion: json['Fehca_Fundacion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asamblea': asamblea,
      'numero': numero,
      'ciudad': ciudad,
      'estado': estado,
      'direccion': direccion,
      'domingo': domingo,
      'lunes': lunes,
      'martes': martes,
      'miercoles': miercoles,
      'jueves': jueves,
      'viernes': viernes,
      'sabado': sabado,
      'obras': obras,
      'GoogleMaps': googleMaps,
      'coordenadas': coordenadas,
      'Fehca_Fundacion': fechaFundacion,
    };
  }
}