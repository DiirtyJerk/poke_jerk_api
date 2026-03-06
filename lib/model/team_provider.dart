import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:poke_jerk_api/model/user_team.dart';

class TeamProvider extends ChangeNotifier {
  Box<UserTeam>? _box;

  void init(Box<UserTeam> box) => _box = box;

  List<UserTeam> get teams => _box?.values.toList() ?? [];

  void addTeam(String name) {
    _box?.add(UserTeam(name));
    notifyListeners();
  }

  void removeTeam(UserTeam team) {
    team.delete();
    notifyListeners();
  }

  void renameTeam(UserTeam team, String name) {
    team.name = name;
    team.save();
    notifyListeners();
  }

  void addPokemon(UserTeam team, int pokemonId) {
    if (team.pokemonIds.length >= 6) return;
    team.pokemonIds = [...team.pokemonIds, pokemonId];
    team.save();
    notifyListeners();
  }

  void removePokemon(UserTeam team, int index) {
    if (index < 0 || index >= team.pokemonIds.length) return;
    team.pokemonIds = [...team.pokemonIds]..removeAt(index);
    team.save();
    notifyListeners();
  }

  void replacePokemon(UserTeam team, int index, int pokemonId) {
    if (index < 0 || index >= team.pokemonIds.length) return;
    team.pokemonIds = [...team.pokemonIds]..[index] = pokemonId;
    team.save();
    notifyListeners();
  }

  void reorderPokemon(UserTeam team, int oldIndex, int newIndex) {
    final ids = [...team.pokemonIds];
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    team.pokemonIds = ids;
    team.save();
    notifyListeners();
  }
}
