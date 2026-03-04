class Generation {
  final int id;
  final String name;
  const Generation({required this.id, required this.name});
}

class PokedexEntry {
  final int id;
  final String name;
  const PokedexEntry({required this.id, required this.name});
}

class VersionGroup {
  final int id;
  final int generationId;
  final String identifier;
  final List<String> versionIdentifiers;
  final List<int> versionIds;
  final String nameFr;
  final String nameEn;
  final List<PokedexEntry> pokedexes;

  VersionGroup({
    required this.id,
    required this.generationId,
    required this.identifier,
    required this.versionIdentifiers,
    required this.versionIds,
    required this.nameFr,
    required this.nameEn,
    required this.pokedexes,
  });

  String getName(String language) => language == 'fr' ? nameFr : nameEn;
}
