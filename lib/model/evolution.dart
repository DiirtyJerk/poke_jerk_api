import 'package:poke_jerk_api/model/type_pokemon.dart';

/// Helper pour parser une entité avec nom localisé (item, lieu, attaque, espèce...).
class NamedRef {
  final String identifier;
  final Map<int, String> names;

  NamedRef({required this.identifier, required this.names});

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }

  /// Parse un JSON avec `name` + une liste de noms localisés.
  static NamedRef? parse(Map<String, dynamic>? json, String namesKey) {
    if (json == null) return null;
    final names = <int, String>{};
    for (final n in (json[namesKey] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return NamedRef(
      identifier: json['name'] as String? ?? '',
      names: names,
    );
  }
}

class EvolutionItem {
  final int id;
  final String identifier;
  final Map<int, String> names;

  EvolutionItem({required this.id, required this.identifier, required this.names});

  factory EvolutionItem.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_itemnames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return EvolutionItem(
      id: json['id'] as int,
      identifier: json['name'] as String,
      names: names,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }
}

class EvolutionTrigger {
  final String identifier;
  final Map<int, String> names;

  EvolutionTrigger({required this.identifier, required this.names});

  factory EvolutionTrigger.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_evolutiontriggernames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return EvolutionTrigger(
      identifier: json['name'] as String,
      names: names,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }
}

class PokemonFormVariant {
  final int pokemonId;
  final bool isDefault;
  final String formName;
  final List<TypePokemon> types;

  PokemonFormVariant({
    required this.pokemonId,
    required this.isDefault,
    required this.formName,
    required this.types,
  });
}

class SpeciesRef {
  final int pokemonId;
  final int generationId;
  final Map<int, String> names;
  final Set<int> pokedexIds;
  final List<TypePokemon> types;
  final List<PokemonFormVariant> forms;

  SpeciesRef({
    required this.pokemonId,
    required this.generationId,
    required this.names,
    this.pokedexIds = const {},
    this.types = const [],
    this.forms = const [],
  });

  /// Returns a copy of this SpeciesRef with the form matching [formName].
  /// Falls back to the default form if no match is found.
  SpeciesRef withForm(String formName) {
    if (formName.isEmpty) return this;
    final match = forms.cast<PokemonFormVariant?>().firstWhere(
      (f) => f?.formName == formName,
      orElse: () => null,
    );
    if (match == null || match.pokemonId == pokemonId) return this;
    return SpeciesRef(
      pokemonId: match.pokemonId,
      generationId: generationId,
      names: names,
      pokedexIds: pokedexIds,
      types: match.types,
      forms: forms,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? '';
  }
}

class EvolutionDetail {
  final int id;
  final int evolvedSpeciesId;
  final int minLevel;
  final int minHappiness;
  final int minBeauty;
  final int minAffection;
  final int? genderId;
  final String? timeOfDay;
  final bool needsOverworldRain;
  final bool turnUpsideDown;
  final int? relativePhysicalStats;
  final EvolutionTrigger? trigger;
  final EvolutionItem? item;
  final EvolutionItem? heldItem;
  final NamedRef? location;
  final NamedRef? knownMove;
  final NamedRef? knownMoveType;
  final NamedRef? partySpecies;
  final NamedRef? tradeSpecies;
  final NamedRef? partyType;
  final SpeciesRef? fromSpecies;
  final SpeciesRef? toSpecies;

  EvolutionDetail({
    required this.id,
    required this.evolvedSpeciesId,
    required this.minLevel,
    required this.minHappiness,
    required this.minBeauty,
    required this.minAffection,
    this.genderId,
    this.timeOfDay,
    required this.needsOverworldRain,
    required this.turnUpsideDown,
    this.relativePhysicalStats,
    this.trigger,
    this.item,
    this.heldItem,
    this.location,
    this.knownMove,
    this.knownMoveType,
    this.partySpecies,
    this.tradeSpecies,
    this.partyType,
    this.fromSpecies,
    this.toSpecies,
  });

  static SpeciesRef? _refFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    final pokemons = json['pokemon_v2_pokemons'] as List? ?? [];
    final generationId = json['generation_id'] as int? ?? 0;
    final pokedexIds = <int>{};
    for (final d in (json['pokemon_v2_pokemondexnumbers'] as List? ?? [])) {
      pokedexIds.add(d['pokedex_id'] as int);
    }

    // Parse all forms
    final forms = <PokemonFormVariant>[];
    int defaultPokemonId = 0;
    var defaultTypes = <TypePokemon>[];

    for (final p in pokemons) {
      final pId = p['id'] as int;
      final isDefault = p['is_default'] as bool? ?? false;
      final formsList = p['pokemon_v2_pokemonforms'] as List? ?? [];
      final formName = formsList.isNotEmpty
          ? (formsList.first['form_name'] as String? ?? '')
          : '';
      final pTypes = <TypePokemon>[];
      for (final pt in (p['pokemon_v2_pokemontypes'] as List? ?? [])) {
        pTypes.add(TypePokemon.fromJson(pt['pokemon_v2_type'] as Map<String, dynamic>));
      }
      forms.add(PokemonFormVariant(
        pokemonId: pId,
        isDefault: isDefault,
        formName: formName,
        types: pTypes,
      ));
      if (isDefault) {
        defaultPokemonId = pId;
        defaultTypes = pTypes;
      }
    }

    // Fallback if no default found
    if (defaultPokemonId == 0 && pokemons.isNotEmpty) {
      defaultPokemonId = pokemons.first['id'] as int;
      defaultTypes = forms.isNotEmpty ? forms.first.types : [];
    }

    return SpeciesRef(
      pokemonId: defaultPokemonId,
      generationId: generationId,
      names: names,
      pokedexIds: pokedexIds,
      types: defaultTypes,
      forms: forms,
    );
  }

  /// Clé unique pour identifier les doublons (même cible + mêmes conditions).
  String get dedupeKey {
    return '${evolvedSpeciesId}_${trigger?.identifier}_${item?.id}_${heldItem?.id}'
        '_${location?.identifier}_${knownMove?.identifier}_${knownMoveType?.identifier}'
        '_${minLevel}_${genderId}_$timeOfDay';
  }

  factory EvolutionDetail.fromJson(Map<String, dynamic> json) {
    final fromSpecies = _refFromJson(json['_fromSpeciesJson'] as Map<String, dynamic>?);
    final toSpecies   = _refFromJson(json['_toSpeciesJson']   as Map<String, dynamic>?);

    return EvolutionDetail(
      id: json['id'] as int,
      evolvedSpeciesId: json['evolved_species_id'] as int? ?? 0,
      minLevel: json['min_level'] as int? ?? 0,
      minHappiness: json['min_happiness'] as int? ?? 0,
      minBeauty: json['min_beauty'] as int? ?? 0,
      minAffection: json['min_affection'] as int? ?? 0,
      genderId: json['gender_id'] as int?,
      timeOfDay: json['time_of_day'] as String?,
      needsOverworldRain: (json['needs_overworld_rain'] as bool?) ?? false,
      turnUpsideDown: (json['turn_upside_down'] as bool?) ?? false,
      relativePhysicalStats: json['relative_physical_stats'] as int?,
      trigger: json['pokemon_v2_evolutiontrigger'] != null
          ? EvolutionTrigger.fromJson(json['pokemon_v2_evolutiontrigger'] as Map<String, dynamic>)
          : null,
      item: json['pokemon_v2_item'] != null
          ? EvolutionItem.fromJson(json['pokemon_v2_item'] as Map<String, dynamic>)
          : null,
      heldItem: json['pokemonV2ItemByHeldItemId'] != null
          ? EvolutionItem.fromJson(json['pokemonV2ItemByHeldItemId'] as Map<String, dynamic>)
          : null,
      location: NamedRef.parse(
        json['pokemon_v2_location'] as Map<String, dynamic>?,
        'pokemon_v2_locationnames',
      ),
      knownMove: NamedRef.parse(
        json['pokemon_v2_move'] as Map<String, dynamic>?,
        'pokemon_v2_movenames',
      ),
      knownMoveType: NamedRef.parse(
        json['pokemon_v2_type'] as Map<String, dynamic>?,
        'pokemon_v2_typenames',
      ),
      partySpecies: NamedRef.parse(
        json['pokemonV2PokemonspecyByPartySpeciesId'] as Map<String, dynamic>?,
        'pokemon_v2_pokemonspeciesnames',
      ),
      tradeSpecies: NamedRef.parse(
        json['pokemonV2PokemonspecyByTradeSpeciesId'] as Map<String, dynamic>?,
        'pokemon_v2_pokemonspeciesnames',
      ),
      partyType: NamedRef.parse(
        json['pokemonV2TypeByPartyTypeId'] as Map<String, dynamic>?,
        'pokemon_v2_typenames',
      ),
      fromSpecies: fromSpecies,
      toSpecies: toSpecies,
    );
  }

  String getTriggerDescription(String language) {
    String desc = trigger?.getTranslation(language) ?? '';
    if (item != null) desc += '\n${item!.getTranslation(language)}';
    if (minLevel > 0) desc += '\nNiv. $minLevel';
    if (genderId == 1) desc += language == 'fr' ? '\nFemelle' : '\nFemale';
    if (genderId == 2) desc += language == 'fr' ? '\nMâle' : '\nMale';
    if (timeOfDay == 'day') desc += language == 'fr' ? '\nJour' : '\nDay';
    if (timeOfDay == 'night') desc += language == 'fr' ? '\nNuit' : '\nNight';
    if (timeOfDay == 'dusk') desc += language == 'fr' ? '\nCrépuscule' : '\nDusk';
    if (minHappiness > 0) desc += '\nBonheur >=$minHappiness';
    if (turnUpsideDown) desc += language == 'fr' ? '\nRetourner la console' : '\nTurn upside down';
    return desc;
  }
}
