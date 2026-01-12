// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_account_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAccountHiveModelAdapter extends TypeAdapter<UserAccountHiveModel> {
  @override
  final int typeId = 13;

  @override
  UserAccountHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAccountHiveModel(
      userId: fields[0] as String,
      email: fields[1] as String,
      password: fields[2] as String,
      role: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserAccountHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccountHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
