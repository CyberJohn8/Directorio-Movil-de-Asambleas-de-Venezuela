// lib/models/verse.dart
class Verse {
  final int bookId;
  final int chapter;
  final int verse;
  final String text;

  Verse({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory Verse.fromMap(Map<String, dynamic> map) {
    return Verse(
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

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
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