// lib/models/adapters/book_adapter.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../book.dart';

@HiveType(typeId: 1)
class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 1;

  @override
  Book read(BinaryReader reader) {
    return Book(
      id: reader.readInt(),
      name: reader.readString(),
      modernName: reader.readString(),
      newTestament: reader.readInt(), // 👈 CORREGIDO: leer como int
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.modernName);
    writer.writeInt(obj.newTestament); // 👈 CORREGIDO: escribir como int
  }
}