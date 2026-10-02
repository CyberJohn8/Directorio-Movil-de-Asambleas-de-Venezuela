// lib/services/local_db_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
// ELIMINADO: import 'package:hive/hive.dart';  // ← No es necesario
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/iglesia.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../models/himno.dart';
import '../models/adapters/iglesia_adapter.dart';
import '../models/adapters/himno_adapter.dart';
import '../models/adapters/book_adapter.dart';
import '../models/adapters/verse_adapter.dart';

class LocalDbService {
  static const String iglesiasBox = 'iglesias';
  static const String booksBox = 'books';
  static const String versesBox = 'verses';
  static const String himnosBox = 'himnos';

  static Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    }
    
    // Registrar adaptadores ANTES de abrir las cajas
    Hive.registerAdapter(IglesiaAdapter());
    Hive.registerAdapter(HimnoAdapter());
    Hive.registerAdapter(BookAdapter());
    Hive.registerAdapter(VerseAdapter());
    
    // Abrir cajas
    await Hive.openBox<Iglesia>(iglesiasBox);
    await Hive.openBox<Book>(booksBox);
    // Para versículos, usamos un box de tipo dynamic para guardar listas
    await Hive.openBox<dynamic>(versesBox);
    await Hive.openBox<Himno>(himnosBox);
  }

  // ========== IGLESIAS ==========
  static Future<void> saveIglesias(List<Iglesia> iglesias) async {
    final box = Hive.box<Iglesia>(iglesiasBox);
    await box.clear();
    for (var iglesia in iglesias) {
      await box.put(iglesia.id, iglesia);
    }
  }

  static List<Iglesia> getIglesias() {
    final box = Hive.box<Iglesia>(iglesiasBox);
    return box.values.toList();
  }

  static Future<void> saveIglesia(Iglesia iglesia) async {
    final box = Hive.box<Iglesia>(iglesiasBox);
    await box.put(iglesia.id, iglesia);
  }

  // ========== LIBROS ==========
  static Future<void> saveBooks(List<Book> books) async {
    final box = Hive.box<Book>(booksBox);
    await box.clear();
    for (var book in books) {
      await box.put(book.id, book);
    }
  }

  static List<Book> getBooks() {
    final box = Hive.box<Book>(booksBox);
    return box.values.toList();
  }

  // ========== VERSÍCULOS ==========
  static Future<void> saveVerses(int bookId, int chapter, List<Verse> verses) async {
    final box = Hive.box<dynamic>(versesBox);
    final String key = '${bookId}_$chapter';
    await box.put(key, verses);
  }

  static List<Verse>? getVerses(int bookId, int chapter) {
    final box = Hive.box<dynamic>(versesBox);
    final String key = '${bookId}_$chapter';
    final dynamic data = box.get(key);
    if (data is List<Verse>) {
      return data;
    }
    return null;
  }

  // ========== HIMNOS ==========
  // CORREGIDO: Usar 'numero' en lugar de 'id'
  static Future<void> saveHimnos(List<Himno> himnos) async {
    final box = Hive.box<Himno>(himnosBox);
    await box.clear();
    for (var himno in himnos) {
      await box.put(himno.numero, himno);  // ← CORREGIDO: usar 'numero'
    }
  }

  static List<Himno> getHimnos() {
    final box = Hive.box<Himno>(himnosBox);
    return box.values.toList();
  }

  // ========== VERIFICAR SI HAY DATOS LOCALES ==========
  static bool hasLocalData() {
    return Hive.box<Iglesia>(iglesiasBox).isNotEmpty;
  }

  static bool hasLocalHimnos() {
    return Hive.box<Himno>(himnosBox).isNotEmpty;
  }

  static bool hasLocalBooks() {
    return Hive.box<Book>(booksBox).isNotEmpty;
  }

  static Future<void> clearAll() async {
    await Hive.box<Iglesia>(iglesiasBox).clear();
    await Hive.box<Book>(booksBox).clear();
    await Hive.box<dynamic>(versesBox).clear();
    await Hive.box<Himno>(himnosBox).clear();
  }
}