// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_limit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklyLimitAdapter extends TypeAdapter<WeeklyLimit> {
  @override
  final int typeId = 2;

  @override
  WeeklyLimit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyLimit(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      limitAmount: fields[2] as double,
      weekStartDate: fields[3] as DateTime,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyLimit obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.limitAmount)
      ..writeByte(3)
      ..write(obj.weekStartDate)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyLimitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
