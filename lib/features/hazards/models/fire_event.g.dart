import 'package:hive/hive.dart';
import 'fire_event.dart';

/// Hive TypeAdapter for FireEvent
/// Enables local caching of fire events for offline support
class FireEventAdapter extends TypeAdapter<FireEvent> {
  @override
  final int typeId = 0; // Unique ID for this adapter

  @override
  FireEvent read(BinaryReader reader) {
    return FireEvent(
      id: reader.readString(),
      latitude: reader.readDouble(),
      longitude: reader.readDouble(),
      brightness: reader.readDouble(),
      confidence: reader.readString(),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      frp: reader.readDouble(),
      satellite: reader.readString(),
      isDayTime: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, FireEvent obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
    writer.writeDouble(obj.brightness);
    writer.writeString(obj.confidence);
    writer.writeInt(obj.acquisitionTime.millisecondsSinceEpoch);
    writer.writeDouble(obj.frp);
    writer.writeString(obj.satellite);
    writer.writeBool(obj.isDayTime);
  }
}
