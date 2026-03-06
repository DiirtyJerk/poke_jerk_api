import 'dart:convert';
import 'package:poke_jerk_api/model/encounter.dart';
import 'package:poke_jerk_api/model/evolution.dart';
import 'package:poke_jerk_api/model/move.dart';
import 'package:poke_jerk_api/model/stat.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';

class PokemonForm {
  final int id;
  final String identifier;
  final bool isBattleOnly;
  final bool isMega;
  final Map<int, String> names;

  PokemonForm({
    required this.id,
    required this.identifier,
    required this.isBattleOnly,
    required this.isMega,
    required this.names,
  });

  factory PokemonForm.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_pokemonformnames'] as List? ?? [])) {
      final pokemonName = n['pokemon_name'] as String?;
      if (pokemonName != null && pokemonName.isNotEmpty) {
        names[n['language_id'] as int] = pokemonName;
      } else {
        names[n['language_id'] as int] = n['name'] as String? ?? '';
      }
    }
    return PokemonForm(
      id: json['id'] as int,
      identifier: json['name'] as String,
      isBattleOnly: json['is_battle_only'] as bool? ?? false,
      isMega: json['is_mega'] as bool? ?? false,
      names: names,
    );
  }

  String getTranslation(String language) => localizedName(names, language, identifier);
}

class PokemonSpecies {
  final int id;
  final int generationId;
  final int evolutionChainId;
  final bool isLegendary;
  final bool isMythical;
  final bool isBaby;
  final int genderRate;
  final double captureRate;
  final Map<int, String> names;
  final Map<int, String> genus;
  final List<EvolutionDetail> evolutions;

  PokemonSpecies({
    required this.id,
    required this.generationId,
    required this.evolutionChainId,
    required this.isLegendary,
    required this.isMythical,
    required this.isBaby,
    required this.genderRate,
    required this.captureRate,
    required this.names,
    required this.genus,
    required this.evolutions,
  });

  factory PokemonSpecies.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    final genus = <int, String>{};
    for (final n in (json['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
      final langId = n['language_id'] as int;
      final name = n['name'] as String? ?? '';
      final g = n['genus'] as String? ?? '';
      if (name.isNotEmpty) names[langId] = name;
      if (g.isNotEmpty) genus[langId] = g;
    }

    final evolutions = <EvolutionDetail>[];
    final chain = json['pokemon_v2_evolutionchain'] as Map<String, dynamic>?;
    if (chain != null) {
      // Construire une map espèce par id pour retrouver le "from"
      final chainSpecies = chain['pokemon_v2_pokemonspecies'] as List? ?? [];
      final speciesById = <int, Map<String, dynamic>>{};
      for (final s in chainSpecies) {
        speciesById[s['id'] as int] = s as Map<String, dynamic>;
      }
      // Chaque espèce expose les évolutions qui LA produisent
      for (final s in chainSpecies) {
        final toSpeciesJson = s as Map<String, dynamic>;
        final evolveFromId = toSpeciesJson['evolves_from_species_id'] as int?;
        final fromSpeciesJson = evolveFromId != null ? speciesById[evolveFromId] : null;
        for (final e in (toSpeciesJson['pokemon_v2_pokemonevolutions'] as List? ?? [])) {
          final evoMap = Map<String, dynamic>.from(e as Map<String, dynamic>);
          evoMap['_toSpeciesJson'] = toSpeciesJson;
          evoMap['_fromSpeciesJson'] = fromSpeciesJson;
          evolutions.add(EvolutionDetail.fromJson(evoMap));
        }
      }
    }

    return PokemonSpecies(
      id: json['id'] as int? ?? 0,
      generationId: json['generation_id'] as int? ?? 0,
      evolutionChainId: json['evolution_chain_id'] as int? ?? 0,
      isLegendary: json['is_legendary'] as bool? ?? false,
      isMythical: json['is_mythical'] as bool? ?? false,
      isBaby: json['is_baby'] as bool? ?? false,
      genderRate: json['gender_rate'] as int? ?? -1,
      captureRate: double.parse(
        (((json['capture_rate'] as int? ?? 0) / 255) * 100).toStringAsFixed(2),
      ),
      names: names,
      genus: genus,
      evolutions: evolutions,
    );
  }

  String getTranslation(String language) => localizedName(names, language, '');
  String getGenus(String language) => localizedName(genus, language, '');
}

class PokemonVariant {
  final int id;
  final String identifier;
  final String formName;
  final Map<int, String> names;
  final List<TypePokemon> types;
  final bool isDefault;

  PokemonVariant({
    required this.id,
    required this.identifier,
    required this.formName,
    required this.names,
    required this.types,
    required this.isDefault,
  });

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get shinySpriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$id.png';

  String getTranslation(String language) => localizedName(names, language, identifier);

  factory PokemonVariant.fromJson(Map<String, dynamic> json) {
    final formsList = json['pokemon_v2_pokemonforms'] as List? ?? [];
    final firstForm = formsList.isNotEmpty ? formsList.first as Map<String, dynamic> : null;
    final formName = firstForm?['form_name'] as String? ?? '';
    final names = <int, String>{};
    if (firstForm != null) {
      for (final n in (firstForm['pokemon_v2_pokemonformnames'] as List? ?? [])) {
        final pokemonName = n['pokemon_name'] as String?;
        if (pokemonName != null && pokemonName.isNotEmpty) {
          names[n['language_id'] as int] = pokemonName;
        } else {
          final name = n['name'] as String?;
          if (name != null && name.isNotEmpty) {
            names[n['language_id'] as int] = name;
          }
        }
      }
    }

    final types = <TypePokemon>[];
    for (final t in (json['pokemon_v2_pokemontypes'] as List? ?? [])) {
      if (t['pokemon_v2_type'] != null) {
        types.add(TypePokemon.fromJson(t['pokemon_v2_type'] as Map<String, dynamic>));
      }
    }

    return PokemonVariant(
      id: json['id'] as int,
      identifier: json['name'] as String,
      formName: formName,
      names: names,
      types: types,
      isDefault: json['is_default'] as bool? ?? true,
    );
  }
}

class Pokemon {
  final int id;
  final String identifier;
  final double height;
  final double weight;
  final int baseExperience;
  final bool isDefault;
  final List<TypePokemon> types;
  final Map<Stat, int> stats;
  final List<PokemonMove> moves;
  final List<PokemonForm> forms;
  final PokemonSpecies? species;
  final List<LocationEncounter> encounters;
  final String? spriteUrl;
  final int? generationId;
  final int? pokedexNumber;
  final List<PokemonVariant> variants;

