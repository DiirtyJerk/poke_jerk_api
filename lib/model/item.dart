class Item {
  final int id;
  final String identifier;
  final int cost;
  final Map<int, String> names;
  final Map<int, String> categoryNames;
  final Map<int, String> flavorTexts;
  final List<int> generationIds;

  Item({
    required this.id,
    required this.identifier,
    required this.cost,
    required this.names,
    required this.categoryNames,
    required this.flavorTexts,
    required this.generationIds,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final names = <int, String>{};
    for (final n in (json['pokemon_v2_itemnames'] as List? ?? [])) {
      names[n['language_id'] as int] = n['name'] as String;
    }
    final categoryNames = <int, String>{};
    final cat = json['pokemon_v2_itemcategory'] as Map<String, dynamic>?;
    if (cat != null) {
      for (final n in (cat['pokemon_v2_itemcategorynames'] as List? ?? [])) {
        categoryNames[n['language_id'] as int] = n['name'] as String;
      }
    }
    final flavorTexts = <int, String>{};
    for (final n in (json['pokemon_v2_itemflavortexts'] as List? ?? [])) {
      flavorTexts[n['language_id'] as int] = n['flavor_text'] as String;
    }
    final generationIds = <int>[];
    for (final g in (json['pokemon_v2_itemgameindices'] as List? ?? [])) {
      final genId = g['generation_id'] as int?;
      if (genId != null && !generationIds.contains(genId)) {
        generationIds.add(genId);
      }
    }
    return Item(
      id: json['id'] as int,
      identifier: json['name'] as String,
      cost: json['cost'] as int? ?? 0,
      names: names,
      categoryNames: categoryNames,
      flavorTexts: flavorTexts,
      generationIds: generationIds,
    );
  }

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? identifier;
  }

  String getCategoryTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return categoryNames[langId] ?? categoryNames[9] ?? '';
  }

  String getFlavorText(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return flavorTexts[langId] ?? flavorTexts[9] ?? '';
  }

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$identifier.png';
}
