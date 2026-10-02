// lib/models/himno.dart
class Himno {
  final int numero;
  final String primeraLinea;
  final String letra;
  final String? versiculos;
  final String? tema;
  final String? subtema;
  final String? subSubtema;
  final String? reunion;

  Himno({
    required this.numero,
    required this.primeraLinea,
    required this.letra,
    this.versiculos,
    this.tema,
    this.subtema,
    this.subSubtema,
    this.reunion,
  });

  factory Himno.fromMap(Map<String, dynamic> map) {
    return Himno(
      numero: map['Numero'] as int? ?? 0,
      primeraLinea: map['Primera_linea'] as String? ?? '',
      letra: map['Letra'] as String? ?? '',
      versiculos: map['Versiculos'] as String?,
      tema: map['Tema'] as String?,
      subtema: map['Subtema'] as String?,
      subSubtema: map['Sub_subtema'] as String?,
      reunion: map['Reunion'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Numero': numero,
      'Primera_linea': primeraLinea,
      'Letra': letra,
      'Versiculos': versiculos,
      'Tema': tema,
      'Subtema': subtema,
      'Sub_subtema': subSubtema,
      'Reunion': reunion,
    };
  }

  factory Himno.fromJson(Map<String, dynamic> json) {
    return Himno(
      numero: json['Numero'] as int? ?? 0,
      primeraLinea: json['Primera_linea'] as String? ?? '',
      letra: json['Letra'] as String? ?? '',
      versiculos: json['Versiculos'] as String?,
      tema: json['Tema'] as String?,
      subtema: json['Subtema'] as String?,
      subSubtema: json['Sub_subtema'] as String?,
      reunion: json['Reunion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Numero': numero,
      'Primera_linea': primeraLinea,
      'Letra': letra,
      'Versiculos': versiculos,
      'Tema': tema,
      'Subtema': subtema,
      'Sub_subtema': subSubtema,
      'Reunion': reunion,
    };
  }
}