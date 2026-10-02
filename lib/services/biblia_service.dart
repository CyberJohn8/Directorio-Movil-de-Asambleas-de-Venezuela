// lib/services/biblia_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/biblia.dart';

class BibliaService {
  // ============================================================
  // CONFIGURACIÓN DE IDIOMAS
  // ============================================================
  static const String _langEs = 'es';
  static const String _langEn = 'en';

  static String _currentLanguage = _langEs;

  // Rutas por idioma
  static const Map<String, String> _basePaths = {
    _langEs: 'assets/data/Biblia/dist/biblia/',
    _langEn: 'assets/data/Biblia_Ingles/',
  };

  // Formato por idioma
  static const Map<String, String> _formats = {
    _langEs: 'per_book',
    _langEn: 'single_file',
  };

  static const String _indexFile = 'index.json';
  static const String _singleFile = 'kjv.json';

  // Caches
  static List<BibliaBook>? _cachedBooks;
  static List<Map<String, dynamic>>? _cachedSingleFileVerses;

  // ============================================================
  // TABLA DE DATOS DE LIBROS (ESPAÑOL)
  // ============================================================
  // id: [key, título, shortTitle, abbr, categoría, testamento]
  static const Map<int, List<String>> _spanishBooksData = {
    1: ['genesis', 'Génesis', 'Génesis', 'Gn', 'Pentateuco', 'A.T.'],
    2: ['exodo', 'Éxodo', 'Éxodo', 'Ex', 'Pentateuco', 'A.T.'],
    3: ['levitico', 'Levítico', 'Levítico', 'Lv', 'Pentateuco', 'A.T.'],
    4: ['numeros', 'Números', 'Números', 'Nm', 'Pentateuco', 'A.T.'],
    5: ['deuteronomio', 'Deuteronomio', 'Deuteronomio', 'Dt', 'Pentateuco', 'A.T.'],
    6: ['josue', 'Josué', 'Josué', 'Jos', 'Históricos', 'A.T.'],
    7: ['jueces', 'Jueces', 'Jueces', 'Jue', 'Históricos', 'A.T.'],
    8: ['rut', 'Rut', 'Rut', 'Rt', 'Históricos', 'A.T.'],
    9: ['1_samuel', '1 Samuel', '1 Samuel', '1 S', 'Históricos', 'A.T.'],
    10: ['2_samuel', '2 Samuel', '2 Samuel', '2 S', 'Históricos', 'A.T.'],
    11: ['1_reyes', '1 Reyes', '1 Reyes', '1 R', 'Históricos', 'A.T.'],
    12: ['2_reyes', '2 Reyes', '2 Reyes', '2 R', 'Históricos', 'A.T.'],
    13: ['1_cronicas', '1 Crónicas', '1 Crónicas', '1 Cr', 'Históricos', 'A.T.'],
    14: ['2_cronicas', '2 Crónicas', '2 Crónicas', '2 Cr', 'Históricos', 'A.T.'],
    15: ['esdras', 'Esdras', 'Esdras', 'Esd', 'Históricos', 'A.T.'],
    16: ['nehemias', 'Nehemías', 'Nehemías', 'Neh', 'Históricos', 'A.T.'],
    17: ['ester', 'Ester', 'Ester', 'Est', 'Históricos', 'A.T.'],
    18: ['job', 'Job', 'Job', 'Job', 'Poéticos', 'A.T.'],
    19: ['salmos', 'Salmos', 'Salmos', 'Sal', 'Poéticos', 'A.T.'],
    20: ['proverbios', 'Proverbios', 'Proverbios', 'Pr', 'Poéticos', 'A.T.'],
    21: ['eclesiastes', 'Eclesiastés', 'Eclesiastés', 'Ec', 'Poéticos', 'A.T.'],
    22: ['cantares', 'Cantares', 'Cantares', 'Cnt', 'Poéticos', 'A.T.'],
    23: ['isaias', 'Isaías', 'Isaías', 'Is', 'Profetas Mayores', 'A.T.'],
    24: ['jeremias', 'Jeremías', 'Jeremías', 'Jer', 'Profetas Mayores', 'A.T.'],
    25: ['lamentaciones', 'Lamentaciones', 'Lamentaciones', 'Lm', 'Profetas Mayores', 'A.T.'],
    26: ['ezequiel', 'Ezequiel', 'Ezequiel', 'Ez', 'Profetas Mayores', 'A.T.'],
    27: ['daniel', 'Daniel', 'Daniel', 'Dn', 'Profetas Mayores', 'A.T.'],
    28: ['oseas', 'Oseas', 'Oseas', 'Os', 'Profetas Menores', 'A.T.'],
    29: ['joel', 'Joel', 'Joel', 'Jl', 'Profetas Menores', 'A.T.'],
    30: ['amos', 'Amós', 'Amós', 'Am', 'Profetas Menores', 'A.T.'],
    31: ['abdias', 'Abdías', 'Abdías', 'Abd', 'Profetas Menores', 'A.T.'],
    32: ['jonas', 'Jonás', 'Jonás', 'Jon', 'Profetas Menores', 'A.T.'],
    33: ['miqueas', 'Miqueas', 'Miqueas', 'Miq', 'Profetas Menores', 'A.T.'],
    34: ['nahum', 'Nahúm', 'Nahúm', 'Nah', 'Profetas Menores', 'A.T.'],
    35: ['habacuc', 'Habacuc', 'Habacuc', 'Hab', 'Profetas Menores', 'A.T.'],
    36: ['sofonias', 'Sofonías', 'Sofonías', 'Sof', 'Profetas Menores', 'A.T.'],
    37: ['hageo', 'Hageo', 'Hageo', 'Hag', 'Profetas Menores', 'A.T.'],
    38: ['zacarias', 'Zacarías', 'Zacarías', 'Zac', 'Profetas Menores', 'A.T.'],
    39: ['malaquias', 'Malaquías', 'Malaquías', 'Mal', 'Profetas Menores', 'A.T.'],
    40: ['mateo', 'Mateo', 'Mateo', 'Mt', 'Evangelios', 'N.T.'],
    41: ['marcos', 'Marcos', 'Marcos', 'Mr', 'Evangelios', 'N.T.'],
    42: ['lucas', 'Lucas', 'Lucas', 'Lc', 'Evangelios', 'N.T.'],
    43: ['juan', 'Juan', 'Juan', 'Jn', 'Evangelios', 'N.T.'],
    44: ['hechos', 'Hechos', 'Hechos', 'Hch', 'Historia', 'N.T.'],
    45: ['romanos', 'Romanos', 'Romanos', 'Ro', 'Cartas Paulinas', 'N.T.'],
    46: ['1_corintios', '1 Corintios', '1 Corintios', '1 Co', 'Cartas Paulinas', 'N.T.'],
    47: ['2_corintios', '2 Corintios', '2 Corintios', '2 Co', 'Cartas Paulinas', 'N.T.'],
    48: ['galatas', 'Gálatas', 'Gálatas', 'Gá', 'Cartas Paulinas', 'N.T.'],
    49: ['efesios', 'Efesios', 'Efesios', 'Ef', 'Cartas Paulinas', 'N.T.'],
    50: ['filipenses', 'Filipenses', 'Filipenses', 'Fil', 'Cartas Paulinas', 'N.T.'],
    51: ['colosenses', 'Colosenses', 'Colosenses', 'Col', 'Cartas Paulinas', 'N.T.'],
    52: ['1_tesalonicenses', '1 Tesalonicenses', '1 Tesalonicenses', '1 Ts', 'Cartas Paulinas', 'N.T.'],
    53: ['2_tesalonicenses', '2 Tesalonicenses', '2 Tesalonicenses', '2 Ts', 'Cartas Paulinas', 'N.T.'],
    54: ['1_timoteo', '1 Timoteo', '1 Timoteo', '1 Ti', 'Cartas Paulinas', 'N.T.'],
    55: ['2_timoteo', '2 Timoteo', '2 Timoteo', '2 Ti', 'Cartas Paulinas', 'N.T.'],
    56: ['tito', 'Tito', 'Tito', 'Tit', 'Cartas Paulinas', 'N.T.'],
    57: ['filemon', 'Filemón', 'Filemón', 'Flm', 'Cartas Paulinas', 'N.T.'],
    58: ['hebreos', 'Hebreos', 'Hebreos', 'He', 'Cartas Generales', 'N.T.'],
    59: ['santiago', 'Santiago', 'Santiago', 'Stg', 'Cartas Generales', 'N.T.'],
    60: ['1_pedro', '1 Pedro', '1 Pedro', '1 P', 'Cartas Generales', 'N.T.'],
    61: ['2_pedro', '2 Pedro', '2 Pedro', '2 P', 'Cartas Generales', 'N.T.'],
    62: ['1_juan', '1 Juan', '1 Juan', '1 Jn', 'Cartas Generales', 'N.T.'],
    63: ['2_juan', '2 Juan', '2 Juan', '2 Jn', 'Cartas Generales', 'N.T.'],
    64: ['3_juan', '3 Juan', '3 Juan', '3 Jn', 'Cartas Generales', 'N.T.'],
    65: ['judas', 'Judas', 'Judas', 'Jud', 'Cartas Generales', 'N.T.'],
    66: ['apocalipsis', 'Apocalipsis', 'Apocalipsis', 'Ap', 'Profético', 'N.T.'],
  };

