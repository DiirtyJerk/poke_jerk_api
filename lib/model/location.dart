import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';

class GameLocation {
  final int id;
  final String identifier;
  final Map<int, String> names;
  final int? regionId;
  final Map<int, String> regionNames;
  final Set<int> versionIds;

  GameLocation({
    required this.id,
    required this.identifier,
    required this.names,
    this.regionId,
    this.regionNames = const {},
    this.versionIds = const {},
  });

  String getTranslation(String language) => localizedName(names, language, identifier);
  String getRegionTranslation(String language) => localizedName(regionNames, language, '');

  factory GameLocation.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_locationnames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    final regionJson = json['pokemon_v2_region'] as Map<String, dynamic>?;
    final regionNames = <int, String>{};
    int? regionId;
    if (regionJson != null) {
      regionId = regionJson['id'] as int?;
      for (final n in (regionJson['pokemon_v2_regionnames'] as List? ?? [])) {
        regionNames[n['language_id'] as int] = n['name'] as String;
      }
    }
    final versionIds = <int>{};
    for (final area in (json['pokemon_v2_locationareas'] as List? ?? [])) {
      for (final enc in (area['pokemon_v2_encounters'] as List? ?? [])) {
        final vid = enc['version_id'] as int?;
        if (vid != null) versionIds.add(vid);
      }
    }

    return GameLocation(
      id: json['id'] as int,
      identifier: json['name'] as String? ?? '',
      names: names,
      regionId: regionId,
      regionNames: regionNames,
      versionIds: versionIds,
    );
  }
}

class LocationPokemonEncounter {
  final int pokemonId;
  final String pokemonIdentifier;
  final Map<int, String> pokemonNames;
  final List<TypePokemon> pokemonTypes;
  final int versionId;
  final String versionIdentifier;
  final Map<int, String> versionNames;
  final String methodIdentifier;
  final Map<int, String> methodNames;
  final int slotId;
  final int minLevel;
  final int maxLevel;
  final int chance;

  LocationPokemonEncounter({
    required this.pokemonId,
    required this.pokemonIdentifier,
    required this.pokemonNames,
    required this.pokemonTypes,
    required this.versionId,
    required this.versionIdentifier,
    required this.versionNames,
    required this.methodIdentifier,
    required this.methodNames,
    required this.slotId,
    required this.minLevel,
    required this.maxLevel,
    required this.chance,
  });

  String getPokemonName(String language) => localizedName(pokemonNames, language, pokemonIdentifier);
  String getVersionName(String language) => localizedName(versionNames, language, versionIdentifier);
  String getMethodName(String language) => localizedName(methodNames, language, methodIdentifier);

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png';

  factory LocationPokemonEncounter.fromJson(Map<String, dynamic> json) {
    final pokemonJson = json['pokemon_v2_pokemon'] as Map<String, dynamic>? ?? {};
    final pokemonId = pokemonJson['id'] as int? ?? json['pokemon_id'] as int? ?? 0;
    final pokemonIdentifier = pokemonJson['name'] as String? ?? '';

    final pokemonNames = <int, String>{};
    final specyJson = pokemonJson['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
    if (specyJson != null) {
      for (final n in (specyJson['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
        pokemonNames[n['language_id'] as int] = n['name'] as String;
      }
    }

    final pokemonTypes = <TypePokemon>[];
    for (final t in (pokemonJson['pokemon_v2_pokemontypes'] as List? ?? [])) {
      if (t['pokemon_v2_type'] != null) {
        pokemonTypes.add(TypePokemon.fromJson(t['pokemon_v2_type'] as Map<String, dynamic>));
      }
    }

    final versionJson = json['pokemon_v2_version'] as Map<String, dynamic>? ?? {};
    final versionId = versionJson['id'] as int? ?? 0;
    final versionIdentifier = versionJson['name'] as String? ?? '';
    final versionNames = <int, String>{};
    for (final n in (versionJson['pokemon_v2_versionnames'] as List? ?? [])) {
      versionNames[n['language_id'] as int] = n['name'] as String;
    }

    final slotJson = json['pokemon_v2_encounterslot'] as Map<String, dynamic>? ?? {};
    final slotId = json['encounter_slot_id'] as int? ?? 0;
    final chance = slotJson['rarity'] as int? ?? 0;
    final methodJson = slotJson['pokemon_v2_encountermethod'] as Map<String, dynamic>? ?? {};
    final methodIdentifier = methodJson['name'] as String? ?? '';
    final methodNames = <int, String>{};
    for (final n in (methodJson['pokemon_v2_encountermethodnames'] as List? ?? [])) {
      methodNames[n['language_id'] as int] = n['name'] as String;
    }

    return LocationPokemonEncounter(
      pokemonId: pokemonId,
      pokemonIdentifier: pokemonIdentifier,
      pokemonNames: pokemonNames,
      pokemonTypes: pokemonTypes,
      versionId: versionId,
      versionIdentifier: versionIdentifier,
      versionNames: versionNames,
      methodIdentifier: methodIdentifier,
      methodNames: methodNames,
      minLevel: json['min_level'] as int? ?? 0,
      maxLevel: json['max_level'] as int? ?? 0,
      slotId: slotId,
      chance: chance,
    );
  }
}
