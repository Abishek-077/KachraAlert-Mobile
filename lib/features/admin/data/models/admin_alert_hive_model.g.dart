// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_alert_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdminAlertHiveModelAdapter extends TypeAdapter<AdminAlertHiveModel> {
  @override
  final int typeId = 14;

  @override
  AdminAlertHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdminAlertHiveModel(
      id: fields[0] as String,
      title: fields[1] as String,
      message: fields[2] as String,
      createdAt: fields[3] as int,
      updatedAt: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AdminAlertHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAlertHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
