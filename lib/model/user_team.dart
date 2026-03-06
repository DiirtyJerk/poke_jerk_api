import 'package:hive/hive.dart';

part 'user_team.g.dart';

@HiveType(typeId: 2)
class UserTeam extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<int> pokemonIds;

  UserTeam(this.name, [List<int>? pokemonIds])
      : pokemonIds = pokemonIds ?? [];
}