  // ============================================================
  // TABLA DE DATOS DE LIBROS (INGLÉS)
  // ============================================================
  // id: [key, title, shortTitle, abbr, category, testament]
  static const Map<int, List<String>> _englishBooksData = {
    1: ['genesis', 'Genesis', 'Genesis', 'Gen', 'Pentateuch', 'A.T.'],
    2: ['exodus', 'Exodus', 'Exodus', 'Ex', 'Pentateuch', 'A.T.'],
    3: ['leviticus', 'Leviticus', 'Leviticus', 'Lev', 'Pentateuch', 'A.T.'],
    4: ['numbers', 'Numbers', 'Numbers', 'Num', 'Pentateuch', 'A.T.'],
    5: ['deuteronomy', 'Deuteronomy', 'Deuteronomy', 'Deut', 'Pentateuch', 'A.T.'],
    6: ['joshua', 'Joshua', 'Joshua', 'Josh', 'Historical', 'A.T.'],
    7: ['judges', 'Judges', 'Judges', 'Judg', 'Historical', 'A.T.'],
    8: ['ruth', 'Ruth', 'Ruth', 'Ruth', 'Historical', 'A.T.'],
    9: ['1_samuel', '1 Samuel', '1 Samuel', '1 Sam', 'Historical', 'A.T.'],
    10: ['2_samuel', '2 Samuel', '2 Samuel', '2 Sam', 'Historical', 'A.T.'],
    11: ['1_kings', '1 Kings', '1 Kings', '1 Kgs', 'Historical', 'A.T.'],
    12: ['2_kings', '2 Kings', '2 Kings', '2 Kgs', 'Historical', 'A.T.'],
    13: ['1_chronicles', '1 Chronicles', '1 Chronicles', '1 Chr', 'Historical', 'A.T.'],
    14: ['2_chronicles', '2 Chronicles', '2 Chronicles', '2 Chr', 'Historical', 'A.T.'],
    15: ['ezra', 'Ezra', 'Ezra', 'Ezra', 'Historical', 'A.T.'],
    16: ['nehemiah', 'Nehemiah', 'Nehemiah', 'Neh', 'Historical', 'A.T.'],
    17: ['esther', 'Esther', 'Esther', 'Esth', 'Historical', 'A.T.'],
    18: ['job', 'Job', 'Job', 'Job', 'Poetical', 'A.T.'],
    19: ['psalms', 'Psalms', 'Psalms', 'Ps', 'Poetical', 'A.T.'],
    20: ['proverbs', 'Proverbs', 'Proverbs', 'Prov', 'Poetical', 'A.T.'],
    21: ['ecclesiastes', 'Ecclesiastes', 'Ecclesiastes', 'Eccl', 'Poetical', 'A.T.'],
    22: ['song_of_solomon', 'Song of Solomon', 'Song', 'Song', 'Poetical', 'A.T.'],
    23: ['isaiah', 'Isaiah', 'Isaiah', 'Isa', 'Major Prophets', 'A.T.'],
    24: ['jeremiah', 'Jeremiah', 'Jeremiah', 'Jer', 'Major Prophets', 'A.T.'],
    25: ['lamentations', 'Lamentations', 'Lamentations', 'Lam', 'Major Prophets', 'A.T.'],
    26: ['ezekiel', 'Ezekiel', 'Ezekiel', 'Ezek', 'Major Prophets', 'A.T.'],
    27: ['daniel', 'Daniel', 'Daniel', 'Dan', 'Major Prophets', 'A.T.'],
    28: ['hosea', 'Hosea', 'Hosea', 'Hos', 'Minor Prophets', 'A.T.'],
    29: ['joel', 'Joel', 'Joel', 'Joel', 'Minor Prophets', 'A.T.'],
    30: ['amos', 'Amos', 'Amos', 'Amos', 'Minor Prophets', 'A.T.'],
    31: ['obadiah', 'Obadiah', 'Obadiah', 'Obad', 'Minor Prophets', 'A.T.'],
    32: ['jonah', 'Jonah', 'Jonah', 'Jonah', 'Minor Prophets', 'A.T.'],
    33: ['micah', 'Micah', 'Micah', 'Mic', 'Minor Prophets', 'A.T.'],
    34: ['nahum', 'Nahum', 'Nahum', 'Nah', 'Minor Prophets', 'A.T.'],
    35: ['habakkuk', 'Habakkuk', 'Habakkuk', 'Hab', 'Minor Prophets', 'A.T.'],
    36: ['zephaniah', 'Zephaniah', 'Zephaniah', 'Zeph', 'Minor Prophets', 'A.T.'],
    37: ['haggai', 'Haggai', 'Haggai', 'Hag', 'Minor Prophets', 'A.T.'],
    38: ['zechariah', 'Zechariah', 'Zechariah', 'Zech', 'Minor Prophets', 'A.T.'],
    39: ['malachi', 'Malachi', 'Malachi', 'Mal', 'Minor Prophets', 'A.T.'],
    40: ['matthew', 'Matthew', 'Matthew', 'Matt', 'Gospels', 'N.T.'],
    41: ['mark', 'Mark', 'Mark', 'Mark', 'Gospels', 'N.T.'],
    42: ['luke', 'Luke', 'Luke', 'Luke', 'Gospels', 'N.T.'],
    43: ['john', 'John', 'John', 'John', 'Gospels', 'N.T.'],
    44: ['acts', 'Acts', 'Acts', 'Acts', 'History', 'N.T.'],
    45: ['romans', 'Romans', 'Romans', 'Rom', 'Pauline Epistles', 'N.T.'],
    46: ['1_corinthians', '1 Corinthians', '1 Corinthians', '1 Cor', 'Pauline Epistles', 'N.T.'],
    47: ['2_corinthians', '2 Corinthians', '2 Corinthians', '2 Cor', 'Pauline Epistles', 'N.T.'],
    48: ['galatians', 'Galatians', 'Galatians', 'Gal', 'Pauline Epistles', 'N.T.'],
    49: ['ephesians', 'Ephesians', 'Ephesians', 'Eph', 'Pauline Epistles', 'N.T.'],
    50: ['philippians', 'Philippians', 'Philippians', 'Phil', 'Pauline Epistles', 'N.T.'],
    51: ['colossians', 'Colossians', 'Colossians', 'Col', 'Pauline Epistles', 'N.T.'],
    52: ['1_thessalonians', '1 Thessalonians', '1 Thessalonians', '1 Thess', 'Pauline Epistles', 'N.T.'],
    53: ['2_thessalonians', '2 Thessalonians', '2 Thessalonians', '2 Thess', 'Pauline Epistles', 'N.T.'],
    54: ['1_timothy', '1 Timothy', '1 Timothy', '1 Tim', 'Pauline Epistles', 'N.T.'],
    55: ['2_timothy', '2 Timothy', '2 Timothy', '2 Tim', 'Pauline Epistles', 'N.T.'],
    56: ['titus', 'Titus', 'Titus', 'Titus', 'Pauline Epistles', 'N.T.'],
    57: ['philemon', 'Philemon', 'Philemon', 'Phlm', 'Pauline Epistles', 'N.T.'],
    58: ['hebrews', 'Hebrews', 'Hebrews', 'Heb', 'General Epistles', 'N.T.'],
    59: ['james', 'James', 'James', 'Jas', 'General Epistles', 'N.T.'],
    60: ['1_peter', '1 Peter', '1 Peter', '1 Pet', 'General Epistles', 'N.T.'],
    61: ['2_peter', '2 Peter', '2 Peter', '2 Pet', 'General Epistles', 'N.T.'],
    62: ['1_john', '1 John', '1 John', '1 John', 'General Epistles', 'N.T.'],
    63: ['2_john', '2 John', '2 John', '2 John', 'General Epistles', 'N.T.'],
    64: ['3_john', '3 John', '3 John', '3 John', 'General Epistles', 'N.T.'],
    65: ['jude', 'Jude', 'Jude', 'Jude', 'General Epistles', 'N.T.'],
    66: ['revelation', 'Revelation', 'Revelation', 'Rev', 'Prophetic', 'N.T.'],
  };

