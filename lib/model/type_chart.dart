/// Table des efficacités de types (Gen 6+)
/// Seules les valeurs ≠ 1.0 sont stockées.
class TypeChart {
  TypeChart._();

  static const Map<String, Map<String, double>> _chart = {
    'normal':   {'rock': 0.5, 'ghost': 0.0, 'steel': 0.5},
    'fire':     {'fire': 0.5, 'water': 0.5, 'grass': 2.0, 'ice': 2.0, 'bug': 2.0, 'rock': 0.5, 'dragon': 0.5, 'steel': 2.0},
    'water':    {'fire': 2.0, 'water': 0.5, 'grass': 0.5, 'ground': 2.0, 'rock': 2.0, 'dragon': 0.5},
    'electric': {'water': 2.0, 'electric': 0.5, 'grass': 0.5, 'ground': 0.0, 'flying': 2.0, 'dragon': 0.5},
    'grass':    {'fire': 0.5, 'water': 2.0, 'grass': 0.5, 'poison': 0.5, 'ground': 2.0, 'flying': 0.5, 'bug': 0.5, 'rock': 2.0, 'dragon': 0.5, 'steel': 0.5},
    'ice':      {'water': 0.5, 'grass': 2.0, 'ice': 0.5, 'ground': 2.0, 'flying': 2.0, 'dragon': 2.0},
    'fighting': {'normal': 2.0, 'ice': 2.0, 'poison': 0.5, 'flying': 0.5, 'psychic': 0.5, 'bug': 0.5, 'rock': 2.0, 'ghost': 0.0, 'dark': 2.0, 'steel': 2.0, 'fairy': 0.5},
    'poison':   {'grass': 2.0, 'poison': 0.5, 'ground': 0.5, 'rock': 0.5, 'ghost': 0.5, 'steel': 0.0, 'fairy': 2.0},
    'ground':   {'fire': 2.0, 'electric': 2.0, 'grass': 0.5, 'poison': 2.0, 'flying': 0.0, 'bug': 0.5, 'rock': 2.0, 'steel': 2.0},
    'flying':   {'electric': 0.5, 'grass': 2.0, 'fighting': 2.0, 'bug': 2.0, 'rock': 0.5, 'steel': 0.5},
    'psychic':  {'fighting': 2.0, 'poison': 2.0, 'psychic': 0.5, 'dark': 0.0, 'steel': 0.5},
    'bug':      {'fire': 0.5, 'grass': 2.0, 'fighting': 0.5, 'flying': 0.5, 'ghost': 0.5, 'psychic': 2.0, 'dark': 2.0, 'steel': 0.5, 'fairy': 0.5},
    'rock':     {'fire': 2.0, 'ice': 2.0, 'fighting': 0.5, 'ground': 0.5, 'flying': 2.0, 'bug': 2.0, 'steel': 0.5},
    'ghost':    {'normal': 0.0, 'ghost': 2.0, 'psychic': 2.0, 'dark': 0.5},
    'dragon':   {'dragon': 2.0, 'steel': 0.5, 'fairy': 0.0},
    'dark':     {'fighting': 0.5, 'ghost': 2.0, 'psychic': 2.0, 'dark': 0.5, 'fairy': 0.5},
    'steel':    {'fire': 0.5, 'water': 0.5, 'electric': 0.5, 'ice': 2.0, 'rock': 2.0, 'steel': 0.5, 'fairy': 2.0},
    'fairy':    {'fire': 0.5, 'fighting': 2.0, 'poison': 0.5, 'dragon': 2.0, 'dark': 2.0, 'steel': 0.5},
  };

  static const List<String> allTypes = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice',
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy',
  ];

  static const Map<String, String> namesFr = {
    'normal': 'Normal', 'fire': 'Feu', 'water': 'Eau',
    'electric': 'Électrik', 'grass': 'Plante', 'ice': 'Glace',
    'fighting': 'Combat', 'poison': 'Poison', 'ground': 'Sol',
    'flying': 'Vol', 'psychic': 'Psy', 'bug': 'Insecte',
    'rock': 'Roche', 'ghost': 'Spectre', 'dragon': 'Dragon',
    'dark': 'Ténèbres', 'steel': 'Acier', 'fairy': 'Fée',
  };

  static const Map<String, String> namesEn = {
    'normal': 'Normal', 'fire': 'Fire', 'water': 'Water',
    'electric': 'Electric', 'grass': 'Grass', 'ice': 'Ice',
    'fighting': 'Fighting', 'poison': 'Poison', 'ground': 'Ground',
    'flying': 'Flying', 'psychic': 'Psychic', 'bug': 'Bug',
    'rock': 'Rock', 'ghost': 'Ghost', 'dragon': 'Dragon',
    'dark': 'Dark', 'steel': 'Steel', 'fairy': 'Fairy',
  };

  static String getTypeName(String identifier, String language) {
    final map = language == 'fr' ? namesFr : namesEn;
    return map[identifier] ?? identifier;
  }

  /// Retourne le multiplicateur d'un type attaquant contre un type défenseur.
  static double _get(String attacker, String defender) =>
      _chart[attacker]?[defender] ?? 1.0;

  /// Calcule les multiplicateurs défensifs de tous les types attaquants
  /// contre un Pokémon possédant [defenderTypes] (1 ou 2 types).
  /// Seuls les multiplicateurs ≠ 1.0 sont inclus dans le résultat.
  static Map<String, double> computeDefenseChart(List<String> defenderTypes) {
    final result = <String, double>{};
    for (final attacker in allTypes) {
      double mult = 1.0;
      for (final defender in defenderTypes) {
        mult *= _get(attacker, defender);
      }
      if (mult != 1.0) result[attacker] = mult;
    }
    return result;
  }
}
