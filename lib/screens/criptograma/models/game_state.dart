// lib/screens/criptograma/models/game_state.dart

// Enumeración para los niveles de dificultad
enum Difficulty {
  easy,
  medium,
  hard,
  extreme
}

// Clase que representa el estado completo del juego
class GameState {
  final String originalText;           // Texto original del versículo (con acentos)
  final String cleanText;              // Texto normalizado (sin acentos, mayúsculas)
  final List<String> currentGuess;     // Estado actual de las adivinanzas ('?' o letra)
  final int lives;                      // Vidas restantes (0-3)
  final int score;                      // Puntuación acumulada
  final int currentRound;               // Ronda actual
  final bool isGameOver;                // Indica si el juego terminó
  final Set<String> revealedLetters;    // Conjunto de letras ya reveladas
  final Difficulty difficulty;          // Nivel de dificultad
  final Map<String, int> encryptionMap; // 👈 AÑADIDO: Mapa de encriptación (letra → número)

  GameState({
    required this.originalText,
    required this.cleanText,
    required this.currentGuess,
    required this.lives,
    required this.score,
    required this.currentRound,
    required this.isGameOver,
    required this.revealedLetters,
    required this.difficulty,
    required this.encryptionMap, // 👈 AÑADIDO (ahora es requerido)
  });

  // Método para crear una copia del estado con cambios específicos
  GameState copyWith({
    String? originalText,
    String? cleanText,
    List<String>? currentGuess,
    int? lives,
    int? score,
    int? currentRound,
    bool? isGameOver,
    Set<String>? revealedLetters,
    Difficulty? difficulty,
    Map<String, int>? encryptionMap, // 👈 AÑADIDO
  }) {
    return GameState(
      originalText: originalText ?? this.originalText,
      cleanText: cleanText ?? this.cleanText,
      currentGuess: currentGuess ?? this.currentGuess,
      lives: lives ?? this.lives,
      score: score ?? this.score,
      currentRound: currentRound ?? this.currentRound,
      isGameOver: isGameOver ?? this.isGameOver,
      revealedLetters: revealedLetters ?? this.revealedLetters,
      difficulty: difficulty ?? this.difficulty,
      encryptionMap: encryptionMap ?? this.encryptionMap, // 👈 AÑADIDO
    );
  }
}