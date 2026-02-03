// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_point_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CollectionPointHiveModelAdapter
    extends TypeAdapter<CollectionPointHiveModel> {
  @override
  final int typeId = 41;

  @override
  CollectionPointHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollectionPointHiveModel(
      id: fields[0] as String,
      name: fields[1] as String? ?? '',
      latitude: fields[2] as double? ?? 0,
      longitude: fields[3] as double? ?? 0,
      createdAt: fields[4] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, CollectionPointHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionPointHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
