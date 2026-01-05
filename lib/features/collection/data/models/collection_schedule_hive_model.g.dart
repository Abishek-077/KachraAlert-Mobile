// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_schedule_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CollectionScheduleHiveModelAdapter
    extends TypeAdapter<CollectionScheduleHiveModel> {
  @override
  final int typeId = 3;

  @override
  CollectionScheduleHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollectionScheduleHiveModel(
      routeId: fields[0] as String,
      area: fields[1] as String,
      days: fields[2] as String,
      time: fields[3] as String,
      wasteTypes: (fields[4] as List).cast<String>(),
      dayOfWeek: '',
    );
  }

  @override
  void write(BinaryWriter writer, CollectionScheduleHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.routeId)
      ..writeByte(1)
      ..write(obj.area)
      ..writeByte(2)
      ..write(obj.days)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.wasteTypes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionScheduleHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
