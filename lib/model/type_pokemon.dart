import 'package:poke_jerk_api/utils/string_utils.dart';

class TypePokemon {
  final int id;
  final String identifier;
  final Map<int, String> names;

  TypePokemon({required this.id, required this.identifier, required this.names});

  factory TypePokemon.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_typenames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return TypePokemon(
      id: json['id'] as int,
      identifier: json['name'] as String,
      names: names,
    );
  }

  String getTranslation(String language) => localizedName(names, language, identifier);
}
