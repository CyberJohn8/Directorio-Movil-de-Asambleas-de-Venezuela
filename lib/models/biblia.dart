// lib/models/biblia.dart

class BibliaBook {
  final int id;
  final String key;
  final String title;
  final String shortTitle;
  final String abbr;
  final String category;
  final String testament;
  final int chapters;
  final int verses;

  BibliaBook({
    required this.id,
    required this.key,
    required this.title,
    required this.shortTitle,
    required this.abbr,
    required this.category,
    required this.testament,
    required this.chapters,
    required this.verses,
  });

  // Getter para compatibilidad con el código existente
  String get name => shortTitle;
  String get modernName => shortTitle;

  factory BibliaBook.fromJson(Map<String, dynamic> json) {
    return BibliaBook(
      id: json['number'] as int? ?? 0,
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortTitle: json['shortTitle'] as String? ?? '',
      abbr: json['abbr'] as String? ?? '',
      category: json['category'] as String? ?? '',
      testament: json['testament'] as String? ?? '',
      chapters: json['chapters'] as int? ?? 0,
      verses: json['verses'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': id,
      'key': key,
      'title': title,
      'shortTitle': shortTitle,
      'abbr': abbr,
      'category': category,
      'testament': testament,
      'chapters': chapters,
      'verses': verses,
    };
  }
}

class BibliaVerse {
  final int bookId;
  final int chapter;
  final int verse;
  final String text;

  BibliaVerse({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  // 👈 MÉTODO COPYWITH AGREGADO
  BibliaVerse copyWith({
    int? bookId,
    int? chapter,
    int? verse,
    String? text,
  }) {
    return BibliaVerse(
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
    );
  }

  factory BibliaVerse.fromMap(Map<String, dynamic> map) {
    return BibliaVerse(
      bookId: map['book_id'] as int? ?? 0,
      chapter: map['chapter'] as int? ?? 0,
      verse: map['verse'] as int? ?? 0,
      text: map['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'text': text,
    };
  }

  factory BibliaVerse.fromJson(Map<String, dynamic> json) {
    return BibliaVerse(
      bookId: json['book_id'] as int? ?? 0,
      chapter: json['chapter'] as int? ?? 0,
      verse: json['verse'] as int? ?? 0,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'text': text,
    };
  }
}