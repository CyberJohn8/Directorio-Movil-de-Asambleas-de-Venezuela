// lib/models/versiculo_guardado.dart
import 'package:flutter/foundation.dart';

class NotaVersiculo {
  final String id;
  String texto;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  NotaVersiculo({
    required this.id,
    required this.texto,
    required this.fechaCreacion,
    required this.fechaModificacion,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'texto': texto,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaModificacion': fechaModificacion.toIso8601String(),
      };

  factory NotaVersiculo.fromJson(Map<String, dynamic> json) => NotaVersiculo(
        id: json['id'] ?? '',
        texto: json['texto'] ?? '',
        fechaCreacion:
            DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime.now(),
        fechaModificacion:
            DateTime.tryParse(json['fechaModificacion'] ?? '') ?? DateTime.now(),
      );
}

class VersiculoGuardado {
  final String id;
  final String libro;
  final int capitulo;
  final int versiculo;
  final String texto;
  final DateTime fechaGuardado;
  final String idioma; // 👈 NUEVO CAMPO
  List<NotaVersiculo> notas;

  VersiculoGuardado({
    required this.id,
    required this.libro,
    required this.capitulo,
    required this.versiculo,
    required this.texto,
    required this.fechaGuardado,
    this.idioma = 'es', // 👈 VALOR POR DEFECTO
    List<NotaVersiculo>? notas,
  }) : notas = notas ?? [];

  String get cita => '$libro $capitulo:$versiculo';

  int get notasCount => notas.length;

  // Helper para saber si es inglés
  bool get esIngles => idioma == 'en';

  Map<String, dynamic> toJson() => {
        'id': id,
        'libro': libro,
        'capitulo': capitulo,
        'versiculo': versiculo,
        'texto': texto,
        'fechaGuardado': fechaGuardado.toIso8601String(),
        'idioma': idioma, // 👈 GUARDAR IDIOMA
        'notas': notas.map((n) => n.toJson()).toList(),
      };

  factory VersiculoGuardado.fromJson(Map<String, dynamic> json) =>
      VersiculoGuardado(
        id: json['id'] ?? '',
        libro: json['libro'] ?? '',
        capitulo: json['capitulo'] ?? 0,
        versiculo: json['versiculo'] ?? 0,
        texto: json['texto'] ?? '',
        fechaGuardado:
            DateTime.tryParse(json['fechaGuardado'] ?? '') ?? DateTime.now(),
        idioma: json['idioma'] ?? 'es', // 👈 LEER IDIOMA (compatibilidad con datos antiguos)
        notas: (json['notas'] as List<dynamic>?)
                ?.map((n) => NotaVersiculo.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersiculoGuardado &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VersiculoGuardado($cita)';
}