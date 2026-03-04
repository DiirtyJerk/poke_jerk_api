class TypePokemon {
  final int id;
  final String identifier;
  final Map<int, String> names; // language_id → name

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

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }
}
