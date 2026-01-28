// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationRuleAdapter extends TypeAdapter<NotificationRule> {
  @override
  final int typeId = 10;

  @override
  NotificationRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationRule(
      id: fields[0] as String?,
      keyword: fields[1] as String,
      categoryId: fields[2] as String,
      isActive: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationRule obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.keyword)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
