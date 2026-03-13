import 'package:flutter/foundation.dart';

/// Holds the list of pokemon IDs currently in the comparator.
/// Persists in memory across navigation (lives at root provider level).
class ComparatorProvider extends ChangeNotifier {
  static const int maxCompare = 3;

  final List<int> _pokemonIds = [];

  List<int> get pokemonIds => List.unmodifiable(_pokemonIds);
  int get count => _pokemonIds.length;
  bool get isFull => _pokemonIds.length >= maxCompare;

  bool contains(int id) => _pokemonIds.contains(id);

  /// Returns true if added, false if already present or full.
  bool addPokemon(int id) {
    if (_pokemonIds.contains(id) || isFull) return false;
    _pokemonIds.add(id);
    notifyListeners();
    return true;
  }

  void removePokemonAt(int index) {
    if (index >= 0 && index < _pokemonIds.length) {
      _pokemonIds.removeAt(index);
      notifyListeners();
    }
  }

  void removePokemon(int id) {
    if (_pokemonIds.remove(id)) {
      notifyListeners();
    }
  }

  void clear() {
    _pokemonIds.clear();
    notifyListeners();
  }
}
