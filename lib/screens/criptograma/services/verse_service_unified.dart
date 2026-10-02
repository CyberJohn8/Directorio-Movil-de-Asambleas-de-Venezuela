// lib/screens/criptograma/services/verse_service_unified.dart
import 'package:flutter/foundation.dart';
import 'verse_service_web.dart';

class VerseServiceUnified {
  late dynamic _service;

  VerseServiceUnified() {
    // Detectar si es Web o móvil
    if (kIsWeb) {
      _service = VerseServiceWeb();
    } else {
      // Para móvil, usar el servicio original con SQLite
      _service = VerseServiceMobile();
    }
  }

  Future<Map<String, dynamic>?> getRandomVerse() async {
    return await _service.getRandomVerse();
  }
}

// Versión para móvil (la que ya tenías, pero corregida)
class VerseServiceMobile {
  // Aquí iría tu implementación original con SQLite
  // Por ahora, usaremos los mismos datos de ejemplo
  static final List<Map<String, dynamic>> _verses = [
    {
      'book_name': 'Juan',
      'chapter': 3,
      'verse_num': 16,
      'text': 'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.'
    },
    {
      'book_name': 'Salmos',
      'chapter': 23,
      'verse_num': 1,
      'text': 'Jehová es mi pastor; nada me faltará.'
    },
    // Agrega más versículos aquí...
  ];

  Future<Map<String, dynamic>?> getRandomVerse() async {
    try {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % _verses.length;
      return _verses[randomIndex];
    } catch (e) {
      debugPrint('Error al obtener versículo: $e');
      return null;
    }
  }
}