  Pokemon({
    required this.id,
    required this.identifier,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.isDefault,
    required this.types,
    required this.stats,
    required this.moves,
    required this.forms,
    this.species,
    required this.encounters,
    this.spriteUrl,
    this.generationId,
    this.pokedexNumber,
    this.variants = const [],
  });

  String get officialArtworkUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get displayId {
    String s = '#$id';
    while (s.length < 5) { s = s.replaceFirst('#', '#0'); }
    return s;
  }

  String getTranslation(String language) {
    return species?.getTranslation(language) ?? identifier;
  }

  /// Construit depuis la query liste (données partielles)
  factory Pokemon.fromListJson(Map<String, dynamic> json) {
    final types = <TypePokemon>[];
    for (final t in (json['pokemon_v2_pokemontypes'] as List? ?? [])) {
      types.add(TypePokemon.fromJson(t['pokemon_v2_type'] as Map<String, dynamic>));
    }

    String? spriteUrl;
    final spritesRaw = json['pokemon_v2_pokemonsprites'] as List?;
    if (spritesRaw != null && spritesRaw.isNotEmpty) {
      final spritesJson = spritesRaw.first['sprites'];
      Map<String, dynamic> spritesMap = {};
      if (spritesJson is String) {
        spritesMap = jsonDecode(spritesJson) as Map<String, dynamic>;
      } else if (spritesJson is Map<String, dynamic>) {
        spritesMap = spritesJson;
      }
      spriteUrl = (spritesMap['other'] as Map<String, dynamic>?)?['official-artwork']
              ?['front_default'] as String?;
    }

    // Construire une espèce minimale pour avoir les noms traduits
    final specyJson = json['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
    PokemonSpecies? species;
    if (specyJson != null) {
      species = PokemonSpecies.fromJson(specyJson);
    }

    return Pokemon(
      id: json['id'] as int,
      identifier: json['name'] as String,
      height: 0,
      weight: 0,
      baseExperience: 0,
      isDefault: true,
      types: types,
      stats: {},
      moves: [],
      forms: [],
      species: species,
      encounters: [],
      spriteUrl: spriteUrl,
      generationId: specyJson?['generation_id'] as int?,
      pokedexNumber: json['pokedex_number'] as int?,
    );
  }

  /// Construit depuis la query détail (données complètes)
  factory Pokemon.fromDetailJson(Map<String, dynamic> json) {
    final types = <TypePokemon>[];
    for (final t in (json['pokemon_v2_pokemontypes'] as List? ?? [])) {
      if (t['pokemon_v2_type'] != null) {
        types.add(TypePokemon.fromJson(t['pokemon_v2_type'] as Map<String, dynamic>));
      }
    }

    final stats = <Stat, int>{};
    for (final s in (json['pokemon_v2_pokemonstats'] as List? ?? [])) {
      if (s['pokemon_v2_stat'] != null) {
        final stat = Stat.fromJson(s['pokemon_v2_stat'] as Map<String, dynamic>);
        stats[stat] = s['base_stat'] as int? ?? 0;
      }
    }

    final moves = <PokemonMove>[];
    for (final m in (json['pokemon_v2_pokemonmoves'] as List? ?? [])) {
      // Ignorer les entrées avec move ou learnMethod nuls pour éviter une TypeError
      if (m['pokemon_v2_move'] != null && m['pokemon_v2_movelearnmethod'] != null) {
        moves.add(PokemonMove.fromJson(m as Map<String, dynamic>));
      }
    }

    final forms = <PokemonForm>[];
    for (final f in (json['pokemon_v2_pokemonforms'] as List? ?? [])) {
      forms.add(PokemonForm.fromJson(f as Map<String, dynamic>));
    }

    final encounters = <LocationEncounter>[];
    for (final e in (json['pokemon_v2_encounters'] as List? ?? [])) {
      encounters.add(LocationEncounter.fromJson(e as Map<String, dynamic>));
    }

    PokemonSpecies? species;
    final specyJson = json['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
    if (specyJson != null) {
      species = PokemonSpecies.fromJson(specyJson);
    }

    // Parse variants (all forms of the same species)
    final variants = <PokemonVariant>[];
    if (specyJson != null) {
      for (final p in (specyJson['pokemon_v2_pokemons'] as List? ?? [])) {
        try {
          variants.add(PokemonVariant.fromJson(p as Map<String, dynamic>));
        } catch (_) {
          // Skip malformed variant entries
        }
      }
    }

    return Pokemon(
      id: json['id'] as int,
      identifier: json['name'] as String,
      height: ((json['height'] as int? ?? 0) / 10),
      weight: ((json['weight'] as int? ?? 0) / 10),
      baseExperience: json['base_experience'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? true,
      types: types,
      stats: stats,
      moves: moves,
      forms: forms,
      species: species,
      encounters: encounters,
      spriteUrl: null,
      generationId: species?.generationId,
      variants: variants,
    );
  }
}
