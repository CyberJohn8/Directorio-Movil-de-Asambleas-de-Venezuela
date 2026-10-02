// lib/models/adapters/himno_adapter.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../himno.dart';

@HiveType(typeId: 2)
class HimnoAdapter extends TypeAdapter<Himno> {
  @override
  final int typeId = 2;

  @override
  Himno read(BinaryReader reader) {
    return Himno(
      numero: reader.readInt(),
      primeraLinea: reader.readString(),
      letra: reader.readString(),
      versiculos: reader.readString(),
      tema: reader.readString(),
      subtema: reader.readString(),
      subSubtema: reader.readString(),
      reunion: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Himno obj) {
    writer.writeInt(obj.numero);
    writer.writeString(obj.primeraLinea);
    writer.writeString(obj.letra);
    writer.writeString(obj.versiculos ?? '');
    writer.writeString(obj.tema ?? '');
    writer.writeString(obj.subtema ?? '');
    writer.writeString(obj.subSubtema ?? '');
    writer.writeString(obj.reunion ?? '');
  }
}