  /// Devuelve la tabla de datos según el idioma actual
  static Map<int, List<String>> get _currentBooksData =>
      _currentLanguage == _langEn ? _englishBooksData : _spanishBooksData;

  // ============================================================
  // API PÚBLICA
  // ============================================================

  static Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    _cachedBooks = null;
    _cachedSingleFileVerses = null;

    if (kDebugMode) {
      debugPrint('🌐 Idioma cambiado a: $language');
    }
  }

  static String get currentLanguage => _currentLanguage;
  static bool get isEnglish => _currentLanguage == _langEn;
  static bool get _isSingleFile => _formats[_currentLanguage] == 'single_file';

  // ============================================================
  // CARGA DE LIBROS
  // ============================================================

  static Future<List<BibliaBook>> getBooks() async {
    if (_cachedBooks != null) {
      return _cachedBooks!;
    }

    try {
      if (_isSingleFile) {
        _cachedBooks = await _loadBooksFromSingleFile();
      } else {
        _cachedBooks = await _loadBooksFromIndex();
      }

      if (kDebugMode) {
        debugPrint('✅ ${_cachedBooks!.length} libros cargados '
            '(idioma: $_currentLanguage)');
      }

      return _cachedBooks!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando libros: $e');
      }
      return [];
    }
  }

  static Future<List<BibliaBook>> _loadBooksFromIndex() async {
    final basePath = _basePaths[_currentLanguage]!;
    final jsonString = await rootBundle.loadString('$basePath$_indexFile');
    final List<dynamic> data = json.decode(jsonString);
    return data.map((e) => BibliaBook.fromJson(e)).toList();
  }

  static Future<List<BibliaBook>> _loadBooksFromSingleFile() async {
    final verses = await _loadSingleFileVerses();
    if (verses.isEmpty) return [];

    // Agrupar por libro
    final Map<int, Set<int>> booksChapters = {};

    for (final v in verses) {
      final int bookId = (v['book'] as num).toInt();
      final int chapter = (v['chapter'] as num).toInt();
      booksChapters.putIfAbsent(bookId, () => <int>{});
      booksChapters[bookId]!.add(chapter);
    }

    // ✅ Usar la tabla del idioma actual
    final booksData = _currentBooksData;
    final List<BibliaBook> books = [];
    final sortedIds = booksChapters.keys.toList()..sort();

    for (final id in sortedIds) {
      final chapterCount = booksChapters[id]!.length;
      final data = booksData[id];

      if (data == null) {
        books.add(BibliaBook(
          id: id,
          key: 'book_$id',
          title: 'Book $id',
          shortTitle: 'Book $id',
          abbr: 'B$id',
          category: 'Unknown',
          testament: id <= 39 ? 'O.T.' : 'N.T.',
          chapters: chapterCount,
          verses: 0,
        ));
        continue;
      }

      books.add(BibliaBook(
        id: id,
        key: data[0],
        title: data[1],
        shortTitle: data[2],
        abbr: data[3],
        category: data[4],
        testament: data[5],
        chapters: chapterCount,
        verses: 0,
      ));
    }

    return books;
  }

  static Future<List<Map<String, dynamic>>> _loadSingleFileVerses() async {
    if (_cachedSingleFileVerses != null) {
      return _cachedSingleFileVerses!;
    }

    final basePath = _basePaths[_currentLanguage]!;
    final jsonString = await rootBundle.loadString('$basePath$_singleFile');
    final dynamic decoded = json.decode(jsonString);

    List<dynamic> versesList;

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('verses')) {
        versesList = decoded['verses'] as List<dynamic>;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ El JSON no contiene la clave "verses"');
        }
        return [];
      }
    } else if (decoded is List) {
      versesList = decoded;
    } else {
      return [];
    }

    _cachedSingleFileVerses = versesList
        .whereType<Map<String, dynamic>>()
        .toList();

    if (kDebugMode) {
      debugPrint('📦 kjv.json cargado: '
          '${_cachedSingleFileVerses!.length} versículos');
    }

    return _cachedSingleFileVerses!;
  }

  // ============================================================
  // CARGA DE CAPÍTULOS
  // ============================================================

  static Future<List<BibliaVerse>> getChapter(
    BibliaBook book,
    int chapter,
  ) async {
    try {
      if (_isSingleFile) {
        return await _getChapterFromSingleFile(book, chapter);
      } else {
        return await _getChapterFromPerBook(book, chapter);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando capítulo $chapter de '
            '${book.shortTitle}: $e');
      }
      return [];
    }
  }

  static Future<List<BibliaVerse>> _getChapterFromSingleFile(
    BibliaBook book,
    int chapter,
  ) async {
    final verses = await _loadSingleFileVerses();

    final filtered = verses.where((v) {
      final int vBookId = (v['book'] as num).toInt();
      final int vChapter = (v['chapter'] as num).toInt();
      return vBookId == book.id && vChapter == chapter;
    }).toList();

    filtered.sort((a, b) {
      return ((a['verse'] as num).toInt())
          .compareTo((b['verse'] as num).toInt());
    });

    return filtered.map((v) {
      return BibliaVerse(
        bookId: book.id,
        chapter: chapter,
        verse: (v['verse'] as num).toInt(),
        text: (v['text'] ?? '').toString(),
      );
    }).toList();
  }

  static Future<List<BibliaVerse>> _getChapterFromPerBook(
    BibliaBook book,
    int chapter,
  ) async {
    final basePath = _basePaths[_currentLanguage]!;
    final filePath = '$basePath${book.key}.json';

    final jsonString = await rootBundle.loadString(filePath);
    final List<dynamic> data = json.decode(jsonString);

    if (chapter < 1 || chapter > data.length) return [];

    final List<dynamic> verses = data[chapter - 1];

    return List.generate(
      verses.length,
      (index) => BibliaVerse(
        bookId: book.id,
        chapter: chapter,
        verse: index + 1,
        text: verses[index].toString(),
      ),
    );
  }

  // ============================================================
  // OTROS MÉTODOS
  // ============================================================

  static Future<BibliaVerse?> getVerse(BibliaBook book, int chapter, int verse) async {
    try {
      final verses = await getChapter(book, chapter);
      if (verse < 1 || verse > verses.length) return null;
      return verses[verse - 1];
    } catch (e) {
      return null;
    }
  }

  static Future<List<BibliaVerse>> searchVerses(BibliaBook book, String query) async {
    try {
      final allVerses = <BibliaVerse>[];
      for (int i = 1; i <= book.chapters; i++) {
        final chapterVerses = await getChapter(book, i);
        for (var verse in chapterVerses) {
          if (verse.text.toLowerCase().contains(query.toLowerCase())) {
            allVerses.add(verse);
          }
        }
      }
      return allVerses;
    } catch (e) {
      return [];
    }
  }

  static Future<int> getChapterCount(BibliaBook book) async {
    try {
      if (_isSingleFile) {
        final verses = await _loadSingleFileVerses();
        final chapters = <int>{};
        for (final v in verses) {
          if ((v['book'] as num).toInt() == book.id) {
            chapters.add((v['chapter'] as num).toInt());
          }
        }
        return chapters.length;
      } else {
        final basePath = _basePaths[_currentLanguage]!;
        final jsonString = await rootBundle.loadString('$basePath${book.key}.json');
        final List<dynamic> data = json.decode(jsonString);
        return data.length;
      }
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> bookExists(BibliaBook book) async {
    try {
      if (_isSingleFile) {
        final verses = await _loadSingleFileVerses();
        return verses.any((v) => (v['book'] as num).toInt() == book.id);
      } else {
        final basePath = _basePaths[_currentLanguage]!;
        await rootBundle.loadString('$basePath${book.key}.json');
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<List<BibliaVerse>> getAllVerses(BibliaBook book) async {
    try {
      if (_isSingleFile) {
        final verses = await _loadSingleFileVerses();
        final filtered = verses
            .where((v) => (v['book'] as num).toInt() == book.id)
            .toList();
        filtered.sort((a, b) {
          final int ca = (a['chapter'] as num).toInt();
          final int cb = (b['chapter'] as num).toInt();
          if (ca != cb) return ca.compareTo(cb);
          return ((a['verse'] as num).toInt())
              .compareTo((b['verse'] as num).toInt());
        });
        return filtered.map((v) => BibliaVerse(
          bookId: book.id,
          chapter: (v['chapter'] as num).toInt(),
          verse: (v['verse'] as num).toInt(),
          text: (v['text'] ?? '').toString(),
        )).toList();
      } else {
        final allVerses = <BibliaVerse>[];
        for (int i = 1; i <= book.chapters; i++) {
          allVerses.addAll(await getChapter(book, i));
        }
        return allVerses;
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<BibliaBook>> getBooksByTestament(String testament) async {
    try {
      final allBooks = await getBooks();
      return allBooks.where((book) => book.testament == testament).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<BibliaBook>> getBooksByCategory(String category) async {
    try {
      final allBooks = await getBooks();
      return allBooks.where((book) => book.category == category).toList();
    } catch (e) {
      return [];
    }
  }

  static int getTotalVerses(BibliaBook book) => book.verses;
}