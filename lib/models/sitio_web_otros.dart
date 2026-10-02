class SitioWebOtros {
  final int id;
  final String titular;
  final String? descripcion;
  final String enlace;

  SitioWebOtros({
    required this.id,
    required this.titular,
    this.descripcion,
    required this.enlace,
  });

  factory SitioWebOtros.fromJson(Map<String, dynamic> json) {
    return SitioWebOtros(
      id: json['id'] ?? 0,
      titular: json['Titular'] ?? json['titular'] ?? 'Sin título',
      descripcion: json['Descripcion'] ?? json['descripcion'],
      enlace: json['Enlace'] ?? json['enlace'] ?? '',
    );
  }

  // 👈 AGREGAR ESTE MÉTODO
  factory SitioWebOtros.fromMap(Map<String, dynamic> map) {
    return SitioWebOtros(
      id: map['id'] ?? 0,
      titular: map['Titular'] ?? map['titular'] ?? 'Sin título',
      descripcion: map['Descripcion'] ?? map['descripcion'],
      enlace: map['Enlace'] ?? map['enlace'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Titular': titular,
      'Descripcion': descripcion,
      'Enlace': enlace,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Titular': titular,
      'Descripcion': descripcion,
      'Enlace': enlace,
    };
  }
}