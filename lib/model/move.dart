import 'package:poke_jerk_api/model/type_pokemon.dart';

class DamageClass {
  final int id;
  final String identifier;
  final Map<int, String> names;

  DamageClass({required this.id, required this.identifier, required this.names});

  factory DamageClass.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_movedamageclassnames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return DamageClass(
      id: json['id'] as int? ?? 0,
      identifier: json['name'] as String? ?? '',
      names: names,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }
}

class Move {
  final int id;
  final String identifier;
  final int power;
  final int pp;
  final int accuracy;
  final int priority;
  final int? generationId;
  final TypePokemon? type;
  final DamageClass? damageClass;
  final Map<int, String> names;

  Move({
    required this.id,
    required this.identifier,
    required this.power,
    required this.pp,
    required this.accuracy,
    required this.priority,
    this.generationId,
    this.type,
    this.damageClass,
    required this.names,
  });

  factory Move.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_movenames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return Move(
      id: json['id'] as int,
      identifier: json['name'] as String,
      power: json['power'] as int? ?? 0,
      pp: json['pp'] as int? ?? 0,
      accuracy: json['accuracy'] as int? ?? 0,
      priority: json['priority'] as int? ?? 0,
      generationId: (json['pokemon_v2_generation'] as Map<String, dynamic>?)?['id'] as int?,
      type: json['pokemon_v2_type'] != null
          ? TypePokemon.fromJson(json['pokemon_v2_type'] as Map<String, dynamic>)
          : null,
      damageClass: json['pokemon_v2_movedamageclass'] != null
          ? DamageClass.fromJson(json['pokemon_v2_movedamageclass'] as Map<String, dynamic>)
          : null,
      names: names,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }
}

class LearnMethod {
  final String identifier;
  final Map<int, String> names;

  LearnMethod({required this.identifier, required this.names});

  factory LearnMethod.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_movelearnmethodnames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return LearnMethod(
      identifier: json['name'] as String,
      names: names,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }
}

class PokemonMove {
  final int level;
  final int versionGroupId;
  final int generationId;
  final String versionGroupIdentifier;
  final List<String> versionIdentifiers;
  final List<int> versionIds;
  final Map<int, String> versionGroupNames;
  final Move move;
  final LearnMethod learnMethod;

  PokemonMove({
    required this.level,
    required this.versionGroupId,
    required this.generationId,
    required this.versionGroupIdentifier,
    required this.versionIdentifiers,
    required this.versionIds,
    required this.versionGroupNames,
    required this.move,
    required this.learnMethod,
  });

  String getVersionGroupName(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return versionGroupNames[langId] ?? versionGroupNames[9] ?? versionGroupIdentifier;
  }

  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    final vg = json['pokemon_v2_versiongroup'] as Map<String, dynamic>?;
    final identifier = vg?['name'] as String? ?? '';

    // Construit le nom localisé en joignant les noms des versions du groupe (ex: "Rouge/Bleu")
    final versions = vg?['pokemon_v2_versions'] as List? ?? [];
    final versionIdentifiers = versions.map((v) => v['name'] as String).toList();

    final namesByLang = <int, List<String>>{};
    for (final v in versions) {
      for (final n in (v['pokemon_v2_versionnames'] as List? ?? [])) {
        final langId = n['language_id'] as int;
        namesByLang.putIfAbsent(langId, () => []).add(n['name'] as String);
      }
    }
    final vgNames = namesByLang.map((k, v) => MapEntry(k, v.join('/')));

    return PokemonMove(
      level: json['level'] as int? ?? 0,
      versionGroupId: json['version_group_id'] as int? ?? 0,
      generationId: vg?['generation_id'] as int? ?? 0,
      versionGroupIdentifier: identifier,
      versionIdentifiers: versionIdentifiers,
      versionIds: versions.map((v) => v['id'] as int).toList(),
      versionGroupNames: vgNames,
      move: Move.fromJson(json['pokemon_v2_move'] as Map<String, dynamic>),
      learnMethod: LearnMethod.fromJson(json['pokemon_v2_movelearnmethod'] as Map<String, dynamic>),
    );
  }
}
