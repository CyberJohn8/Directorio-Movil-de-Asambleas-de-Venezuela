// lib/models/book.dart
class Book {
  final int id;
  final String name;
  final String modernName;
  final int newTestament; // Cambiado de bool a int (0 o 1)

  Book({
    required this.id,
    required this.name,
    required this.modernName,
    required this.newTestament,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      modernName: map['modern_name'] as String? ?? '',
      newTestament: map['new_testament'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'modern_name': modernName,
      'new_testament': newTestament,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      modernName: json['modern_name'] as String? ?? '',
      newTestament: json['new_testament'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modern_name': modernName,
      'new_testament': newTestament,
    };
  }
}