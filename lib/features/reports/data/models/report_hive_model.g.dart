// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReportHiveModelAdapter extends TypeAdapter<ReportHiveModel> {
  @override
  final int typeId = 31;

  @override
  ReportHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReportHiveModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      createdAt: fields[2] as int,
      category: fields[3] as String,
      location: fields[4] as String,
      message: fields[5] as String,
      status: fields[6] as String,
      attachmentUrl: fields[7] as String?,
      reporterName: fields[8] as String?,
      reporterPhotoUrl: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReportHiveModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.message)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.attachmentUrl)
      ..writeByte(8)
      ..write(obj.reporterName)
      ..writeByte(9)
      ..write(obj.reporterPhotoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
