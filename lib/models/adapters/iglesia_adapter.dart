import 'package:hive/hive.dart';
import '../iglesia.dart';

@HiveType(typeId: 0)
class IglesiaAdapter extends TypeAdapter<Iglesia> {
  @override
  final int typeId = 0;

  @override
  Iglesia read(BinaryReader reader) {
    return Iglesia(
      id: reader.readInt(),
      asamblea: reader.readString(),
      numero: reader.readString(),
      ciudad: reader.readString(),
      estado: reader.readString(),
      direccion: reader.readString(),
      domingo: reader.readString(),
      lunes: reader.readString(),
      martes: reader.readString(),
      miercoles: reader.readString(),
      jueves: reader.readString(),
      viernes: reader.readString(),
      sabado: reader.readString(),
      obras: reader.readString(),
      googleMaps: reader.readString(),
      coordenadas: reader.readString(),
      fechaFundacion: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Iglesia obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.asamblea);
    writer.writeString(obj.numero);
    writer.writeString(obj.ciudad);
    writer.writeString(obj.estado);
    writer.writeString(obj.direccion);
    writer.writeString(obj.domingo ?? '');
    writer.writeString(obj.lunes ?? '');
    writer.writeString(obj.martes ?? '');
    writer.writeString(obj.miercoles ?? '');
    writer.writeString(obj.jueves ?? '');
    writer.writeString(obj.viernes ?? '');
    writer.writeString(obj.sabado ?? '');
    writer.writeString(obj.obras ?? '');
    writer.writeString(obj.googleMaps ?? '');
    writer.writeString(obj.coordenadas ?? '');
    writer.writeString(obj.fechaFundacion ?? '');
  }
}