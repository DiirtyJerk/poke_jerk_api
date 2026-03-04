import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:poke_jerk_api/model/user_pokemons.dart';

class UserDatas with ChangeNotifier {
  UserDatas._privateConstructor();

  static final UserDatas _instance = UserDatas._privateConstructor();

  factory UserDatas() => _instance;

  final Map<String, UserPokemons> _userPokemons = {};
  Box<UserPokemons>? boxUserPokemons;

  void initUserPokemons() {
    for (UserPokemons value in boxUserPokemons!.values) {
      _userPokemons[value.identifier] = value;
    }
  }

  void capturedPokemon(String identifier, bool captured) {
    if (_userPokemons[identifier] == null) {
      final userDatas = UserPokemons(identifier, false, false, captured);
      boxUserPokemons!.add(userDatas);
      _userPokemons[identifier] = userDatas;
    } else {
      _userPokemons[identifier]!.captured = captured;
      _userPokemons[identifier]!.save();
    }
    notifyListeners();
  }

  void selectedPokemon(String identifier, bool selected) {
    if (_userPokemons[identifier] == null) {
      final userDatas = UserPokemons(identifier, selected, false, false);
      boxUserPokemons!.add(userDatas);
      _userPokemons[identifier] = userDatas;
    } else {
      _userPokemons[identifier]!.selected = selected;
      _userPokemons[identifier]!.save();
    }
    notifyListeners();
  }

  void favoritedPokemon(String identifier, bool favorited) {
    if (_userPokemons[identifier] == null) {
      final userDatas = UserPokemons(identifier, false, favorited, false);
      boxUserPokemons!.add(userDatas);
      _userPokemons[identifier] = userDatas;
    } else {
      _userPokemons[identifier]!.favorited = favorited;
      _userPokemons[identifier]!.save();
    }
    notifyListeners();
  }

  UserPokemons? getUserPokemon(String identifier) {
    return _userPokemons[identifier];
  }

  void clearFavorited() {
    _userPokemons.forEach((key, value) {
      value.favorited = false;
      value.save();
    });
    notifyListeners();
  }

  void clearSelected() {
    _userPokemons.forEach((key, value) {
      value.selected = false;
      value.save();
    });
    notifyListeners();
  }

  void clearCaptured() {
    _userPokemons.forEach((key, value) {
      value.captured = false;
      value.save();
    });
    notifyListeners();
  }
}
