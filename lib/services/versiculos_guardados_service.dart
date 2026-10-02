// lib/services/versiculos_guardados_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/versiculo_guardado.dart';
import 'package:flutter/foundation.dart';

class VersiculosGuardadosService {
  static const String _keyVersiculos = 'versiculos_guardados_v1';
  static const String _keyUltimasLecturas = 'ultimas_lecturas';

  // ✅ lowerCamelCase para eliminar el warning de Dart
  static const int maxUltimasLecturas = 5;

  // ========================================
  // VERSÍCULOS GUARDADOS (FAVORITOS)
  // ========================================

  static Future<List<VersiculoGuardado>> obtenerGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyVersiculos);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> lista = jsonDecode(data);
      return lista
          .map((json) =>
              VersiculoGuardado.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> guardarVersiculo(VersiculoGuardado versiculo) async {
    final lista = await obtenerGuardados();

    if (lista.any((v) => v.id == versiculo.id)) {
      return false;
    }

    lista.insert(0, versiculo);
    return await _persistir(lista);
  }

  static Future<bool> eliminarVersiculo(String id) async {
    final lista = await obtenerGuardados();
    lista.removeWhere((v) => v.id == id);
    return await _persistir(lista);
  }

  static Future<bool> estaGuardado(String id) async {
    final lista = await obtenerGuardados();
    return lista.any((v) => v.id == id);
  }

  static Future<bool> _persistir(List<VersiculoGuardado> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(lista.map((v) => v.toJson()).toList());
    return await prefs.setString(_keyVersiculos, data);
  }

  // ========================================
  // NOTAS DE UN VERSÍCULO
  // ========================================

  static Future<bool> agregarNota(String versiculoId, String texto) async {
    final lista = await obtenerGuardados();
    final index = lista.indexWhere((v) => v.id == versiculoId);
    if (index == -1) return false;

    if (lista[index].notas.length >= 3) {
      return false;
    }

    final nuevaNota = NotaVersiculo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      texto: texto,
      fechaCreacion: DateTime.now(),
      fechaModificacion: DateTime.now(),
    );

    lista[index].notas.add(nuevaNota);
    return await _persistir(lista);
  }

  static Future<bool> actualizarNota(
    String versiculoId,
    String notaId,
    String nuevoTexto,
  ) async {
    final lista = await obtenerGuardados();
    final vIndex = lista.indexWhere((v) => v.id == versiculoId);
    if (vIndex == -1) return false;

    final nIndex = lista[vIndex].notas.indexWhere((n) => n.id == notaId);
    if (nIndex == -1) return false;

    lista[vIndex].notas[nIndex].texto = nuevoTexto;
    lista[vIndex].notas[nIndex].fechaModificacion = DateTime.now();

    return await _persistir(lista);
  }

  static Future<bool> eliminarNota(String versiculoId, String notaId) async {
    final lista = await obtenerGuardados();
    final vIndex = lista.indexWhere((v) => v.id == versiculoId);
    if (vIndex == -1) return false;

    lista[vIndex].notas.removeWhere((n) => n.id == notaId);
    return await _persistir(lista);
  }

  // ========================================
  // ÚLTIMAS LECTURAS (HASTA 5)
  // ========================================

  /// Guarda/actualiza una última lectura (máximo 5).
  ///
  /// ✅ Si ya existe una entrada para el mismo libro + capítulo + idioma,
  /// la ACTUALIZA (versículo y fecha) y la mueve al inicio, en lugar de
  /// duplicarla.
  static Future<void> agregarUltimaLectura({
    required String libro,
    required int capitulo,
    required int versiculo,
    String idioma = 'es',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? lecturasJson =
          prefs.getStringList(_keyUltimasLecturas);
      List<Map<String, dynamic>> lecturas = [];

      if (lecturasJson != null) {
        lecturas = lecturasJson.map((json) {
          final raw = jsonDecode(json) as Map<String, dynamic>;
          // ✅ Normalizar al leer (por si hay datos viejos mal guardados)
          return <String, dynamic>{
            'libro': raw['libro']?.toString() ?? '',
            'capitulo': _toInt(raw['capitulo']),
            'versiculo': _toInt(raw['versiculo']),
            'idioma': raw['idioma']?.toString() ?? 'es',
            'fecha': raw['fecha']?.toString() ?? '',
          };
        }).toList();
      }

      // ✅ Buscar si YA existe una entrada para libro + capítulo + idioma
      final int existenteIndex = lecturas.indexWhere((l) =>
          l['libro'] == libro &&
          l['capitulo'] == capitulo &&
          (l['idioma'] ?? 'es') == idioma);

      // Eliminar la entrada existente para reinsertarla al inicio
      if (existenteIndex != -1) {
        lecturas.removeAt(existenteIndex);
      }

      // Insertar la nueva lectura al inicio
      lecturas.insert(0, {
        'libro': libro,
        'capitulo': capitulo,
        'versiculo': versiculo,
        'idioma': idioma,
        'fecha': DateTime.now().toIso8601String(),
      });

      // Mantener solo las últimas 5
      if (lecturas.length > maxUltimasLecturas) {
        lecturas = lecturas.sublist(0, maxUltimasLecturas);
      }

      final listaStrings = lecturas.map((l) => jsonEncode(l)).toList();
      await prefs.setStringList(_keyUltimasLecturas, listaStrings);

      if (kDebugMode) {
        debugPrint(
            '✅ Última lectura guardada: $libro $capitulo:$versiculo ($idioma)');
        debugPrint('📚 Total: ${lecturas.length}');
      }
    } catch (e) {
      debugPrint('❌ Error guardando última lectura: $e');
    }
  }

  /// Obtiene las últimas lecturas (máximo 5), con tipos normalizados.
  ///
  /// ✅ Los valores se devuelven SIEMPRE como `int` y `String` para que
  /// la UI no falle al hacer `as int?` o `as String?` (bug clásico de
  /// `jsonDecode` que a veces devuelve `double` en lugar de `int`).
  static Future<List<Map<String, dynamic>>> obtenerUltimasLecturas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? lecturasJson =
          prefs.getStringList(_keyUltimasLecturas);

      if (lecturasJson == null || lecturasJson.isEmpty) {
        if (kDebugMode) {
          debugPrint('📚 No hay últimas lecturas guardadas');
        }
        return [];
      }

      final lecturas = lecturasJson.map((json) {
        final raw = jsonDecode(json) as Map<String, dynamic>;
        return <String, dynamic>{
          'libro': raw['libro']?.toString() ?? '',
          'capitulo': _toInt(raw['capitulo']),
          'versiculo': _toInt(raw['versiculo']),
          'idioma': raw['idioma']?.toString() ?? 'es',
          'fecha': raw['fecha']?.toString() ?? '',
        };
      }).toList();

      if (kDebugMode) {
        debugPrint('📚 Últimas lecturas cargadas: ${lecturas.length}');
        for (var l in lecturas) {
          debugPrint(
              '  → ${l['libro']} ${l['capitulo']}:${l['versiculo']} (${l['idioma']})');
        }
      }

      return lecturas;
    } catch (e) {
      debugPrint('❌ Error cargando últimas lecturas: $e');
      return [];
    }
  }

  /// Limpia el historial de últimas lecturas
  static Future<void> limpiarUltimasLecturas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUltimasLecturas);
  }

  // ========================================
  // HELPERS INTERNOS
  // ========================================

  /// ✅ Convierte cualquier valor a `int` de forma segura.
  /// Cubre los casos: int, double, String numérica, null.
  static int _toInt(dynamic value, {int fallback = 1}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}