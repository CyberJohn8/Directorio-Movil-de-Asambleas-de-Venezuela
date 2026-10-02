// lib/screens/criptograma/cryptogram_game.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/game_state.dart';
import 'services/cryptogram_service.dart';
import '../../services/biblia_service.dart';
import '../../models/biblia.dart';
import '../../utils/theme.dart';

class CryptogramGame extends StatefulWidget {
  const CryptogramGame({super.key});

  @override
  State<CryptogramGame> createState() => _CryptogramGameState();
}

class _CryptogramGameState extends State<CryptogramGame> {
  late CryptogramService _cryptogramService;
  GameState? _gameState;
  String? _currentVerseInfo;
  String? _currentVerseText;
  bool _isLoading = true;
  
  int? _selectedPosition;
  String _selectedLetter = '';
  Difficulty _selectedDifficulty = Difficulty.medium;
  
  List<BibliaBook> _books = [];
  bool _booksLoaded = false;
  
  // ========== CRONÓMETRO ==========
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _elapsedSeconds = 0;
  static const int maxTimeSeconds = 240; // 4 minutos
  
  // ========== SISTEMA DE PENALIZACIÓN ==========
  int _penaltyPoints = 0;
  int _lastPenaltySecond = 0;
  bool _isPenaltyActive = false;
  
  // ========== MEJORES PUNTAJES ==========
  Map<String, int> _highScores = {};
  static const String _keyHighScores = 'cryptogram_high_scores';
  
  // ========== NUEVA CLAVE PARA GUARDAR ESTADO DE RONDA COMPLETADA ==========
  static const String _keyRoundCompleted = 'round_completed';
  
  final List<String> _keyboardLetters = const [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];
  
  final List<String> _usedVersesHistory = [];
  static const int maxHistorySize = 10;
  
  static const String _keyHasSavedGame = 'has_saved_game';
  static const String _keyGameState = 'game_state_json';
  static const String _keyCurrentVerseInfo = 'current_verse_info';
  static const String _keyCurrentVerseText = 'current_verse_text';
  static const String _keyUsedVersesHistory = 'used_verses_history';
  static const String _keySelectedDifficulty = 'selected_difficulty';
  static const String _keySelectedPosition = 'selected_position';
  static const String _keySelectedLetter = 'selected_letter';

  static const Color buttonColor = Color(0xFF637983);
  static const Color lightBrownColor = Color(0xFFCD977B);
  static const Color lightGrayColor = Color(0xFFEEEFF1);
  static const Color dialogBackgroundColor = Color(0xFFEAE4D5);

