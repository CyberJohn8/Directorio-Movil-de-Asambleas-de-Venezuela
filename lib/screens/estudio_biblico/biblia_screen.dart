// lib/screens/estudio_biblico/biblia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/biblia.dart';
import '../../models/versiculo_guardado.dart';
import '../../services/biblia_service.dart';
import '../../services/versiculos_guardados_service.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme.dart';
import '../../utils/voice_helper.dart';
import 'buscador_biblia.dart';
import 'versiculos_guardados_screen.dart';

class BibliaScreen extends StatefulWidget {
  const BibliaScreen({super.key});

  @override
  State<BibliaScreen> createState() => _BibliaScreenState();
}

class _BibliaScreenState extends State<BibliaScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  List<BibliaBook> books = [];
  List<BibliaVerse> verses = [];
  bool cargandoBooks = true;
  bool cargandoVerses = false;

  // Variables de audio
  bool isSpeaking = false;
  bool isPaused = false;
  int currentVerseIndex = -1;
  String? currentVerseText;

  BibliaBook? selectedBook;
  int selectedChapter = 1;
  int maxChapters = 0;
  double fontSize = 18.0;
  BibliaVerse? randomVerse;
  String? randomCitation;
  bool showAudioPanel = false;
  bool _mostrarAntiguoTestamento = true;

  // Idioma actual (es = Español, en = Inglés)
  String _currentLanguage = 'es';

  // Preferencias de audio
  bool _announceBook = true;
  bool _announceVerseNumber = true;
  double _speechRate = 0.45;
  double _pitch = 1.0;
  Map<String, String>? _selectedVoice;
  List<Map<String, String>> _availableVoices = [];
  bool _voicesLoaded = false;

  // Repetir / siguiente capítulo
  bool _repeatChapter = false;
  bool _autoNextChapter = false;
  int _pauseDuration = 2;
  bool _isWaitingForNextAction = false;

  // Últimas lecturas (hasta 5)
  List<Map<String, dynamic>> _ultimasLecturas = [];

  static const String _keyAnnounceBook = 'announce_book';
  static const String _keyAnnounceVerse = 'announce_verse';
  static const String _keySpeechRate = 'speech_rate';
  static const String _keyPitch = 'pitch';
  static const String _keySelectedVoiceName = 'selected_voice_name';
  static const String _keySelectedVoiceLocale = 'selected_voice_locale';
  static const String _keyRepeatChapter = 'repeat_chapter';
  static const String _keyAutoNextChapter = 'auto_next_chapter';
  static const String _keyPauseDuration = 'pause_duration';
  static const String _keyLanguage = 'bible_language';

  final ScrollController _scrollController = ScrollController();

  // ========================================
  // HELPERS DE IDIOMA
  // ========================================
  bool get _isEnglish => _currentLanguage == 'en';

  String _t(String es, String en) => _isEnglish ? en : es;

  // ========================================
  // HELPERS SEGUROS
  // ========================================
  int _safeInt(dynamic value, {int fallback = 1}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  // ========================================
  // LIMPIAR TEXTO
  // ========================================
  String _cleanVerseText(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(RegExp(r'\n'), ' ')
        .replaceAll(RegExp(r'\r'), ' ')
        .replaceAll(RegExp(r'\t'), ' ')
        .replaceAll('_', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadPreferences();
    _loadVoices();
    _loadLastRead();
    _cargarBooks();
  }

  // ========================================
  // CARGA DE DATOS
  // ========================================
  Future<void> _cargarBooks() async {
    try {
      final lista = await BibliaService.getBooks();
      final lecturas =
          await VersiculosGuardadosService.obtenerUltimasLecturas();

      if (mounted) {
        setState(() {
          books = lista;
          cargandoBooks = false;
          _ultimasLecturas = lecturas;
          selectedBook = null;
          selectedChapter = 1;
          maxChapters = 0;
          verses = [];
        });
        _loadRandomVerse();
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargandoBooks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_t('Error al cargar libros: $e',
                  'Error loading books: $e'))),
        );
      }
    }
  }

  Future<void> _loadLastRead() async {
    try {
      final lecturas =
          await VersiculosGuardadosService.obtenerUltimasLecturas();
      if (mounted) {
        setState(() => _ultimasLecturas = lecturas);
        if (kDebugMode) {
          debugPrint('📚 _loadLastRead: ${lecturas.length} lecturas');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error cargando últimas lecturas: $e');
    }
  }

  Future<void> _saveLastRead() async {
    if (selectedBook == null) return;

    final int versiculoAGuardar =
        currentVerseIndex >= 0 ? currentVerseIndex + 1 : 1;

    await VersiculosGuardadosService.agregarUltimaLectura(
      libro: selectedBook!.shortTitle,
      capitulo: selectedChapter,
      versiculo: versiculoAGuardar,
      idioma: _currentLanguage,
    );
    await _loadLastRead();
  }

  Future<void> _loadRandomVerse() async {
    try {
      if (books.isEmpty) return;
      final rnd = Random();
      final book = books[rnd.nextInt(books.length)];
      final chapter = (book.chapters > 0) ? rnd.nextInt(book.chapters) + 1 : 1;
      final lista = await _getVerses(book, chapter);
      if (lista.isEmpty) return;
      final verse = lista[rnd.nextInt(lista.length)];
      if (mounted) {
        setState(() {
          randomVerse = verse.copyWith(text: _cleanVerseText(verse.text));
          randomCitation = '${book.shortTitle} $chapter:${verse.verse}';
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error versículo aleatorio: $e');
    }
  }

  Future<List<BibliaVerse>> _getVerses(BibliaBook book, int chapter) async {
    try {
      final verses = await BibliaService.getChapter(book, chapter);
      return verses
          .map((v) => v.copyWith(text: _cleanVerseText(v.text)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo versículos: $e');
      return [];
    }
  }

  Future<void> _cargarVerses() async {
    if (selectedBook == null) return;

    await _stopSpeaking();
    setState(() {
      currentVerseIndex = -1;
      isPaused = false;
      isSpeaking = false;
      _isWaitingForNextAction = false;
    });

    setState(() => cargandoVerses = true);
    try {
      final lista = await _getVerses(selectedBook!, selectedChapter);
      if (mounted) {
        setState(() {
          verses = lista;
          cargandoVerses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargandoVerses = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Error al cargar versículos: $e',
              'Error loading verses: $e'))),
        );
      }
    }
  }

  // ========================================
  // PREFERENCIAS
  // ========================================
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final savedLang = prefs.getString(_keyLanguage) ?? 'es';
      await BibliaService.setLanguage(savedLang);
      setState(() {
        fontSize = prefs.getDouble('bibliaFontSize') ?? 18.0;
        _announceBook = prefs.getBool(_keyAnnounceBook) ?? true;
        _announceVerseNumber = prefs.getBool(_keyAnnounceVerse) ?? true;
        _speechRate = prefs.getDouble(_keySpeechRate) ?? 0.45;
        _pitch = prefs.getDouble(_keyPitch) ?? 1.0;
        _repeatChapter = prefs.getBool(_keyRepeatChapter) ?? false;
        _autoNextChapter = prefs.getBool(_keyAutoNextChapter) ?? false;
        _pauseDuration = prefs.getInt(_keyPauseDuration) ?? 2;
        _currentLanguage = savedLang;

        final voiceName = prefs.getString(_keySelectedVoiceName);
        final voiceLocale = prefs.getString(_keySelectedVoiceLocale);
        if (voiceName != null && voiceLocale != null) {
          _selectedVoice = {'name': voiceName, 'locale': voiceLocale};
        }
      });
    }
  }

  Future<void> _saveFontSizePreference(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bibliaFontSize', value);
  }

  Future<void> _saveAudioPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAnnounceBook, _announceBook);
    await prefs.setBool(_keyAnnounceVerse, _announceVerseNumber);
    await prefs.setDouble(_keySpeechRate, _speechRate);
    await prefs.setDouble(_keyPitch, _pitch);
    await prefs.setBool(_keyRepeatChapter, _repeatChapter);
    await prefs.setBool(_keyAutoNextChapter, _autoNextChapter);
    await prefs.setInt(_keyPauseDuration, _pauseDuration);

    if (_selectedVoice != null) {
      await prefs.setString(_keySelectedVoiceName, _selectedVoice!['name'] ?? '');
      await prefs.setString(_keySelectedVoiceLocale, _selectedVoice!['locale'] ?? '');
    } else {
      await prefs.remove(_keySelectedVoiceName);
      await prefs.remove(_keySelectedVoiceLocale);
    }

    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    if (_selectedVoice != null) {
      await _flutterTts.setVoice(_selectedVoice!);
    }
  }

  Future<void> _saveLanguagePreference(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang);
  }

  // ========================================
  // VOCES
  // ========================================
  Future<void> _loadVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (mounted) {
        final List<Map<String, String>> voiceList = [];
        for (var voice in voices) {
          if (voice is Map) {
            final Map<String, String> voiceMap = {};
            voice.forEach((key, value) {
              if (key is String && value is String) {
                voiceMap[key] = value;
              }
            });
            if (voiceMap.isNotEmpty) {
              voiceList.add(voiceMap);
            }
          }
        }
        final filtered = VoiceHelper.filterAndSort(voiceList);
        setState(() {
          _availableVoices = filtered;
          _voicesLoaded = true;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error cargando voces: $e');
      if (mounted) setState(() => _voicesLoaded = true);
    }
  }

  // ========================================
  // INICIALIZACIÓN TTS
  // ========================================
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    if (_selectedVoice != null) {
      await _flutterTts.setVoice(_selectedVoice!);
    }
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = true;
          isPaused = false;
        });
      }
    });
    _restoreCompletionHandler();
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          isPaused = false;
        });
      }
      if (kDebugMode) debugPrint('❌ Error en TTS: $msg');
    });
  }

  void _restoreCompletionHandler() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          isPaused = false;
        });
        _goToNextVerse();
      }
    });
  }

  // ========================================
  // AUDIO
  // ========================================
  String _getBookNameWithArticle(String bookName) {
    if (_isEnglish) return bookName;
    final masculineBooks = [
      'Génesis', 'Éxodo', 'Levítico', 'Números', 'Deuteronomio',
      'Josué', 'Jueces', 'Rut', 'Samuel', 'Reyes', 'Crónicas',
      'Esdras', 'Nehemías', 'Ester', 'Job', 'Salmos', 'Proverbios',
      'Eclesiastés', 'Cantares', 'Isaías', 'Jeremías', 'Ezequiel',
      'Daniel', 'Oseas', 'Joel', 'Amós', 'Abdías', 'Jonás', 'Miqueas',
      'Nahúm', 'Habacuc', 'Sofonías', 'Hageo', 'Zacarías', 'Malaquías',
      'Mateo', 'Marcos', 'Lucas', 'Juan', 'Hechos', 'Romanos',
      'Corintios', 'Gálatas', 'Efesios', 'Filipenses', 'Colosenses',
      'Tesalonicenses', 'Timoteo', 'Tito', 'Filemón', 'Hebreos',
      'Santiago', 'Pedro', 'Juan', 'Judas', 'Apocalipsis'
    ];
    if (masculineBooks.any((b) => bookName.contains(b))) {
      return 'el $bookName';
    }
    return bookName;
  }

  Future<void> _speakVerseAtIndex(int index) async {
    if (verses.isEmpty || index < 0 || index >= verses.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_t('No hay versículos para leer.',
                  'No verses to read.'))),
        );
      }
      return;
    }

    if (_isWaitingForNextAction) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }

    await _flutterTts.stop();

    final verse = verses[index];
    String textToSpeak = '';

    if (_announceVerseNumber && selectedBook != null) {
      textToSpeak +=
          _t('Versículo ${verse.verse}. ', 'Verse ${verse.verse}. ');
    }
    textToSpeak += _cleanVerseText(verse.text);

    setState(() {
      currentVerseIndex = index;
      currentVerseText = textToSpeak;
      isSpeaking = true;
      isPaused = false;
    });

    await _saveLastRead();

    await _flutterTts.speak(textToSpeak);
    if (mounted) _scrollToVerse(index);
  }

  Future<void> _speakChapter() async {
    if (verses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_t('Carga el capítulo primero para escuchar.',
                  'Load the chapter first to listen.'))),
        );
      }
      return;
    }

    if (isPaused) {
      await _resumeSpeaking();
      return;
    }

    if (isSpeaking) return;
    _isWaitingForNextAction = false;

    try {
      await _flutterTts.stop();

      if (_announceBook && selectedBook != null) {
        final String bookName =
            _getBookNameWithArticle(selectedBook!.shortTitle);
        final String announcement = _isEnglish
            ? 'Book of $bookName, chapter $selectedChapter.'
            : 'Libro de $bookName, capítulo $selectedChapter.';

        final completer = Completer<void>();
        _flutterTts.setCompletionHandler(() {
          if (!completer.isCompleted) completer.complete();
        });

        await _flutterTts.speak(announcement);

        try {
          await completer.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );
        } catch (_) {}

        _restoreCompletionHandler();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted || verses.isEmpty) return;

      setState(() {
        currentVerseIndex = 0;
        isSpeaking = true;
        isPaused = false;
      });

      await _speakVerseAtIndex(0);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error en _speakChapter: $e');
      if (mounted) {
        setState(() {
          isSpeaking = false;
          isPaused = false;
        });
      }
    }
  }

  Future<void> _pauseSpeaking() async {
    if (isSpeaking && !isPaused) {
      await _flutterTts.stop();
      setState(() {
        isSpeaking = false;
        isPaused = true;
      });
    }
  }

  Future<void> _resumeSpeaking() async {
    if (isPaused && currentVerseIndex >= 0) {
      _isWaitingForNextAction = false;
      await _speakVerseAtIndex(currentVerseIndex);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        isSpeaking = false;
        isPaused = false;
        currentVerseIndex = -1;
        currentVerseText = null;
        _isWaitingForNextAction = false;
      });
    }
  }

  Future<void> _goToNextVerse() async {
    if (!mounted) return;
    if (currentVerseIndex < verses.length - 1) {
      await _speakVerseAtIndex(currentVerseIndex + 1);
    } else {
      await _handleChapterEnd();
    }
  }

  Future<void> _handleChapterEnd() async {
    if (!mounted) return;
    setState(() {
      isSpeaking = false;
      isPaused = false;
    });

    if (_isWaitingForNextAction) return;

    if (_repeatChapter || _autoNextChapter) {
      _isWaitingForNextAction = true;
      await Future.delayed(Duration(seconds: _pauseDuration));
      if (!mounted) return;
      _isWaitingForNextAction = false;

      if (_repeatChapter) {
        await _repeatCurrentChapter();
      } else if (_autoNextChapter) {
        await _goToNextChapter();
      }
    } else {
      setState(() => currentVerseIndex = -1);
    }
  }

  Future<void> _repeatCurrentChapter() async {
    if (!mounted || selectedBook == null) return;
    setState(() => currentVerseIndex = -1);

    if (_announceBook) {
      final String bookName =
          _getBookNameWithArticle(selectedBook!.shortTitle);
      final String msg = _isEnglish
          ? 'Repeating chapter $selectedChapter of the book of $bookName.'
          : 'Repitiendo capítulo $selectedChapter del libro de $bookName.';
      await _flutterTts.speak(msg);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    await _speakVerseAtIndex(0);
  }

  Future<void> _goToNextChapter() async {
    if (!mounted || selectedBook == null) return;

    if (selectedChapter < selectedBook!.chapters) {
      setState(() {
        selectedChapter++;
        currentVerseIndex = -1;
        verses = [];
        _isWaitingForNextAction = false;
      });
      await _cargarVerses();

      if (mounted && verses.isNotEmpty) {
        if (_announceBook) {
          final String bookName =
              _getBookNameWithArticle(selectedBook!.shortTitle);
          final String msg = _isEnglish
              ? 'Chapter $selectedChapter of the book of $bookName.'
              : 'Capítulo $selectedChapter del libro de $bookName.';
          await _flutterTts.speak(msg);
          await Future.delayed(const Duration(milliseconds: 500));
        }
        await _speakVerseAtIndex(0);
      }
    } else {
      final String bookName =
          _getBookNameWithArticle(selectedBook!.shortTitle);
      final String message = _isEnglish
          ? 'The book of $bookName has ended.'
          : 'El libro de $bookName ha concluido.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('📕 $message'),
              duration: const Duration(seconds: 3)),
        );
      }
      await _flutterTts.speak(message);
      setState(() {
        _isWaitingForNextAction = false;
        isSpeaking = false;
        currentVerseIndex = -1;
      });
    }
  }

  Future<void> _goToPreviousVerse() async {
    if (!mounted) return;
    if (currentVerseIndex > 0) {
      await _speakVerseAtIndex(currentVerseIndex - 1);
    } else {
      await _speakVerseAtIndex(0);
    }
  }

  Future<void> _selectVerse(int verseNumber) async {
    if (!mounted) return;
    if (verseNumber < 1 || verseNumber > verses.length) return;

    _isWaitingForNextAction = false;
    final int index = verseNumber - 1;
    await _speakVerseAtIndex(index);
  }

  void _scrollToVerse(int index) {
    if (_scrollController.hasClients) {
      const double itemHeight = 80.0;
      final double scrollPosition = index * itemHeight;
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ========================================
  // ABRIR ÚLTIMA LECTURA
  // ========================================
  Future<void> _abrirUltimaLectura(
      String libro, int capitulo, int versiculo,
      {String? idioma}) async {
    if (idioma != null && idioma != _currentLanguage) {
      await _cambiarIdioma(idioma);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }

    final book = books.firstWhere(
      (b) => b.shortTitle == libro,
      orElse: () => books.first,
    );
    if (book.shortTitle != libro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
              'No se encontró "$libro" en esta versión.',
              '"$libro" was not found in this version.',
            )),
          ),
        );
      }
      return;
    }

    setState(() {
      selectedBook = book;
      selectedChapter = capitulo;
      maxChapters = book.chapters;
    });

    await _cargarVerses();

    if (versiculo > 0 && versiculo <= verses.length) {
      _scrollToVerse(versiculo - 1);
    }
  }

  // ========================================
  // GUARDAR VERSÍCULO
  // ========================================
  Future<void> _guardarVersiculo(BibliaVerse verse) async {
    if (selectedBook == null) return;

    final id = '${selectedBook!.shortTitle}_${selectedChapter}_${verse.verse}';
    final yaGuardado = await VersiculosGuardadosService.estaGuardado(id);

    if (yaGuardado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_t('ℹ️ Este versículo ya está guardado',
                  'ℹ️ This verse is already saved'))),
        );
      }
      return;
    }

    final nuevo = VersiculoGuardado(
      id: id,
      libro: selectedBook!.shortTitle,
      capitulo: selectedChapter,
      versiculo: verse.verse,
      texto: verse.text,
      fechaGuardado: DateTime.now(),
      idioma: _currentLanguage,
    );

    final ok = await VersiculosGuardadosService.guardarVersiculo(nuevo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? _t('✅ Versículo guardado en favoritos',
                  '✅ Verse saved to favorites')
              : _t('⚠️ No se pudo guardar', '⚠️ Could not save')),
          action: ok
              ? SnackBarAction(
                  label: _t('Ver', 'View'),
                  textColor: const Color(0xFFEAE4D5),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VersiculosGuardadosScreen(),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  Widget _buildMenuTresPuntos(
      BibliaVerse verse, int index, bool isCurrentVerse) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: isCurrentVerse ? const Color(0xFF637983) : Colors.grey.shade600,
      ),
      tooltip: _t('Opciones', 'Options'),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuAction(value, verse, index),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'compartir',
          child: Row(
            children: [
              const Icon(Icons.share, size: 20, color: Color(0xFF637983)),
              const SizedBox(width: 12),
              Text(_t('Compartir', 'Share'),
                  style:
                      const TextStyle(fontFamily: 'Sansation', fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copiar',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20, color: Color(0xFF637983)),
              const SizedBox(width: 12),
              Text(_t('Copiar', 'Copy'),
                  style:
                      const TextStyle(fontFamily: 'Sansation', fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'guardar',
          child: Row(
            children: [
              const Icon(Icons.bookmark_add_outlined,
                  size: 20, color: Color(0xFF637983)),
              const SizedBox(width: 12),
              Text(_t('Guardar versículo', 'Save verse'),
                  style:
                      const TextStyle(fontFamily: 'Sansation', fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'leer',
          child: Row(
            children: [
              const Icon(Icons.play_arrow,
                  size: 20, color: Color(0xFF637983)),
              const SizedBox(width: 12),
              Text(_t('Leer desde aquí', 'Read from here'),
                  style:
                      const TextStyle(fontFamily: 'Sansation', fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenuAction(
      String action, BibliaVerse verse, int index) async {
    final cita =
        '${selectedBook?.shortTitle ?? ''} ${selectedChapter}:${verse.verse}';

    switch (action) {
      case 'compartir':
        await Share.share('"${verse.text}"\n\n— $cita');
        break;
      case 'copiar':
        await Clipboard.setData(ClipboardData(text: '"${verse.text}" — $cita'));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_t('✅ Versículo copiado', '✅ Verse copied'))),
          );
        }
        break;
      case 'guardar':
        await _guardarVersiculo(verse);
        break;
      case 'leer':
        await _speakVerseAtIndex(index);
        break;
    }
  }

  // ========================================
  // DIÁLOGO DE CAMBIO DE IDIOMA
  // ========================================
  void _mostrarDialogoIdioma() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: const Color(0xFFEAE4D5),
              title: Row(
                children: [
                  const Icon(Icons.language, color: Color(0xFF637983)),
                  const SizedBox(width: 10),
                  Text(
                    _t('Idioma de la Biblia', 'Bible Language'),
                    style: const TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF637983),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIdiomaOption(
                    setStateDialog,
                    _t('Español', 'Spanish'),
                    'es',
                    Icons.flag,
                    versionName: 'Reina-Valera 1960',
                  ),
                  const SizedBox(height: 8),
                  _buildIdiomaOption(
                    setStateDialog,
                    _t('Inglés', 'English'),
                    'en',
                    Icons.flag_outlined,
                    versionName: 'King James Version',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    _t('Cancelar', 'Cancel'),
                    style: const TextStyle(
                      fontFamily: 'Sansation',
                      color: Color(0xFF637983),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIdiomaOption(
    StateSetter setStateDialog,
    String label,
    String lang,
    IconData icon, {
    String? versionName,
  }) {
    final bool isSelected = _currentLanguage == lang;

    return GestureDetector(
      onTap: () async {
        if (_currentLanguage == lang) {
          Navigator.pop(context);
          return;
        }

        Navigator.pop(context);
        await _cambiarIdioma(lang);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF637983) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF637983),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF637983),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF637983),
                    ),
                  ),
                  if (versionName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      versionName,
                      style: TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF637983).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white)
            else
              const Icon(Icons.circle_outlined, color: Color(0xFF637983)),
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarIdioma(String lang) async {
    if (_currentLanguage == lang) return;

    final scaffoldContext = context;

    if (mounted) {
      showDialog(
        context: scaffoldContext,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF637983)),
        ),
      );
    }

    try {
      await _stopSpeaking();
      await BibliaService.setLanguage(lang);
      await _saveLanguagePreference(lang);

      final lista = await BibliaService.getBooks();

      if (!mounted) return;
      Navigator.of(scaffoldContext).pop();

      setState(() {
        _currentLanguage = lang;
        books = lista;
        selectedBook = null;
        selectedChapter = 1;
        maxChapters = 0;
        verses = [];
        currentVerseIndex = -1;
        randomVerse = null;
        randomCitation = null;
      });

      _loadRandomVerse();
      await _loadLastRead();

      if (!mounted) return;
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'es'
                ? '✅ Idioma cambiado a Español'
                : '✅ Language changed to English',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(scaffoldContext).pop();
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ========================================
  // DIÁLOGOS
  // ========================================
  void _mostrarDialogoTamanoFuente() {
    showDialog(
      context: context,
      builder: (context) {
        double tempSize = fontSize;
        return AlertDialog(
          backgroundColor: const Color(0xFFEAE4D5),
          title: Text(
            _t('Tamaño de letra', 'Font size'),
            style: const TextStyle(
              fontFamily: 'Sansation',
              color: Color(0xFF637983),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    children: [
                      Slider(
                        value: tempSize,
                        min: 12,
                        max: 36,
                        divisions: 12,
                        label: tempSize.toInt().toString(),
                        activeColor: const Color(0xFF637983),
                        onChanged: (v) => setStateDialog(() => tempSize = v),
                      ),
                      Text(_t('Previsualización', 'Preview'),
                          style: TextStyle(
                              fontSize: tempSize, fontFamily: 'Sansation')),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('Cancelar', 'Cancel'),
                  style: const TextStyle(
                      fontFamily: 'Sansation', color: Color(0xFF637983))),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => fontSize = tempSize);
                _saveFontSizePreference(tempSize);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF637983),
                foregroundColor: Colors.white,
              ),
              child: Text(_t('Aplicar', 'Apply'),
                  style: const TextStyle(fontFamily: 'Sansation')),
            ),
          ],
        );
      },
    );
  }

  void _showVerseSelector() {
    if (verses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _t('No hay versículos disponibles', 'No verses available'))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            decoration: BoxDecoration(
              color: const Color(0xFFEAE4D5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF637983),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t('Seleccionar Versículo', 'Select Verse'),
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontSize: 18,
                            color: Color(0xFFEAE4D5),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFFEAE4D5)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final int verseNumber = index + 1;
                      final bool isCurrent = currentVerseIndex == index;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _selectVerse(verseNumber);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF637983)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF637983), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              verseNumber.toString(),
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 16,
                                color: isCurrent
                                    ? Colors.white
                                    : const Color(0xFF637983),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoLibros() {
    final antiguoTestamento = books
        .where((book) =>
            book.testament == 'A.T.' ||
            book.testament == 'O.T.' ||
            book.testament == 'Antiguo Testamento' ||
            book.testament == 'Old Testament')
        .toList();
    final nuevoTestamento = books
        .where((book) =>
            book.testament == 'N.T.' ||
            book.testament == 'Nuevo Testamento' ||
            book.testament == 'New Testament')
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final List<BibliaBook> librosMostrar = _mostrarAntiguoTestamento
                ? antiguoTestamento
                : nuevoTestamento;
            final String tituloTestamento = _mostrarAntiguoTestamento
                ? _t('AT', 'OT')
                : _t('NT', 'NT');

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.9,
                constraints:
                    const BoxConstraints(maxWidth: 500, maxHeight: 550),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE4D5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF637983),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          Text(
                            _t('Seleccionar Libro', 'Select Book'),
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 18,
                              color: Color(0xFFEAE4D5),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFFEAE4D5)),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFA2B0BE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setStateDialog(
                                    () => _mostrarAntiguoTestamento = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _mostrarAntiguoTestamento
                                        ? const Color(0xFF637983)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _t('Antiguo', 'Old'),
                                      style: TextStyle(
                                        fontFamily: 'Sansation',
                                        fontSize: 13,
                                        fontWeight: _mostrarAntiguoTestamento
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _mostrarAntiguoTestamento
                                            ? Colors.white
                                            : const Color(0xFF637983),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setStateDialog(
                                    () => _mostrarAntiguoTestamento = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_mostrarAntiguoTestamento
                                        ? const Color(0xFF637983)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _t('Nuevo', 'New'),
                                      style: TextStyle(
                                        fontFamily: 'Sansation',
                                        fontSize: 13,
                                        fontWeight: !_mostrarAntiguoTestamento
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: !_mostrarAntiguoTestamento
                                            ? Colors.white
                                            : const Color(0xFF637983),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA2B0BE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          Text(
                            tituloTestamento,
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${librosMostrar.length} ${_t('libros', 'books')}',
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: librosMostrar.isEmpty
                          ? Center(
                              child: Text(
                                _t('No hay libros en este testamento',
                                    'No books in this testament'),
                                style: const TextStyle(
                                    fontFamily: 'Sansation',
                                    color: Color(0xFF637983)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              itemCount: librosMostrar.length,
                              itemBuilder: (context, index) {
                                final book = librosMostrar[index];
                                final bool isSelected =
                                    selectedBook?.id == book.id;
                                return GestureDetector(
                                  onTap: () async {
                                    if (!mounted) return;

                                    final navigator =
                                        Navigator.of(dialogContext);
                                    final scaffoldContext = this.context;

                                    setState(() {
                                      selectedBook = book;
                                      selectedChapter = 1;
                                      maxChapters = book.chapters;
                                      verses = [];
                                      currentVerseIndex = -1;
                                      isPaused = false;
                                      isSpeaking = false;
                                      _isWaitingForNextAction = false;
                                    });
                                    navigator.pop();

                                    if (!mounted) return;
                                    showDialog(
                                      context: scaffoldContext,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(
                                          child: CircularProgressIndicator()),
                                    );

                                    await _cargarVerses();
                                    await _saveLastRead();

                                    if (!mounted) return;
                                    Navigator.of(scaffoldContext).pop();
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF637983)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFF637983),
                                          width: 2),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                    .withValues(alpha: 0.2)
                                                : const Color(0xFF637983)
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontFamily: 'Sansation',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF637983),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            book.shortTitle,
                                            style: TextStyle(
                                              fontFamily: 'Sansation',
                                              fontSize: 15,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF637983),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                    .withValues(alpha: 0.2)
                                                : const Color(0xFF637983)
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${book.chapters} ${_t('cap.', 'ch.')}',
                                            style: TextStyle(
                                              fontFamily: 'Sansation',
                                              fontSize: 11,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF637983),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF637983),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoCapitulos() {
    if (selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _t('Primero selecciona un libro', 'Select a book first'))),
      );
      return;
    }
    final totalCapitulos = selectedBook!.chapters;
    if (totalCapitulos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_t(
                'No se encontraron capítulos para ${selectedBook!.shortTitle}',
                'No chapters found for ${selectedBook!.shortTitle}'))),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 550),
            decoration: BoxDecoration(
              color: const Color(0xFFEAE4D5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF637983),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _t('Capítulos de ${selectedBook!.shortTitle}',
                              'Chapters of ${selectedBook!.shortTitle}'),
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontSize: 18,
                            color: Color(0xFFEAE4D5),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFFEAE4D5)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA2B0BE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedBook!.shortTitle,
                        style: const TextStyle(
                          fontFamily: 'Sansation',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$totalCapitulos ${_t('capítulos', 'chapters')}',
                        style: const TextStyle(
                          fontFamily: 'Sansation',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<int>>(
                    future: _getChapterVerseCounts(selectedBook!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final List<int> verseCounts = snapshot.data ?? [];
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.35,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: totalCapitulos,
                        itemBuilder: (context, index) {
                          final int chapterNumber = index + 1;
                          final bool isSelected =
                              selectedChapter == chapterNumber;
                          final int verseCount = verseCounts.isNotEmpty &&
                                  index < verseCounts.length
                              ? verseCounts[index]
                              : 0;

                          return GestureDetector(
                            onTap: () async {
                              setState(
                                  () => selectedChapter = chapterNumber);
                              Navigator.pop(context);
                              await _cargarVerses();
                              await _saveLastRead();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF637983)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF637983),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    chapterNumber.toString(),
                                    style: TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF637983),
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  if (verseCount > 0)
                                    Text(
                                      '$verseCount ${_t('vers.', 'verses')}',
                                      style: TextStyle(
                                        fontFamily: 'Sansation',
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : const Color(0xFF637983)
                                                .withValues(alpha: 0.75),
                                        height: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else
                                    Text(
                                      '—',
                                      style: TextStyle(
                                        fontFamily: 'Sansation',
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.6)
                                            : Colors.grey.shade400,
                                        height: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<int>> _getChapterVerseCounts(BibliaBook book) async {
    final List<int> counts = [];
    for (int i = 1; i <= book.chapters; i++) {
      try {
        final v = await BibliaService.getChapter(book, i);
        counts.add(v.length);
      } catch (e) {
        counts.add(0);
      }
    }
    return counts;
  }

  // ========================================
  // DIÁLOGO DE AUDIO
  // ========================================
  void _showAudioConfigDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: const Color(0xFFEAE4D5),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                constraints:
                    const BoxConstraints(maxWidth: 450, maxHeight: 700),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFF637983), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.settings_voice,
                              color: Color(0xFF637983), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _t('Configuración de Audio',
                                  'Audio Settings'),
                              style: const TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF637983),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFF637983)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildConfigSwitch(
                              setStateDialog,
                              _t('Anunciar libro al inicio',
                                  'Announce book at start'),
                              _t(
                                  'Dice "Libro de ... capítulo ..." al comenzar',
                                  'Says "Book of ... chapter ..." at start'),
                              _announceBook,
                              (value) {
                                setStateDialog(() => _announceBook = value);
                                setState(() => _announceBook = value);
                                _saveAudioPreferences();
                              },
                              Icons.book,
                            ),
                            const SizedBox(height: 8),
                            _buildConfigSwitch(
                              setStateDialog,
                              _t('Anunciar número de versículo',
                                  'Announce verse number'),
                              _t(
                                  'Dice "Versículo X" antes de cada versículo',
                                  'Says "Verse X" before each verse'),
                              _announceVerseNumber,
                              (value) {
                                setStateDialog(
                                    () => _announceVerseNumber = value);
                                setState(
                                    () => _announceVerseNumber = value);
                                _saveAudioPreferences();
                              },
                              Icons.format_list_numbered,
                            ),
                            const SizedBox(height: 8),
                            _buildConfigSwitch(
                              setStateDialog,
                              _t('Repetir Capítulo', 'Repeat Chapter'),
                              _t('Repite automáticamente al finalizar',
                                  'Automatically repeats at the end'),
                              _repeatChapter,
                              (value) {
                                setStateDialog(() {
                                  _repeatChapter = value;
                                  if (value) _autoNextChapter = false;
                                });
                                setState(() {
                                  _repeatChapter = value;
                                  if (value) _autoNextChapter = false;
                                });
                                _saveAudioPreferences();
                              },
                              Icons.repeat,
                            ),
                            const SizedBox(height: 8),
                            _buildConfigSwitch(
                              setStateDialog,
                              _t('Siguiente Capítulo', 'Next Chapter'),
                              _t('Pasa automáticamente al siguiente',
                                  'Automatically moves to the next'),
                              _autoNextChapter,
                              (value) {
                                setStateDialog(() {
                                  _autoNextChapter = value;
                                  if (value) _repeatChapter = false;
                                });
                                setState(() {
                                  _autoNextChapter = value;
                                  if (value) _repeatChapter = false;
                                });
                                _saveAudioPreferences();
                              },
                              Icons.skip_next,
                            ),
                            const SizedBox(height: 16),
                            _buildPauseDurationSlider(setStateDialog),
                            const SizedBox(height: 16),
                            _buildSpeedSlider(setStateDialog),
                            const SizedBox(height: 16),
                            _buildPitchSlider(setStateDialog),
                            const SizedBox(height: 16),
                            _buildVoiceSelector(setStateDialog),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _testVoiceConfiguration,
                                icon: const Icon(Icons.volume_up, size: 18),
                                label: Text(_t('Probar configuración',
                                    'Test configuration')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF637983),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfigSwitch(
    StateSetter setStateDialog,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF637983).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF637983).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF637983), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF637983),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF637983),
            activeTrackColor: const Color(0xFF637983).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildPauseDurationSlider(StateSetter setStateDialog) {
    return _buildSliderCard(
      icon: Icons.timer,
      title: _t('Pausa entre capítulos', 'Pause between chapters'),
      valueLabel: '${_pauseDuration}s',
      child: Column(
        children: [
          Slider(
            value: _pauseDuration.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '${_pauseDuration}s',
            onChanged: (value) {
              setStateDialog(() => _pauseDuration = value.round());
              setState(() => _pauseDuration = value.round());
              _saveAudioPreferences();
            },
            activeColor: const Color(0xFF637983),
            inactiveColor: Colors.grey.shade300,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1s',
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
              Text('4s',
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
              Text('8s',
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSlider(StateSetter setStateDialog) {
    return _buildSliderCard(
      icon: Icons.speed,
      title: _t('Velocidad de lectura', 'Reading speed'),
      valueLabel: '${(_speechRate * 100).round()}%',
      child: Column(
        children: [
          Slider(
            value: _speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            label: '${(_speechRate * 100).round()}%',
            onChanged: (value) {
              setStateDialog(() => _speechRate = value);
              setState(() => _speechRate = value);
              _saveAudioPreferences();
            },
            activeColor: const Color(0xFF637983),
            inactiveColor: Colors.grey.shade300,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('Lento', 'Slow'),
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
              Text(_t('Normal', 'Normal'),
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
              Text(_t('Rápido', 'Fast'),
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPitchSlider(StateSetter setStateDialog) {
    return _buildSliderCard(
      icon: Icons.tune,
      title: _t('Tono de voz', 'Voice pitch'),
      valueLabel: '${(_pitch * 100).round()}%',
      child: Column(
        children: [
          Slider(
            value: _pitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: '${(_pitch * 100).round()}%',
            onChanged: (value) {
              setStateDialog(() => _pitch = value);
              setState(() => _pitch = value);
              _saveAudioPreferences();
            },
            activeColor: const Color(0xFF637983),
            inactiveColor: Colors.grey.shade300,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('Grave', 'Low'),
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
              Text(_t('Normal', 'Normal'),
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
              Text(_t('Agudo', 'High'),
                  style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required IconData icon,
    required String title,
    required String valueLabel,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF637983).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF637983), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF637983),
                ),
              ),
              const Spacer(),
              Text(
                valueLabel,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF637983),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  // ========================================
  // SELECTOR DE VOCES
  // ========================================
  Widget _buildVoiceSelector(StateSetter setStateDialog) {
    final List<DropdownMenuItem<String>> items = [];

    items.add(
      DropdownMenuItem<String>(
        value: '__default__',
        child: Row(
          children: [
            const Text('🌐', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              _t('Voz predeterminada del sistema', 'System default voice'),
              style: const TextStyle(
                fontFamily: 'Sansation',
                color: Color(0xFF637983),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    final vocesEspanol = _availableVoices
        .where((v) => VoiceHelper.getLanguageLabel(v) == 'Español')
        .toList();
    final vocesIngles = _availableVoices
        .where((v) => VoiceHelper.getLanguageLabel(v) == 'Inglés')
        .toList();

    if (vocesEspanol.isNotEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          value: '__header_es__',
          enabled: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '─── ESPAÑOL ───',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF637983),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );
      for (final v in vocesEspanol) {
        final name = v['name'] ?? '';
        items.add(
          DropdownMenuItem<String>(
            value: name,
            child: Text(
              VoiceHelper.formatForDisplay(v),
              style: const TextStyle(
                fontFamily: 'Sansation',
                fontSize: 13,
                color: Color(0xFF637983),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    if (vocesIngles.isNotEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          value: '__header_en__',
          enabled: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '─── INGLÉS ───',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF637983),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );
      for (final v in vocesIngles) {
        final name = v['name'] ?? '';
        items.add(
          DropdownMenuItem<String>(
            value: name,
            child: Text(
              VoiceHelper.formatForDisplay(v),
              style: const TextStyle(
                fontFamily: 'Sansation',
                fontSize: 13,
                color: Color(0xFF637983),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    String currentValue = '__default__';
    if (_selectedVoice != null && _selectedVoice!['name'] != null) {
      final name = _selectedVoice!['name']!;
      final exists = _availableVoices.any((v) => v['name'] == name);
      if (exists) currentValue = name;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF637983).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over,
                  color: Color(0xFF637983), size: 20),
              const SizedBox(width: 8),
              Text(
                _t('Seleccionar voz', 'Select voice'),
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF637983),
                ),
              ),
              const Spacer(),
              if (!_voicesLoaded)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF637983),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF637983).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_availableVoices.length} ${_t('voces', 'voices')}',
                    style: const TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF637983),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFF637983)),
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  color: Color(0xFF637983),
                  fontSize: 13,
                ),
                items: items,
                onChanged: (value) {
                  if (value == null ||
                      value == '__default__' ||
                      value.startsWith('__header_')) {
                    setStateDialog(() => _selectedVoice = null);
                    setState(() => _selectedVoice = null);
                    _saveAudioPreferences();
                    return;
                  }

                  Map<String, String>? selectedVoice;
                  for (var voice in _availableVoices) {
                    if (voice['name'] == value) {
                      selectedVoice = voice;
                      break;
                    }
                  }

                  setStateDialog(() => _selectedVoice = selectedVoice);
                  setState(() => _selectedVoice = selectedVoice);
                  _saveAudioPreferences();
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF637983).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: Color(0xFF637983)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _t(
                      'Solo se muestran voces en español e inglés. Si no ves tu idioma, usa la voz predeterminada.',
                      'Only Spanish and English voices are shown. If you don\'t see your language, use the default voice.',
                    ),
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testVoiceConfiguration() async {
    final testText = _t(
        'Prueba de configuración de voz.', 'Voice configuration test.');
    await _flutterTts.stop();
    await _flutterTts.speak(testText);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('🔊 Probando configuración de audio...',
              '🔊 Testing audio configuration...')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ========================================
  // DISPOSE
  // ========================================
  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  // ========================================
  // BUILD
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _t('Biblia', 'Bible'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'OleoScript',
                fontWeight: FontWeight.normal,
                color: AppTheme.color4,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 1),
            Text(
              _isEnglish ? 'King James Version' : 'Reina-Valera 1960',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Sansation',
                fontWeight: FontWeight.normal,
                color: AppTheme.color4.withValues(alpha: 0.85),
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        elevation: 0,
        toolbarHeight: 68,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                'assets/icons/menu.png',
                width: 24,
                height: 24,
                color: AppTheme.color4,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.menu, color: Colors.white);
                },
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (cargandoBooks) const LinearProgressIndicator(),
              if (cargandoBooks) const SizedBox(height: 20),

              // ========== BARRA DE BOTONES PRINCIPAL ==========
              Row(
                children: [
                  // 1. Libro (con texto)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _mostrarDialogoLibros,
                      icon: const Icon(Icons.book, size: 18),
                      label: Text(_t('Lib', 'Bk')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF637983),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 2. Capítulo (con texto)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _mostrarDialogoCapitulos,
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: Text(_t('Cap', 'Ch')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF637983),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.search,
                    tooltip: _t('Buscador', 'Search'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BuscadorBibliaScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.language,
                    tooltip: _t('Cambiar idioma', 'Change language'),
                    onTap: _mostrarDialogoIdioma,
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.bookmark,
                    tooltip: _t('Versículos guardados', 'Saved verses'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VersiculosGuardadosScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.text_fields,
                    tooltip: _t('Tamaño de letra', 'Font size'),
                    onTap: _mostrarDialogoTamanoFuente,
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.volume_up,
                    tooltip: _t('Audio', 'Audio'),
                    onTap: () =>
                        setState(() => showAudioPanel = !showAudioPanel),
                    isActive: showAudioPanel,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // PANEL DE AUDIO
              if (showAudioPanel) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF637983), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (isSpeaking && !isPaused)
                              ? null
                              : _speakChapter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaused
                                ? Colors.orange
                                : const Color(0xFF637983),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          child: const Icon(Icons.play_arrow, size: 20),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (isSpeaking && !isPaused) ? _pauseSpeaking : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isSpeaking && !isPaused)
                                ? const Color(0xFF637983)
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          child: const Icon(Icons.pause, size: 20),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (verses.isNotEmpty && currentVerseIndex > 0)
                                  ? _goToPreviousVerse
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF637983),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              verses.isNotEmpty ? _showVerseSelector : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF637983),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          child: Text(
                            currentVerseIndex >= 0
                                ? '${currentVerseIndex + 1}/${verses.length}'
                                : '0/${verses.length}',
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (verses.isNotEmpty &&
                                  currentVerseIndex < verses.length - 1)
                              ? _goToNextVerse
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF637983),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          child: const Icon(Icons.arrow_forward, size: 20),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (isSpeaking || isPaused) ? _stopSpeaking : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isSpeaking || isPaused)
                                ? const Color(0xFF637983)
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          child: const Icon(Icons.stop, size: 20),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showAudioConfigDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF637983),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.settings, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (cargandoVerses) const LinearProgressIndicator(),
              const SizedBox(height: 8),

              // VERSÍCULO DEL DÍA
              if (selectedBook == null &&
                  randomVerse != null &&
                  randomCitation != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFF637983), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _t('Versículo del día', 'Verse of the day'),
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF637983),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        randomCitation!,
                        style: const TextStyle(
                          fontFamily: 'Sansation',
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF637983),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        randomVerse!.text,
                        style: TextStyle(
                          fontFamily: 'Sansation',
                          fontSize: fontSize - 2,
                          color: const Color(0xFF192E2F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ========================================
              // ✅ ÚLTIMAS LECTURAS (SIN SCROLL, CON WRAP)
              // ========================================
              if (_ultimasLecturas.isNotEmpty && selectedBook == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF637983).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ----- HEADER -----
                      Row(
                        children: [
                          const Icon(Icons.history,
                              color: Color(0xFF637983), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _t('Últimas lecturas', 'Recent readings'),
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF637983),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_ultimasLecturas.length} ${_t('de', 'of')} 5',
                            style: TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () async {
                              final confirmar = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFFEAE4D5),
                                  title: Text(
                                    _t('Limpiar historial', 'Clear history'),
                                    style: const TextStyle(
                                      fontFamily: 'Sansation',
                                      color: Color(0xFF637983),
                                    ),
                                  ),
                                  content: Text(
                                    _t(
                                      '¿Deseas borrar todas las últimas lecturas?',
                                      'Do you want to clear all recent readings?',
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Sansation',
                                      color: Color(0xFF637983),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(
                                        _t('Cancelar', 'Cancel'),
                                        style: const TextStyle(
                                          fontFamily: 'Sansation',
                                          color: Color(0xFF637983),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF637983),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        _t('Borrar', 'Clear'),
                                        style: const TextStyle(
                                            fontFamily: 'Sansation'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmar == true) {
                                await VersiculosGuardadosService
                                    .limpiarUltimasLecturas();
                                await _loadLastRead();
                              }
                            },
                            child: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Color(0xFF637983),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ----- TARJETAS EN WRAP (se ajusta en varias filas) -----
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _ultimasLecturas.map((lectura) {
                          final libro = _safeString(lectura['libro']);
                          final cap = _safeInt(lectura['capitulo']);
                          final ver = _safeInt(lectura['versiculo']);
                          final idiomaLectura = _safeString(
                              lectura['idioma'],
                              fallback: 'es');
                          final bool esOtroIdioma =
                              idiomaLectura != _currentLanguage;
                          final bool esIngles = idiomaLectura == 'en';

                          // 🎨 Colores según paleta personalizada
                          final Color colorBadgeBg = esIngles
                              ? const Color(0xFFCD977B).withValues(alpha: 0.25)
                              : const Color(0xFFB87856).withValues(alpha: 0.25);
                          final Color colorBadgeText = esIngles
                              ? const Color(0xFFCD977B)
                              : const Color(0xFFB87856);

                          return GestureDetector(
                            onTap: () => _abrirUltimaLectura(
                              libro,
                              cap,
                              ver,
                              idioma: idiomaLectura,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                                border: esOtroIdioma
                                    ? Border.all(
                                        color: const Color(0xFFA2B0BE),
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 100),
                                        child: Text(
                                          libro,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Sansation',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF637983),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: colorBadgeBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          esIngles ? 'EN' : 'ES',
                                          style: TextStyle(
                                            fontFamily: 'Sansation',
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: colorBadgeText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_t('Cap.', 'Ch.')} $cap · v.$ver',
                                    style: TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // LISTA DE VERSÍCULOS
              Expanded(
                child: verses.isEmpty &&
                        !cargandoVerses &&
                        selectedBook != null &&
                        maxChapters > 0
                    ? Center(
                        child: Text(
                          _t('No hay versículos para mostrar.',
                              'No verses to display.'),
                          style: const TextStyle(fontFamily: 'Sansation'),
                        ),
                      )
                    : verses.isEmpty && selectedBook == null
                        ? Center(
                            child: Text(
                              _t(
                                  'Seleccione un libro para ver versículos.',
                                  'Select a book to see verses.'),
                              style: const TextStyle(fontFamily: 'Sansation'),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: verses.length,
                              itemBuilder: (context, index) {
                                final verse = verses[index];
                                final bool isCurrentVerse =
                                    currentVerseIndex == index;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrentVerse
                                        ? const Color(0xFF637983)
                                            .withValues(alpha: 0.10)
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (verses.isNotEmpty) {
                                        _selectVerse(verse.verse);
                                      }
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isCurrentVerse
                                                    ? const Color(0xFF637983)
                                                    : const Color(0xFF637983)
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                verse.verse.toString(),
                                                style: TextStyle(
                                                  fontFamily: 'Sansation',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isCurrentVerse
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF637983),
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            _buildMenuTresPuntos(
                                                verse, index, isCurrentVerse),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          verse.text,
                                          style: TextStyle(
                                            fontFamily: 'Sansation',
                                            fontSize: fontSize,
                                            height: 1.6,
                                            fontWeight: isCurrentVerse
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isCurrentVerse
                                                ? const Color(0xFF637983)
                                                : const Color(0xFF192E2F),
                                          ),
                                        ),
                                        if (isCurrentVerse) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                isPaused
                                                    ? Icons.pause
                                                    : Icons.volume_up,
                                                size: 14,
                                                color: const Color(0xFF637983),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isPaused
                                                    ? _t('Pausado', 'Paused')
                                                    : _t('Reproduciendo',
                                                        'Playing'),
                                                style: const TextStyle(
                                                  fontFamily: 'Sansation',
                                                  fontSize: 11,
                                                  color: Color(0xFF637983),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // WIDGET: BOTÓN DE ICONO
  // ========================================
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? const Color(0xFF637983) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF637983) : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF637983),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}