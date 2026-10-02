// lib/screens/criptograma/services/cryptogram_service.dart
import 'dart:math';
import '../models/game_state.dart';

class CryptogramService {
  final Random _random = Random();

  // ==================== FUNCIONES DE NORMALIZACIÓN ====================
  
  /// Convierte un texto a mayúsculas y reemplaza letras acentuadas por sus equivalentes sin acento
  String _normalizeText(String text) {
    return text
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('Ä', 'A')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ì', 'I')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ò', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ù', 'U')
        .replaceAll('Û', 'U')
        .replaceAll('Ü', 'U')
        // 👈 NO REEMPLAZAR LA Ñ
        .replaceAll('Ç', 'C');
  }

  /// Limpia el texto del versículo
  String _cleanText(String text) {
    String cleaned = text.replaceAll(RegExp(r'[^\w\sáéíóúñÁÉÍÓÚÑüÜ.,;!?-]'), '');
    return _normalizeText(cleaned);
  }

  // ==================== GENERACIÓN DEL MAPEO DE LETRAS A NÚMEROS ====================

  /// 👈 NUEVA FUNCIÓN: Genera un mapa de encriptación con números ALEATORIOS y ÚNICOS
  Map<String, int> _generateEncryptionMap(String text) {
    // Obtener todas las letras únicas del texto (incluyendo Ñ)
    Set<String> uniqueLetters = {};
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (RegExp(r'^[A-ZÑ]$').hasMatch(char)) {
        uniqueLetters.add(char);
      }
    }

    List<String> letters = uniqueLetters.toList();
    Map<String, int> encryptionMap = {};
    Set<int> usedNumbers = {};
    
    // Determinar el rango de números según la cantidad de letras
    // Mínimo 20, máximo 99 para dar variedad
    int maxNumber = max(20, letters.length * 3);
    maxNumber = maxNumber.clamp(20, 99);
    
    for (String letter in letters) {
      int number;
      int attempts = 0;
      do {
        // Generar número aleatorio entre 1 y maxNumber
        number = _random.nextInt(maxNumber) + 1;
        attempts++;
        // Evitar bucles infinitos
        if (attempts > 1000) {
          // Fallback: usar número basado en posición
          number = letters.indexOf(letter) + 10;
          break;
        }
      } while (usedNumbers.contains(number));
      
      usedNumbers.add(number);
      encryptionMap[letter] = number;
    }
    
