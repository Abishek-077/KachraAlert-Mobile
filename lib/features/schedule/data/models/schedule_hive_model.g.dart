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
      dateISO: fields[1] as String? ?? '',
      timeLabel: fields[2] as String? ?? '',
      waste: fields[3] as String? ?? '',
      status: fields[4] as String? ?? 'Upcoming',
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateISO)
      ..writeByte(2)
      ..write(obj.timeLabel)
      ..writeByte(3)
      ..write(obj.waste)
      ..writeByte(4)
      ..write(obj.status);
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
