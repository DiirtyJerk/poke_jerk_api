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
  final int? parentId;
  final List<VersionGroup> dlcChildren;

  /// DLC → parent version group mapping
  static const Map<int, int> dlcParentMap = {
    21: 20, // Isle of Armor → Sword/Shield
    22: 20, // Crown Tundra → Sword/Shield
    26: 25, // The Teal Mask → Scarlet/Violet
    27: 25, // The Indigo Disk → Scarlet/Violet
  };

  /// Version group → regional form name mapping
  /// Used to pick the correct regional variant in pokédex listings
  static const Map<int, String> regionalFormMap = {
    14: 'alola',  // Sun/Moon
    15: 'alola',  // Ultra Sun/Ultra Moon
    20: 'galar',  // Sword/Shield
    21: 'galar',  // Isle of Armor
    22: 'galar',  // Crown Tundra
    24: 'hisui',  // Legends Arceus
    25: 'paldea', // Scarlet/Violet
    26: 'paldea', // Teal Mask
    27: 'paldea', // Indigo Disk
  };

  String? get regionalForm => regionalFormMap[id];

  VersionGroup({
    required this.id,
    required this.generationId,
    required this.identifier,
    required this.versionIdentifiers,
    required this.versionIds,
    required this.nameFr,
    required this.nameEn,
    required this.pokedexes,
    this.parentId,
    List<VersionGroup>? dlcChildren,
  }) : dlcChildren = dlcChildren ?? [];

  bool get isDlc => parentId != null;
  bool get hasDlc => dlcChildren.isNotEmpty;

  String getName(String language) => language == 'fr' ? nameFr : nameEn;
}
