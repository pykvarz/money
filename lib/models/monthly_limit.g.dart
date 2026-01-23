// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_limit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyLimitAdapter extends TypeAdapter<MonthlyLimit> {
  @override
  final int typeId = 7;

  @override
  MonthlyLimit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyLimit(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      limitAmount: fields[2] as double,
      isActive: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyLimit obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.limitAmount)
      ..writeByte(3)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyLimitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
