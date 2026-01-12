// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertHiveModelAdapter extends TypeAdapter<AlertHiveModel> {
  @override
  final int typeId = 12;

  @override
  AlertHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertHiveModel(
      id: fields[0] as String,
      wasteType: fields[1] as String,
      note: fields[2] as String,
      lat: fields[3] as double,
      lng: fields[4] as double,
      createdAt: fields[5] as int,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlertHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.wasteType)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.lng)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
