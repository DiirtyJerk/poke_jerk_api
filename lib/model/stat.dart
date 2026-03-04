class Stat {
  final int id;
  final String identifier;
  final Map<int, String> names;

  Stat({required this.id, required this.identifier, required this.names});

  factory Stat.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_statnames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    return Stat(
      id: json['id'] as int? ?? 0,
      identifier: json['name'] as String,
      names: names,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }
}
