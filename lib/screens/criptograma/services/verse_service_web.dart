// lib/screens/criptograma/services/verse_service_web.dart
import 'package:flutter/foundation.dart';

class VerseServiceWeb {
  // Lista de versículos de ejemplo para demostración
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
    {
      'book_name': 'Filipenses',
      'chapter': 4,
      'verse_num': 13,
      'text': 'Todo lo puedo en Cristo que me fortalece.'
    },
    {
      'book_name': 'Jeremías',
      'chapter': 29,
      'verse_num': 11,
      'text': 'Porque yo sé los pensamientos que tengo acerca de vosotros, dice Jehová, pensamientos de paz, y no de mal, para daros el fin que esperáis.'
    },
    {
      'book_name': 'Romanos',
      'chapter': 8,
      'verse_num': 28,
      'text': 'Y sabemos que a los que aman a Dios, todas las cosas les ayudan a bien, esto es, a los que conforme a su propósito son llamados.'
    },
    {
      'book_name': 'Proverbios',
      'chapter': 3,
      'verse_num': 5,
      'text': 'Fíate de Jehová de todo tu corazón, Y no te apoyes en tu propia prudencia.'
    },
    {
      'book_name': 'Mateo',
      'chapter': 11,
      'verse_num': 28,
      'text': 'Venid a mí todos los que estáis trabajados y cargados, y yo os haré descansar.'
    },
    {
      'book_name': 'Isaías',
      'chapter': 40,
      'verse_num': 31,
      'text': 'Pero los que esperan a Jehová tendrán nuevas fuerzas; levantarán alas como las águilas; correrán, y no se cansarán; caminarán, y no se fatigarán.'
    },
    {
      'book_name': 'Efesios',
      'chapter': 2,
      'verse_num': 8,
      'text': 'Porque por gracia sois salvos por medio de la fe; y esto no de vosotros, pues es don de Dios.'
    },
    {
      'book_name': 'Josué',
      'chapter': 1,
      'verse_num': 9,
      'text': 'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes, porque Jehová tu Dios estará contigo dondequiera que vayas.'
    }
  ];

  Future<Map<String, dynamic>?> getRandomVerse() async {
    try {
      // Simular una pequeña demora
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Obtener un versículo aleatorio
      final randomIndex = DateTime.now().millisecondsSinceEpoch % _verses.length;
      return _verses[randomIndex];
    } catch (e) {
      debugPrint('Error al obtener versículo: $e');
      return null;
    }
  }
}