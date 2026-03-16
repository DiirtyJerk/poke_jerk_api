import 'package:hive/hive.dart';

part 'user_pokemons.g.dart';

@HiveType(typeId: 1)
class UserPokemons extends HiveObject {
  @HiveField(0)
  String identifier;

  @HiveField(1)
  bool selected;

  @HiveField(2)
  bool favorited;

  @HiveField(3)
  bool captured;

  @HiveField(4, defaultValue: [])
  List<int> capturedVersionGroupIds;

  UserPokemons(this.identifier, this.selected, this.favorited, this.captured,
      [List<int>? capturedVersionGroupIds])
      : capturedVersionGroupIds = capturedVersionGroupIds ?? [];

  /// Whether captured in a specific version group.
  bool isCapturedIn(int? versionGroupId) {
    if (versionGroupId == null) return captured;
    return capturedVersionGroupIds.contains(versionGroupId);
  }
}
