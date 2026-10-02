// lib/models/adapters/verse_adapter.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../verse.dart';

@HiveType(typeId: 3)
class VerseAdapter extends TypeAdapter<Verse> {
  @override
  final int typeId = 3;

  @override
  Verse read(BinaryReader reader) {
    return Verse(
      bookId: reader.readInt(),
      chapter: reader.readInt(),
      verse: reader.readInt(),
      text: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Verse obj) {
    writer.writeInt(obj.bookId);
    writer.writeInt(obj.chapter);
    writer.writeInt(obj.verse);
    writer.writeString(obj.text);
  }
}