// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleHiveModelAdapter extends TypeAdapter<ScheduleHiveModel> {
  @override
  final int typeId = 21;

  @override
  ScheduleHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleHiveModel(
      id: fields[0] as String,
      dateMillis: fields[1] as int,
      area: fields[2] as String,
      note: fields[3] as String,
      shift: fields[4] as String,
      isActive: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateMillis)
      ..writeByte(2)
      ..write(obj.area)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.shift)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
