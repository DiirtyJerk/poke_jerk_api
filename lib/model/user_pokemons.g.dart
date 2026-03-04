// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_pokemons.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPokemonsAdapter extends TypeAdapter<UserPokemons> {
  @override
  final int typeId = 1;

  @override
  UserPokemons read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPokemons(
      fields[0] as String,
      fields[1] as bool,
      fields[2] as bool,
      fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPokemons obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.identifier)
      ..writeByte(1)
      ..write(obj.selected)
      ..writeByte(2)
      ..write(obj.favorited)
      ..writeByte(3)
      ..write(obj.captured);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPokemonsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
