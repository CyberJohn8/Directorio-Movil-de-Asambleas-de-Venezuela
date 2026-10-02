import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VerseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'biblia.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Aquí irían las tablas de books y verses
        db.execute('''
          CREATE TABLE books(
            id INTEGER PRIMARY KEY,
            name TEXT,
            modern_name TEXT,
            new_testament INTEGER
          )
        ''');
        
        db.execute('''
          CREATE TABLE verses(
            book_id INTEGER,
            chapter INTEGER,
            verse INTEGER,
            text TEXT
          )
        ''');
      },
    );
  }

  Future<Map<String, dynamic>?> getRandomVerse() async {
    final db = await database;
    
    try {
      // Contar versículos totales
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM verses')
      ) ?? 0;
      
      if (count == 0) return null;
      
      // Obtener un versículo aleatorio
      final randomOffset = (count * (DateTime.now().millisecondsSinceEpoch % count / count)).floor();
      
      final List<Map<String, dynamic>> verses = await db.query(
        'verses',
        limit: 1,
        offset: randomOffset,
      );
      
      if (verses.isEmpty) return null;
      
      final verse = verses.first;
      
      // Obtener la información del libro
      final List<Map<String, dynamic>> books = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [verse['book_id']],
      );
      
      if (books.isEmpty) return null;
      
      final book = books.first;
      
      return {
        'book_name': book['name'],
        'chapter': verse['chapter'],
        'verse_num': verse['verse'],
        'text': verse['text'],
      };
    } catch (e) {
      debugPrint('Error al obtener versículo: $e');
      return null;
    }
  }
}