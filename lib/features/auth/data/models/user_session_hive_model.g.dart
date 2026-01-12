// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_session_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSessionHiveModelAdapter extends TypeAdapter<UserSessionHiveModel> {
  @override
  final int typeId = 11;

  @override
  UserSessionHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSessionHiveModel(
      userId: fields[0] as String,
      email: fields[1] as String,
      role: fields[2] as String,
      lastHeardBroadcastAt: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSessionHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.lastHeardBroadcastAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSessionHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
