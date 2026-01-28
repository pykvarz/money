// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationLogAdapter extends TypeAdapter<NotificationLog> {
  @override
  final int typeId = 11;

  @override
  NotificationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationLog(
      packageName: fields[0] as String,
      text: fields[1] as String,
      timestamp: fields[2] as DateTime,
      parsedAmount: fields[3] as String?,
      parsedKeyword: fields[4] as String?,
      parseSuccess: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.parsedAmount)
      ..writeByte(4)
      ..write(obj.parsedKeyword)
      ..writeByte(5)
      ..write(obj.parseSuccess);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
