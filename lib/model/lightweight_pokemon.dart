import 'package:poke_jerk_api/model/stat.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/utils/sprite_utils.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';

/// Lightweight pokemon data for team analysis, comparator, and pickers.
/// Parsed from `getTeamPokemonDataQuery` results.
class LightweightPokemon {
  final int id;
  final String identifier;
  final Map<int, String> names;
  final List<TypePokemon> types;
  final Map<Stat, int> stats;

  LightweightPokemon({
    required this.id,
    required this.identifier,
    required this.names,
    required this.types,
    required this.stats,
  });

  String getTranslation(String language) =>
      localizedName(names, language, identifier);

  String get spriteUrl => pokemonArtworkUrl(id);

  int get totalStats => stats.values.fold(0, (a, b) => a + b);

  factory LightweightPokemon.fromJson(Map<String, dynamic> json) {
    final types = <TypePokemon>[];
    for (final t in (json['pokemon_v2_pokemontypes'] as List? ?? [])) {
      if (t['pokemon_v2_type'] != null) {
        types.add(
            TypePokemon.fromJson(t['pokemon_v2_type'] as Map<String, dynamic>));
      }
    }
    final stats = <Stat, int>{};
    for (final s in (json['pokemon_v2_pokemonstats'] as List? ?? [])) {
      if (s['pokemon_v2_stat'] != null) {
        final stat =
            Stat.fromJson(s['pokemon_v2_stat'] as Map<String, dynamic>);
        stats[stat] = s['base_stat'] as int? ?? 0;
      }
    }
    final names = <int, String>{};
    final specy = json['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
    if (specy != null) {
      for (final n
          in (specy['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
        names[n['language_id'] as int] = n['name'] as String;
      }
    }
    return LightweightPokemon(
      id: json['id'] as int,
      identifier: json['name'] as String,
      names: names,
      types: types,
      stats: stats,
    );
  }
}