    return encryptionMap;
  }

  // ==================== OBTENER MAPA DE VISUALIZACIÓN ====================

  /// 👈 MODIFICADO: Usa el mapa de encriptación del estado
  Map<String, String> getEncryptedDisplay(GameState state) {
    Map<String, String> result = {};
    final encryptionMap = state.encryptionMap;
    
    for (int i = 0; i < state.cleanText.length; i++) {
      String char = state.cleanText[i];
      
      if (char == ' ') {
        result[i.toString()] = ' ';
      } else if (RegExp(r'^[A-ZÑ]$').hasMatch(char)) {
        // Usar el número del mapa de encriptación
        if (encryptionMap.containsKey(char)) {
          result[i.toString()] = encryptionMap[char].toString();
        } else {
          // Fallback: número basado en posición
          result[i.toString()] = (i + 1).toString();
        }
      } else {
        // Puntuación
        result[i.toString()] = char;
      }
    }
    
    return result;
  }

  // ==================== INICIALIZACIÓN DEL JUEGO ====================

  /// 👈 MODIFICADO: Incluye el mapa de encriptación
  GameState initializeGame(String verseText, Difficulty difficulty) {
    String cleanText = _cleanText(verseText);
    
    // 👈 Generar mapa de encriptación aleatorio para esta ronda
    final encryptionMap = _generateEncryptionMap(cleanText);
    
    // Inicializar currentGuess con '?' para letras y mantener espacios/puntuación
    List<String> currentGuess = List.generate(cleanText.length, (index) {
      String char = cleanText[index];
      if (char == ' ') return ' ';
      if (RegExp(r'^[A-ZÑ]$').hasMatch(char)) return '?';
      return char; // Puntuación se muestra directamente
    });
    
    return GameState(
      originalText: verseText,
      cleanText: cleanText,
      currentGuess: currentGuess,
      lives: _getMaxLives(difficulty),
      score: 0,
      currentRound: 1,
      isGameOver: false,
      revealedLetters: {},
      difficulty: difficulty,
      encryptionMap: encryptionMap, // 👈 AÑADIDO
    );
  }

  // ==================== ADIVINAR LETRA ====================

  GameState guessLetterAtPosition(GameState state, int position, String letter) {
    if (state.isGameOver) return state;
    
    String cleanChar = state.cleanText[position];
    String normalizedLetter = _normalizeText(letter);
    
    if (cleanChar == normalizedLetter) {
      // Acierto
      List<String> newGuess = List.from(state.currentGuess);
      
      if (state.difficulty == Difficulty.easy) {
        // En fácil, revelar todas las ocurrencias
        for (int i = 0; i < state.cleanText.length; i++) {
          if (state.cleanText[i] == cleanChar && newGuess[i] == '?') {
            newGuess[i] = cleanChar;
          }
        }
      } else {
        // En otras dificultades, revelar solo la posición seleccionada
        newGuess[position] = cleanChar;
      }
      
      Set<String> newRevealedLetters = Set.from(state.revealedLetters);
      newRevealedLetters.add(cleanChar);
      
      // Verificar si la ronda está completa
      bool isComplete = !newGuess.contains('?');
      
      if (isComplete) {
        int roundScore = 500 + (state.revealedLetters.length * 50) + (state.lives * 100);
        return state.copyWith(
          currentGuess: newGuess,
          revealedLetters: newRevealedLetters,
          score: state.score + roundScore,
          isGameOver: false,
        );
      }
      
      return state.copyWith(
        currentGuess: newGuess,
        revealedLetters: newRevealedLetters,
      );
    } else {
      // Error: perder una vida
      int newLives = state.lives - 1;
      return state.copyWith(
        lives: newLives,
        isGameOver: newLives <= 0,
      );
    }
  }

  // ==================== USAR PISTA ====================

  GameState useHint(GameState state) {
    if (state.isGameOver) return state;
    
    const int hintCost = 100;
    if (state.score < hintCost) return state;
    
    // Encontrar letras no reveladas
    List<String> unrevealedLetters = [];
    for (int i = 0; i < state.cleanText.length; i++) {
      String char = state.cleanText[i];
      if (RegExp(r'^[A-ZÑ]$').hasMatch(char) && 
          state.currentGuess[i] == '?' &&
          !unrevealedLetters.contains(char)) {
        unrevealedLetters.add(char);
      }
    }
    
    if (unrevealedLetters.isEmpty) return state;
    
    String letterToReveal = unrevealedLetters[_random.nextInt(unrevealedLetters.length)];
    List<String> newGuess = List.from(state.currentGuess);
    
    if (state.difficulty == Difficulty.easy) {
      // En fácil, revelar todas las ocurrencias
      for (int i = 0; i < state.cleanText.length; i++) {
        if (state.cleanText[i] == letterToReveal && newGuess[i] == '?') {
          newGuess[i] = letterToReveal;
        }
      }
    } else {
      // En otras dificultades, revelar solo una ocurrencia
      for (int i = 0; i < state.cleanText.length; i++) {
        if (state.cleanText[i] == letterToReveal && newGuess[i] == '?') {
          newGuess[i] = letterToReveal;
          break;
        }
      }
    }
    
    Set<String> newRevealedLetters = Set.from(state.revealedLetters);
    newRevealedLetters.add(letterToReveal);
    
    return state.copyWith(
      currentGuess: newGuess,
      revealedLetters: newRevealedLetters,
      score: state.score - hintCost,
    );
  }

  // ==================== SIGUIENTE RONDA ====================

  /// 👈 MODIFICADO: Genera NUEVO mapa de encriptación para la nueva ronda
  GameState nextRound(GameState state, String newVerseText) {
    String newCleanText = _cleanText(newVerseText);
    
    // 👈 Generar NUEVO mapa de encriptación para esta ronda
    final newEncryptionMap = _generateEncryptionMap(newCleanText);
    
    List<String> newCurrentGuess = List.generate(newCleanText.length, (index) {
      String char = newCleanText[index];
      if (char == ' ') return ' ';
      if (RegExp(r'^[A-ZÑ]$').hasMatch(char)) return '?';
      return char;
    });
    
    return GameState(
      originalText: newVerseText,
      cleanText: newCleanText,
      currentGuess: newCurrentGuess,
      lives: _getMaxLives(state.difficulty),
      score: state.score,
      currentRound: state.currentRound + 1,
      isGameOver: false,
      revealedLetters: {},
      difficulty: state.difficulty,
      encryptionMap: newEncryptionMap, // 👈 NUEVO MAPA DE ENCRIPTACIÓN
    );
  }

  // ==================== FUNCIONES DE UTILIDAD ====================

  /// Obtiene el número de vidas según la dificultad
  int _getMaxLives(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 5;
      case Difficulty.medium:
        return 4;
      case Difficulty.hard:
        return 3;
      case Difficulty.extreme:
        return 2;
    }
  }
}