  // ========== FUNCIÓN PARA LIMPIAR TEXTO ==========
  String _cleanText(String text) {
    if (text.isEmpty) return text;
    
    String cleaned = text
        .replaceAll(RegExp(r'\n'), ' ')
        .replaceAll(RegExp(r'\r'), ' ')
        .replaceAll(RegExp(r'\t'), ' ')
        .replaceAll('_', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    return cleaned;
  }

  @override
  void initState() {
    super.initState();
    _cryptogramService = CryptogramService();
    _loadHighScores();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooksAndCheckGame();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ========== MÉTODOS DE MEJORES PUNTAJES ==========
  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_keyHighScores);
    if (scoresJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(scoresJson);
        _highScores = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        _highScores = {};
      }
    } else {
      _highScores = {
        'Fácil': 0,
        'Media': 0,
        'Difícil': 0,
        'Extrema': 0,
      };
    }
  }

  Future<void> _saveHighScore(Difficulty difficulty, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final difficultyName = _getDifficultyName(difficulty);
    
    if (_highScores.containsKey(difficultyName)) {
      if (score > _highScores[difficultyName]!) {
        _highScores[difficultyName] = score;
      }
    } else {
      _highScores[difficultyName] = score;
    }
    
    await prefs.setString(_keyHighScores, jsonEncode(_highScores));
  }

  int _getHighScore(Difficulty difficulty) {
    final difficultyName = _getDifficultyName(difficulty);
    return _highScores[difficultyName] ?? 0;
  }

  // ========== MÉTODOS DEL CRONÓMETRO CON PENALIZACIÓN ==========
  
  /// Obtiene el tiempo límite antes de comenzar la penalización según la dificultad
  int _getPenaltyStartTime() {
    switch (_gameState?.difficulty ?? Difficulty.medium) {
      case Difficulty.easy:
        return 999999; // Sin penalización
      case Difficulty.medium:
        return 999999; // Sin penalización
      case Difficulty.hard:
        return 180; // 3 minutos
      case Difficulty.extreme:
        return 120; // 2 minutos
    }
  }
  
  /// Calcula los puntos de penalización según el tiempo excedido
  int _calculatePenalty(int elapsedSeconds) {
    final penaltyStart = _getPenaltyStartTime();
    if (elapsedSeconds <= penaltyStart) return 0;
    
    final excessTime = elapsedSeconds - penaltyStart;
    // 1 punto por cada 3 segundos excedidos
    return (excessTime / 3).floor();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();
    _elapsedSeconds = 0;
    _penaltyPoints = 0;
    _lastPenaltySecond = 0;
    _isPenaltyActive = false;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = _stopwatch.elapsed.inSeconds;
          
          // Verificar penalización
          final penaltyStart = _getPenaltyStartTime();
          if (_elapsedSeconds > penaltyStart) {
            _isPenaltyActive = true;
            final newPenalty = _calculatePenalty(_elapsedSeconds);
            if (newPenalty > _penaltyPoints) {
              _penaltyPoints = newPenalty;
            }
          }
        });
      }
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void _resetTimer() {
    _stopTimer();
    _elapsedSeconds = 0;
    _penaltyPoints = 0;
    _lastPenaltySecond = 0;
    _isPenaltyActive = false;
    _stopwatch.reset();
  }

  int _getTimeBonus() {
    if (_elapsedSeconds >= maxTimeSeconds) {
      return 0;
    }
    final remainingTime = maxTimeSeconds - _elapsedSeconds;
    final bonus = (remainingTime / maxTimeSeconds * 200).round();
    return bonus.clamp(0, 200);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ========== FIN MÉTODOS CRONÓMETRO ==========

  Future<void> _loadBooksAndCheckGame() async {
    try {
      _books = await BibliaService.getBooks();
      _booksLoaded = true;
      
      if (kDebugMode) {
        debugPrint('✅ ${_books.length} libros cargados para el criptograma');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final hasSavedGame = prefs.getBool(_keyHasSavedGame) ?? false;
      
      if (hasSavedGame) {
        _showContinueDialog();
      } else {
        _showDifficultyDialog();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando libros: $e');
      }
      _showErrorDialog('Error al cargar los libros de la Biblia: $e');
    }
  }

  Future<void> _saveGame() async {
    if (_gameState == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si la ronda está completa
    final bool isComplete = _isRoundComplete();
    
    final gameStateMap = {
      'originalText': _gameState!.originalText,
      'cleanText': _gameState!.cleanText,
      'currentGuess': _gameState!.currentGuess,
      'lives': _gameState!.lives,
      'score': _gameState!.score,
      'currentRound': _gameState!.currentRound,
      'isGameOver': _gameState!.isGameOver,
      'revealedLetters': _gameState!.revealedLetters.toList(),
      'difficulty': _gameState!.difficulty.index,
      'encryptionMap': _gameState!.encryptionMap,
      'penaltyPoints': _penaltyPoints,
      'elapsedSeconds': _elapsedSeconds,
    };
    
    final gameStateJson = jsonEncode(gameStateMap);
    
    await prefs.setString(_keyGameState, gameStateJson);
    await prefs.setString(_keyCurrentVerseInfo, _currentVerseInfo ?? '');
    await prefs.setString(_keyCurrentVerseText, _currentVerseText ?? '');
    await prefs.setStringList(_keyUsedVersesHistory, _usedVersesHistory);
    await prefs.setInt(_keySelectedDifficulty, _selectedDifficulty.index);
    await prefs.setInt(_keySelectedPosition, _selectedPosition ?? -1);
    await prefs.setString(_keySelectedLetter, _selectedLetter);
    await prefs.setBool(_keyHasSavedGame, true);
    await prefs.setBool(_keyRoundCompleted, isComplete); // Guardar estado de completado
    
    debugPrint('Juego guardado correctamente - Ronda completada: $isComplete');
  }

  Future<void> _loadGame() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final gameStateJson = prefs.getString(_keyGameState);
      _currentVerseInfo = prefs.getString(_keyCurrentVerseInfo) ?? '';
      _currentVerseText = prefs.getString(_keyCurrentVerseText) ?? '';
      _usedVersesHistory.addAll(prefs.getStringList(_keyUsedVersesHistory) ?? []);
      _selectedDifficulty = Difficulty.values[prefs.getInt(_keySelectedDifficulty) ?? 1];
      _selectedPosition = prefs.getInt(_keySelectedPosition);
      if (_selectedPosition == -1) _selectedPosition = null;
      _selectedLetter = prefs.getString(_keySelectedLetter) ?? '';
      
      // Verificar si la ronda estaba completada
      final bool roundWasCompleted = prefs.getBool(_keyRoundCompleted) ?? false;
      
      if (gameStateJson != null) {
        final Map<String, dynamic> data = jsonDecode(gameStateJson);
        
        Map<String, int> encryptionMap = {};
        if (data['encryptionMap'] != null) {
          encryptionMap = Map<String, int>.from(data['encryptionMap']);
        }
        
        _gameState = GameState(
          originalText: data['originalText'],
          cleanText: data['cleanText'],
          currentGuess: List<String>.from(data['currentGuess']),
          lives: data['lives'],
          score: data['score'],
          currentRound: data['currentRound'],
          isGameOver: data['isGameOver'],
          revealedLetters: Set<String>.from(data['revealedLetters']),
          difficulty: Difficulty.values[data['difficulty']],
          encryptionMap: encryptionMap,
        );
        
        // Cargar penalización si existe
        if (data.containsKey('penaltyPoints')) {
          _penaltyPoints = data['penaltyPoints'] ?? 0;
        }
        if (data.containsKey('elapsedSeconds')) {
          _elapsedSeconds = data['elapsedSeconds'] ?? 0;
        }
        
        setState(() {
          _isLoading = false;
        });
        
        // ========== VERIFICAR SI LA RONDA YA ESTÁ COMPLETADA ==========
        if (roundWasCompleted || _isRoundComplete()) {
          debugPrint('🔄 Ronda ya completada, avanzando automáticamente...');
          // Limpiar el estado de ronda completada antes de avanzar
          await prefs.remove(_keyRoundCompleted);
          // Avanzar a la siguiente ronda automáticamente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _goToNextRound();
            }
          });
          return;
        }
        
        // Reiniciar timer al cargar juego guardado
        _resetTimer();
        _startTimer();
        
        debugPrint('Juego cargado correctamente - Ronda: ${_gameState!.currentRound}, Puntos: ${_gameState!.score}');
      } else {
        await _startNewGame();
      }
    } catch (e) {
      debugPrint('Error al cargar el juego: $e');
      await _clearSavedGame();
      await _startNewGame();
    }
  }

  void _showContinueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: dialogBackgroundColor,
          title: const Text(
            'Partida Guardada',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'Tienes una partida en progreso. ¿Deseas continuar desde donde la dejaste o comenzar una nueva?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _loadGame();
              },
              child: const Text('Continuar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _clearSavedGame();
                _showDifficultyDialog();
              },
              child: const Text('Nueva Partida'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasSavedGame);
    await prefs.remove(_keyGameState);
    await prefs.remove(_keyCurrentVerseInfo);
    await prefs.remove(_keyCurrentVerseText);
    await prefs.remove(_keyUsedVersesHistory);
    await prefs.remove(_keySelectedDifficulty);
    await prefs.remove(_keySelectedPosition);
    await prefs.remove(_keySelectedLetter);
    await prefs.remove(_keyRoundCompleted);
    debugPrint('Partida guardada eliminada');
  }

  bool _isLetterFullyRevealed(String letter) {
    if (_gameState == null) return false;
    
    for (int i = 0; i < _gameState!.cleanText.length; i++) {
      final char = _gameState!.cleanText[i];
      if (char == letter && _gameState!.currentGuess[i] == '?') {
        return false;
      }
    }
    return true;
  }

  // ========== VERIFICAR SI LA RONDA ESTÁ COMPLETA ==========
  bool _isRoundComplete() {
    if (_gameState == null) return false;
    
    for (int i = 0; i < _gameState!.cleanText.length; i++) {
      final char = _gameState!.cleanText[i];
      final RegExp letterRegex = RegExp(r'[A-ZÑ]');
      if (letterRegex.hasMatch(char) && _gameState!.currentGuess[i] == '?') {
        return false;
      }
    }
    return true;
  }

  Future<Map<String, dynamic>?> _getUniqueRandomVerse() async {
    if (!_booksLoaded || _books.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ No hay libros cargados');
      }
      return null;
    }
    
    int attempts = 0;
    const maxAttempts = 30;
    
    while (attempts < maxAttempts) {
      try {
        final random = Random();
        final book = _books[random.nextInt(_books.length)];
        final chapter = random.nextInt(book.chapters) + 1;
        final verses = await BibliaService.getChapter(book, chapter);
        
        if (verses.isNotEmpty) {
          final verse = verses[random.nextInt(verses.length)];
          final verseKey = '${book.shortTitle}|$chapter|${verse.verse}';
          
          if (!_usedVersesHistory.contains(verseKey) || _usedVersesHistory.length >= maxHistorySize) {
            _usedVersesHistory.add(verseKey);
            if (_usedVersesHistory.length > maxHistorySize) {
              _usedVersesHistory.removeAt(0);
            }
            
            return {
              'book_name': book.shortTitle,
              'chapter': chapter,
              'verse_num': verse.verse,
              'text': _cleanText(verse.text),
            };
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error obteniendo versículo: $e');
        }
      }
      attempts++;
    }
    
    // Fallback: obtener cualquier versículo
    try {
      final random = Random();
      final book = _books[random.nextInt(_books.length)];
      final chapter = random.nextInt(book.chapters) + 1;
      final verses = await BibliaService.getChapter(book, chapter);
      
      if (verses.isNotEmpty) {
        final verse = verses[random.nextInt(verses.length)];
        return {
          'book_name': book.shortTitle,
          'chapter': chapter,
          'verse_num': verse.verse,
          'text': _cleanText(verse.text),
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error en fallback de versículo: $e');
      }
    }
    
    return null;
  }

  Future<void> _startNewGame() async {
    setState(() => _isLoading = true);
    _usedVersesHistory.clear();
    await _clearSavedGame();
    _resetTimer();
    _penaltyPoints = 0;
    
    try {
      final verseData = await _getUniqueRandomVerse();
      if (verseData != null && mounted) {
        _currentVerseInfo = '${verseData['book_name']} ${verseData['chapter']}:${verseData['verse_num']}';
        _currentVerseText = verseData['text'];
        
        String cleanText = verseData['text']
            .toUpperCase()
            .replaceAll('Á', 'A')
            .replaceAll('É', 'E')
            .replaceAll('Í', 'I')
            .replaceAll('Ó', 'O')
            .replaceAll('Ú', 'U')
            .replaceAll('Ü', 'U');
        
        setState(() {
          _gameState = _cryptogramService.initializeGame(
            cleanText, 
            _selectedDifficulty
          );
          
          _revealPunctuationMarks();
          _revealInitialLetters();
          
          _selectedPosition = null;
          _selectedLetter = '';
          _isLoading = false;
        });
        
        _startTimer();
        await _saveGame();
      } else {
        _showErrorDialog('No se pudieron cargar los versículos');
      }
    } catch (e) {
      _showErrorDialog('Error al cargar el juego: $e');
    }
  }

  void _revealInitialLetters() {
    if (_gameState == null) return;
    
    int totalLetters = _gameState!.cleanText.replaceAll(' ', '').length;
    double revealPercentage = 0;
    
    switch (_gameState!.difficulty) {
      case Difficulty.easy:
        revealPercentage = 0.30;
        break;
      case Difficulty.medium:
        revealPercentage = 0.15;
        break;
      case Difficulty.hard:
        revealPercentage = 0.05;
        break;
      case Difficulty.extreme:
        revealPercentage = 0.00;
        break;
    }
    
    int lettersToReveal = (totalLetters * revealPercentage).round();
    
    switch (_gameState!.difficulty) {
      case Difficulty.easy:
        lettersToReveal = lettersToReveal.clamp(1, 8);
        break;
      case Difficulty.medium:
        lettersToReveal = lettersToReveal.clamp(1, 4);
        break;
      case Difficulty.hard:
        lettersToReveal = lettersToReveal.clamp(0, 2);
        break;
      case Difficulty.extreme:
        lettersToReveal = 0;
        break;
    }
    
    if (lettersToReveal == 0) return;
    
    Set<String> availableLetters = {};
    for (int i = 0; i < _gameState!.cleanText.length; i++) {
      final char = _gameState!.cleanText[i];
      final RegExp letterRegex = RegExp(r'[A-ZÑ]');
      if (letterRegex.hasMatch(char) && 
          _gameState!.currentGuess[i] == '?' &&
          !_gameState!.revealedLetters.contains(char)) {
        availableLetters.add(char);
      }
    }
    
    List<String> lettersList = availableLetters.toList();
    lettersList.shuffle(Random());
    
    int revealedCount = 0;
    for (String letter in lettersList) {
      if (revealedCount >= lettersToReveal) break;
      
      if (_gameState!.difficulty == Difficulty.easy) {
        List<String> newGuess = List.from(_gameState!.currentGuess);
        for (int i = 0; i < _gameState!.cleanText.length; i++) {
          if (_gameState!.cleanText[i] == letter && newGuess[i] == '?') {
            newGuess[i] = letter;
          }
        }
        
        Set<String> newRevealedLetters = Set.from(_gameState!.revealedLetters);
        newRevealedLetters.add(letter);
        
        _gameState = _gameState!.copyWith(
          currentGuess: newGuess,
          revealedLetters: newRevealedLetters,
        );
      } else {
        for (int i = 0; i < _gameState!.cleanText.length; i++) {
          if (_gameState!.cleanText[i] == letter && _gameState!.currentGuess[i] == '?') {
            List<String> newGuess = List.from(_gameState!.currentGuess);
            newGuess[i] = letter;
            
            Set<String> newRevealedLetters = Set.from(_gameState!.revealedLetters);
            newRevealedLetters.add(letter);
            
            _gameState = _gameState!.copyWith(
              currentGuess: newGuess,
              revealedLetters: newRevealedLetters,
            );
            break;
          }
        }
      }
      
      revealedCount++;
    }
  }

  void _showHintDialog() {
    if (_gameState == null) return;
    
    const int hintCost = 100;
    
    if (_gameState!.score < hintCost) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: dialogBackgroundColor.withValues(alpha: 0.95),
          title: const Text(
            'Puntos Insuficientes',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Necesitas $hintCost puntos para comprar una pista.\n'
            'Tienes ${_gameState!.score} puntos.',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor.withValues(alpha: 0.95),
        title: const Text(
          'Comprar Pista',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres gastar $hintCost puntos por una pista?\n\n'
          'Puntos actuales: ${_gameState!.score}\n'
          'Puntos después: ${_gameState!.score - hintCost}',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeHint();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }

  void _executeHint() {
    if (_gameState == null) return;
    
    const int hintCost = 100;
    
    List<String> unrevealedLetters = [];
    for (int i = 0; i < _gameState!.cleanText.length; i++) {
      final char = _gameState!.cleanText[i];
      final RegExp letterRegex = RegExp(r'[A-ZÑ]');
      if (letterRegex.hasMatch(char) && 
          _gameState!.currentGuess[i] == '?' &&
          !unrevealedLetters.contains(char)) {
        unrevealedLetters.add(char);
      }
    }
    
    if (unrevealedLetters.isEmpty) {
      _showMessage('No hay más letras por revelar');
      return;
    }
    
    final random = Random();
    String letterToReveal = unrevealedLetters[random.nextInt(unrevealedLetters.length)];
    
    setState(() {
      if (_gameState!.difficulty == Difficulty.easy) {
        List<String> newGuess = List.from(_gameState!.currentGuess);
        for (int i = 0; i < _gameState!.cleanText.length; i++) {
          if (_gameState!.cleanText[i] == letterToReveal && newGuess[i] == '?') {
            newGuess[i] = letterToReveal;
          }
        }
        
        Set<String> newRevealedLetters = Set.from(_gameState!.revealedLetters);
        newRevealedLetters.add(letterToReveal);
        
        _gameState = _gameState!.copyWith(
          currentGuess: newGuess,
          revealedLetters: newRevealedLetters,
          score: _gameState!.score - hintCost,
        );
      } else {
        for (int i = 0; i < _gameState!.cleanText.length; i++) {
          if (_gameState!.cleanText[i] == letterToReveal && _gameState!.currentGuess[i] == '?') {
            List<String> newGuess = List.from(_gameState!.currentGuess);
            newGuess[i] = letterToReveal;
            
            Set<String> newRevealedLetters = Set.from(_gameState!.revealedLetters);
            newRevealedLetters.add(letterToReveal);
            
            _gameState = _gameState!.copyWith(
              currentGuess: newGuess,
              revealedLetters: newRevealedLetters,
              score: _gameState!.score - hintCost,
            );
            break;
          }
        }
      }
      
      _saveGame();
      _showMessage('Letra "$letterToReveal" revelada. -$hintCost puntos');
      
      if (_isRoundComplete()) {
        _showRoundCompleteDialog();
      }
    });
  }

  void _revealPunctuationMarks() {
    if (_gameState == null) return;
    
    final RegExp nonLetterRegex = RegExp(r'[^A-ZÑÁÉÍÓÚ]');
    
    List<String> newGuess = List.from(_gameState!.currentGuess);
    bool changesMade = false;
    
    for (int i = 0; i < _gameState!.cleanText.length; i++) {
      final char = _gameState!.cleanText[i];
      
      if (nonLetterRegex.hasMatch(char) && char != ' ') {
        if (newGuess[i] == '?') {
          newGuess[i] = char;
          changesMade = true;
        }
      }
    }
    
    if (changesMade) {
      _gameState = _gameState!.copyWith(currentGuess: newGuess);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedPosition = null;
      _selectedLetter = '';
    });
    _showMessage('Selección limpiada');
    _saveGame();
  }

  // ========== MÉTODO MEJORADO PARA SIGUIENTE RONDA ==========
  Future<void> _goToNextRound() async {
    setState(() => _isLoading = true);
    _resetTimer();
    _penaltyPoints = 0;
    _isPenaltyActive = false;
    
    // Limpiar el estado de ronda completada
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRoundCompleted);
    
    try {
      final verseData = await _getUniqueRandomVerse();
      if (verseData != null && _gameState != null && mounted) {
        _currentVerseInfo = '${verseData['book_name']} ${verseData['chapter']}:${verseData['verse_num']}';
        _currentVerseText = verseData['text'];
        
        String cleanText = verseData['text']
            .toUpperCase()
            .replaceAll('Á', 'A')
            .replaceAll('É', 'E')
            .replaceAll('Í', 'I')
            .replaceAll('Ó', 'O')
            .replaceAll('Ú', 'U')
            .replaceAll('Ü', 'U');
        
        setState(() {
          _gameState = _cryptogramService.nextRound(_gameState!, cleanText);
          
          _revealPunctuationMarks();
          _revealInitialLetters();
          
          _selectedPosition = null;
          _selectedLetter = '';
          _isLoading = false;
        });
        
        // Iniciar nuevo timer para la nueva ronda
        _startTimer();
        await _saveGame();
      } else {
        _showErrorDialog('No se pudo cargar el siguiente versículo');
      }
    } catch (e) {
      // Si hay error, reintentar automáticamente
      debugPrint('Error en _goToNextRound: $e');
      setState(() => _isLoading = false);
      _showMessage('Reintentando cargar siguiente ronda...');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _goToNextRound();
        }
      });
    }
  }

  void _guessLetterAtPosition() {
    if (_gameState == null || _selectedPosition == null || _selectedLetter.isEmpty) {
      _showMessage('Selecciona una casilla y una letra');
      return;
    }
    
    final String cleanChar = _gameState!.cleanText[_selectedPosition!];
    final String currentDisplay = _gameState!.currentGuess[_selectedPosition!];
    
    if (currentDisplay != '?') {
      _showMessage('Esta casilla ya está revelada');
      _selectedPosition = null;
      return;
    }
    
    if (cleanChar == _selectedLetter) {
      setState(() {
        int pointsEarned = 10;
        
        if (_gameState!.difficulty == Difficulty.easy) {
          int lettersToReveal = 0;
          for (int i = 0; i < _gameState!.cleanText.length; i++) {
            if (_gameState!.cleanText[i] == _selectedLetter && _gameState!.currentGuess[i] == '?') {
              lettersToReveal++;
            }
          }
          
          List<String> newGuess = List.from(_gameState!.currentGuess);
          for (int i = 0; i < _gameState!.cleanText.length; i++) {
            if (_gameState!.cleanText[i] == _selectedLetter && newGuess[i] == '?') {
              newGuess[i] = _selectedLetter;
            }
          }
          
          Set<String> newRevealedLetters = Set.from(_gameState!.revealedLetters);
          newRevealedLetters.add(_selectedLetter);
          
          pointsEarned = lettersToReveal * 10;
          
          _gameState = _gameState!.copyWith(
            currentGuess: newGuess,
            revealedLetters: newRevealedLetters,
            score: _gameState!.score + pointsEarned,
          );
        } else {
          List<String> newGuess = List.from(_gameState!.currentGuess);
          newGuess[_selectedPosition!] = _selectedLetter;
          
          Set<String> newRevealedLetters = Set.from(_gameState!.revealedLetters);
          newRevealedLetters.add(_selectedLetter);
          
          _gameState = _gameState!.copyWith(
            currentGuess: newGuess,
            revealedLetters: newRevealedLetters,
            score: _gameState!.score + pointsEarned,
          );
        }
        
        _saveGame();
        _showMessage('+$pointsEarned puntos');
        
        _selectedPosition = null;
        _selectedLetter = '';
        
        if (_isRoundComplete()) {
          _showRoundCompleteDialog();
        }
      });
    } else {
      setState(() {
        _gameState = _gameState!.copyWith(
          lives: _gameState!.lives - 1,
          isGameOver: _gameState!.lives - 1 <= 0,
        );
        _selectedPosition = null;
        _selectedLetter = '';
        
        _saveGame();
        
        if (_gameState!.isGameOver) {
          _showGameOverDialog();
        } else {
          _showMessage('Letra incorrecta. Te quedan ${_gameState!.lives} vidas');
        }
      });
    }
  }

  void _exitToPreviousScreen() {
    _saveGame();
    _stopTimer();
    Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ========== DIALOGO DE GAME OVER CON SCROLL ==========
  void _showGameOverDialog() {
    // Aplicar penalización si corresponde
    final int effectiveScore = (_gameState?.score ?? 0) - _penaltyPoints;
    int lifeBonus = (_gameState?.lives ?? 0) * 100;
    int finalScore = effectiveScore + lifeBonus;
    
    final currentDifficulty = _gameState?.difficulty ?? Difficulty.medium;
    final int highScore = _getHighScore(currentDifficulty);
    
    // Guardar el mejor puntaje
    _saveHighScore(currentDifficulty, finalScore);
    
    _stopTimer();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor.withValues(alpha: 0.95),
        title: const Text(
          '💔 Game Over',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📖 Nivel: ${_getDifficultyName(currentDifficulty)}\n'
                  '🏆 Mejor puntaje: $highScore\n'
                  '───────────────\n'
                  'Puntos por letras: ${_gameState?.score ?? 0}\n'
                  '${_penaltyPoints > 0 ? "⚠️ Penalización por tiempo: -$_penaltyPoints\n" : ""}'
                  'Bonificación por vidas (${_gameState?.lives ?? 0} x 100): +$lifeBonus\n'
                  '───────────────\n'
                  '🎯 Puntuación final: $finalScore\n'
                  '🔄 Rondas completadas: ${(_gameState?.currentRound ?? 1) - 1}',
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 12),
                const Text('📜 Versículo:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                Text(
                  _currentVerseText ?? '',
                  style: const TextStyle(color: Colors.black, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Qué deseas hacer?',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _clearSavedGame();
              _showDifficultyDialog();
            },
            child: const Text('🔄 Nuevo Juego'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _exitToPreviousScreen();
            },
            child: const Text('🚪 Salir'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  // ========== DIALOGO DE RONDA COMPLETADA CON SCROLL ==========
  void _showRoundCompleteDialog() {
    _stopTimer();
    
    // Aplicar penalización si corresponde
    final int effectiveScore = (_gameState?.score ?? 0) - _penaltyPoints;
    int timeBonus = _getTimeBonus();
    int lifeBonus = (_gameState?.lives ?? 0) * 100;
    int roundTotal = effectiveScore + lifeBonus + timeBonus;
    
    final currentDifficulty = _gameState?.difficulty ?? Difficulty.medium;
    final int highScore = _getHighScore(currentDifficulty);
    
    // Guardar el mejor puntaje
    _saveHighScore(currentDifficulty, roundTotal);
    
    // Marcar la ronda como completada al guardar
    _saveGame();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor.withValues(alpha: 0.95),
        title: const Text(
          '🎉 ¡Versículo Completado!',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📖 Nivel: ${_getDifficultyName(currentDifficulty)}\n'
                  '🏆 Mejor puntaje: $highScore\n'
                  '───────────────\n'
                  '⏱️ Tiempo: ${_formatTime(_elapsedSeconds)}\n'
                  'Puntos de la ronda: ${_gameState?.score ?? 0}\n'
                  '${_penaltyPoints > 0 ? "⚠️ Penalización por tiempo: -$_penaltyPoints\n" : ""}'
                  'Bonificación por vidas (${_gameState?.lives ?? 0} x 100): +$lifeBonus\n'
                  '💰 Bonificación por tiempo: +$timeBonus\n'
                  '───────────────\n'
                  '🎯 Total acumulado: $roundTotal',
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text('📜 Versículo:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                Text(
                  _currentVerseText ?? '',
                  style: const TextStyle(color: Colors.black, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Qué deseas hacer?',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _goToNextRound();
            },
            child: const Text('➡️ Siguiente Ronda'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _exitToPreviousScreen();
            },
            child: const Text('🚪 Salir'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _showErrorDialog(String message) {
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor.withValues(alpha: 0.95),
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        content: SingleChildScrollView(
          child: Text(message, style: const TextStyle(color: Colors.black)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: dialogBackgroundColor,
          title: const Text(
            'Seleccionar Dificultad',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'Elige el nivel de dificultad para el criptograma:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDifficultyButton('Fácil', Difficulty.easy, Colors.green),
                _buildDifficultyButton('Media', Difficulty.medium, Colors.orange),
                _buildDifficultyButton('Difícil', Difficulty.hard, Colors.red),
                _buildDifficultyButton('Extrema', Difficulty.extreme, Colors.purple),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }

  Widget _buildDifficultyButton(String label, Difficulty difficulty, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(0, 40),
          ),
          onPressed: () {
            _selectedDifficulty = difficulty;
            Navigator.pop(context);
            _startNewGame();
          },
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, {bool isClickable = false}) {
    final Color chipIconColor = buttonColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isClickable ? buttonColor.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isClickable ? Border.all(color: buttonColor, width: 1.5) : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipIconColor),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isClickable ? buttonColor : Colors.black87,
            ),
          ),
          if (isClickable)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.edit,
                size: 12,
                color: buttonColor,
              ),
            ),
        ],
      ),
    );
  }

  String _getDifficultyName(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Fácil';
      case Difficulty.medium:
        return 'Media';
      case Difficulty.hard:
        return 'Difícil';
      case Difficulty.extreme:
        return 'Extrema';
    }
  }

  Future<void> _changeDifficulty(Difficulty newDifficulty) async {
    if (_gameState == null) return;
    
    final currentDifficulty = _gameState!.difficulty;
    final difficultyLevels = [Difficulty.easy, Difficulty.medium, Difficulty.hard, Difficulty.extreme];
    final currentIndex = difficultyLevels.indexOf(currentDifficulty);
    final newIndex = difficultyLevels.indexOf(newDifficulty);
    
    if (newIndex > currentIndex) {
      setState(() {
        _selectedDifficulty = newDifficulty;
        _gameState = _gameState!.copyWith(difficulty: newDifficulty);
      });
      await _saveGame();
      _showMessage('✅ Dificultad aumentada a ${_getDifficultyName(newDifficulty)}');
    } else if (newIndex == currentIndex) {
      _showMessage('Ya estás en esta dificultad');
    } else {
      _showTramposoDialog();
    }
  }

  void _showTramposoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor.withValues(alpha: 0.95),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              '¡Lo lamento!',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          'No puedes reducir la dificultad durante una partida.\n\n'
          'Solo puedes aumentar la dificultad para hacer el juego más desafiante.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showDifficultyChangeDialog() {
    if (_gameState == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cambiar Dificultad',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dificultad actual: ${_getDifficultyName(_gameState!.difficulty)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Solo puedes aumentar la dificultad.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDifficultyChangeButton('Fácil', Difficulty.easy, Colors.green),
                  _buildDifficultyChangeButton('Media', Difficulty.medium, Colors.orange),
                  _buildDifficultyChangeButton('Difícil', Difficulty.hard, Colors.red),
                  _buildDifficultyChangeButton('Extrema', Difficulty.extreme, Colors.purple),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChangeButton(String label, Difficulty difficulty, Color color) {
    final bool isCurrent = _gameState?.difficulty == difficulty;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrent ? Colors.grey : buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(0, 35),
          ),
          onPressed: () {
            Navigator.pop(context);
            if (isCurrent) {
              _showMessage('Ya estás en esta dificultad');
            } else {
              _changeDifficulty(difficulty);
            }
          },
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCurrent ? Colors.white70 : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getWords() {
    if (_gameState == null) return [];
    
    List<Map<String, dynamic>> words = [];
    List<int> currentWordPositions = [];
    String currentWord = '';
    
    for (int i = 0; i < _gameState!.cleanText.length; i++) {
      final char = _gameState!.cleanText[i];
      final RegExp letterRegex = RegExp(r'[A-ZÑ]');
      
      if (letterRegex.hasMatch(char)) {
        currentWord += char;
        currentWordPositions.add(i);
      } else {
        if (currentWord.isNotEmpty) {
          words.add({
            'word': currentWord,
            'positions': List.from(currentWordPositions),
            'isWord': true,
          });
          currentWord = '';
          currentWordPositions.clear();
        }
        
        if (char == ' ') {
          words.add({
            'word': ' ',
            'positions': [i],
            'isSpace': true,
          });
        } else {
          words.add({
            'word': char,
            'positions': [i],
            'isPunctuation': true,
          });
        }
      }
    }
    
    if (currentWord.isNotEmpty) {
      words.add({
        'word': currentWord,
        'positions': List.from(currentWordPositions),
        'isWord': true,
      });
    }
    
    return words;
  }

  double _calculateWordWidth(Map<String, dynamic> wordData) {
    bool isPunctuation = wordData['isPunctuation'] == true;
    String word = wordData['word'];
    
    if (isPunctuation) {
      return 20;
    } else {
      return word.length * 32;
    }
  }

  List<List<Map<String, dynamic>>> _organizeLines(List<Map<String, dynamic>> words, double availableWidth) {
    List<List<Map<String, dynamic>>> lines = [];
    List<Map<String, dynamic>> currentLine = [];
    double currentLineWidth = 0;
    const double wordSpacing = 8;
    
    for (var wordData in words) {
      bool isSpace = wordData['isSpace'] == true;
      
      if (isSpace) {
        currentLine.add(wordData);
        currentLineWidth += 12;
        continue;
      }
      
      double wordWidth = _calculateWordWidth(wordData);
      double additionalWidth = currentLine.isNotEmpty ? wordSpacing : 0;
      
      if (currentLineWidth + wordWidth + additionalWidth <= availableWidth) {
        currentLine.add(wordData);
        currentLineWidth += wordWidth + additionalWidth;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(List.from(currentLine));
        }
        currentLine = [wordData];
        currentLineWidth = wordWidth;
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    return lines;
  }

  bool _hasExtremelyLongWord(List<Map<String, dynamic>> words, double availableWidth) {
    for (var wordData in words) {
      bool isPunctuation = wordData['isPunctuation'] == true;
      bool isSpace = wordData['isSpace'] == true;
      
      if (!isPunctuation && !isSpace) {
        double wordWidth = _calculateWordWidth(wordData);
        if (wordWidth > availableWidth) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildCryptogramDisplay() {
    if (_gameState == null) return const SizedBox.shrink();
    
    final encryptedMap = _cryptogramService.getEncryptedDisplay(_gameState!);
    final words = _getWords();
    final screenWidth = MediaQuery.of(context).size.width - 40;
    final lines = _organizeLines(words, screenWidth);
    
    bool needsHorizontalScroll = _hasExtremelyLongWord(words, screenWidth);
    
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: lines.asMap().entries.map((lineEntry) {
        int lineIndex = lineEntry.key;
        var lineWords = lineEntry.value;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: lineIndex % 2 == 0 
                ? Colors.white.withValues(alpha: 0.3)
                : lightGrayColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 3,
            children: lineWords.map((wordData) {
              List<int> positions = List.from(wordData['positions']);
              bool isSpace = wordData['isSpace'] == true;
              bool isPunctuation = wordData['isPunctuation'] == true;
              
              if (isSpace) {
                return const SizedBox(width: 12, height: 32);
              }
              
              if (isPunctuation) {
                int pos = positions[0];
                String displayChar = encryptedMap[pos.toString()]!;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  child: Center(
                    child: Text(
                      displayChar,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }
              
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: positions.asMap().entries.map((entry) {
                    int letterIndex = entry.key;
                    int position = entry.value;
                    final encryptedNumber = encryptedMap[position.toString()]!;
                    final isRevealed = _gameState!.currentGuess[position] != '?';
                    final revealedLetter = isRevealed ? _gameState!.currentGuess[position] : '';
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_gameState!.currentGuess[position] == '?') {
                            _selectedPosition = position;
                          } else {
                            _selectedPosition = null;
                            _showMessage('Esta letra ya está revelada');
                          }
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 42,
                        margin: EdgeInsets.only(
                          left: letterIndex == 0 ? 2 : 0.5,
                          right: letterIndex == positions.length - 1 ? 2 : 0.5,
                          top: 2,
                          bottom: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedPosition == position ? Colors.orange : Colors.grey,
                            width: _selectedPosition == position ? 2 : 0.8,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: isRevealed ? Colors.white : lightGrayColor,
                          boxShadow: _selectedPosition == position ? const [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 2,
                              spreadRadius: 0.3,
                            ),
                          ] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isRevealed)
                              Text(
                                revealedLetter,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              )
                            else
                              const SizedBox(height: 16),
                            Text(
                              encryptedNumber,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: buttonColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
    
    Widget scrollableContent;
    
    if (needsHorizontalScroll) {
      scrollableContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: content,
        ),
      );
    } else {
      scrollableContent = SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: content,
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
        color: lightGrayColor.withValues(alpha: 0.5),
      ),
      child: Center(child: scrollableContent),
    );
  }

  Widget _buildKeyboard() {
    final List<Map<String, dynamic>> keyboardKeys = [
      ..._keyboardLetters.map((letter) => {'type': 'letter', 'value': letter}),
      {'type': 'action', 'value': 'ENTER', 'icon': Icons.keyboard_return},
      {'type': 'action', 'value': 'DELETE', 'icon': Icons.backspace},
    ];
    
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: lightGrayColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: keyboardKeys.map((key) {
              if (key['type'] == 'letter') {
                final String letter = key['value'];
                final bool isFullyRevealed = _isLetterFullyRevealed(letter);
                final bool isSelected = _selectedLetter == letter;

                return SizedBox(
                  width: 28,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: isFullyRevealed ? null : () {
                      setState(() {
                        _selectedLetter = letter;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? lightBrownColor : buttonColor,
                      foregroundColor: isSelected ? Colors.black : Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              } else {
                final String action = key['value'];
                final IconData icon = key['icon'];
                final bool isEnabled = action == 'ENTER' 
                    ? (_selectedLetter.isNotEmpty && _selectedPosition != null)
                    : true;
                
                return SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: isEnabled
                        ? () {
                            if (action == 'ENTER') {
                              _guessLetterAtPosition();
                            } else if (action == 'DELETE') {
                              _clearSelection();
                            }
                          }
                        : null,
                    icon: Icon(icon, size: 12),
                    label: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      minimumSize: const Size(32, 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }
            }).toList(),
          ),
          
          const SizedBox(height: 2),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: buttonColor, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 10, color: Colors.grey),
                const SizedBox(width: 2),
                Text(
                  _selectedPosition != null 
                      ? 'Casilla ${_selectedPosition! + 1}'
                      : 'Selecciona una casilla',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 2),
                if (_selectedLetter.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedLetter,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  double _getKeyboardHeight() {
    const int lettersPerRow = 10;
    final int rows = (_keyboardLetters.length / lettersPerRow).ceil();
    const int actionRows = 1;
    final int totalRows = rows + actionRows;
    
    const double rowHeight = 30;
    const double indicatorHeight = 20;
    const double padding = 6;
    
    return (totalRows * rowHeight) + indicatorHeight + padding;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo_mapa_tlf.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    if (_gameState == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo_mapa_tlf.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(child: Text('Error al cargar el juego')),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _exitToPreviousScreen(),
          ),
          title: const Text(
            'Criptograma Bíblico',
            style: TextStyle(
              fontSize: 26,
              fontFamily: 'OleoScript',
              fontWeight: FontWeight.normal,
              color: AppTheme.color4,
            ),
          ),
          backgroundColor: AppTheme.color6,
          foregroundColor: AppTheme.color4,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.lightbulb_outline, size: 22),
              tooltip: 'Comprar pista (100 puntos)',
              onPressed: _showHintDialog,
              color: Colors.amber.shade300,
              padding: const EdgeInsets.all(4),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableHeight = constraints.maxHeight;
                const double topSectionHeight = 90;
                final double keyboardHeight = _getKeyboardHeight();
                final double messageHeight = availableHeight - topSectionHeight - keyboardHeight - 10;
                
                return Column(
                  children: [
                    // ========== BARRA DE ESTADO CON CRONÓMETRO Y PENALIZACIÓN ==========
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: lightGrayColor.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoChip(Icons.score, '${_gameState!.score}'),
                          _buildInfoChip(Icons.straighten, '${_gameState!.currentRound}'),
                          _buildInfoChip(Icons.favorite, '${_gameState!.lives}'),
                          // 👈 CRONÓMETRO CON PENALIZACIÓN
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isPenaltyActive 
                                  ? Colors.red.shade100 
                                  : (_elapsedSeconds >= maxTimeSeconds 
                                      ? Colors.red.shade100 
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isPenaltyActive 
                                    ? Colors.red 
                                    : (_elapsedSeconds >= maxTimeSeconds 
                                        ? Colors.red 
                                        : buttonColor),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPenaltyActive ? Icons.warning : Icons.timer,
                                  size: 14,
                                  color: _isPenaltyActive 
                                      ? Colors.red 
                                      : (_elapsedSeconds >= maxTimeSeconds 
                                          ? Colors.red 
                                          : buttonColor),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(_elapsedSeconds),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isPenaltyActive 
                                        ? Colors.red 
                                        : (_elapsedSeconds >= maxTimeSeconds 
                                            ? Colors.red 
                                            : Colors.black87),
                                  ),
                                ),
                                if (_penaltyPoints > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(-$_penaltyPoints)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showDifficultyChangeDialog(),
                            child: _buildInfoChip(
                              Icons.speed, 
                              _getDifficultyName(_gameState!.difficulty),
                              isClickable: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Referencia del versículo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lightBrownColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentVerseInfo ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Área del criptograma
                    SizedBox(
                      height: messageHeight > 100 ? messageHeight : 100,
                      child: _buildCryptogramDisplay(),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Teclado
                    SizedBox(
                      height: keyboardHeight,
                      child: _buildKeyboard(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}