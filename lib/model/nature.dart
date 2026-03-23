class Nature {
  final String identifier;
  final String nameFr;
  final String nameEn;
  final String? increasedStat; // null = neutral nature
  final String? decreasedStat;

  const Nature({
    required this.identifier,
    required this.nameFr,
    required this.nameEn,
    this.increasedStat,
    this.decreasedStat,
  });

  String getName(String language) => language == 'fr' ? nameFr : nameEn;

  bool get isNeutral => increasedStat == null;

  static const List<Nature> all = [
    Nature(identifier: 'hardy', nameFr: 'Hardi', nameEn: 'Hardy'),
    Nature(identifier: 'lonely', nameFr: 'Solo', nameEn: 'Lonely', increasedStat: 'attack', decreasedStat: 'defense'),
    Nature(identifier: 'brave', nameFr: 'Brave', nameEn: 'Brave', increasedStat: 'attack', decreasedStat: 'speed'),
    Nature(identifier: 'adamant', nameFr: 'Rigide', nameEn: 'Adamant', increasedStat: 'attack', decreasedStat: 'special-attack'),
    Nature(identifier: 'naughty', nameFr: 'Mauvais', nameEn: 'Naughty', increasedStat: 'attack', decreasedStat: 'special-defense'),
    Nature(identifier: 'bold', nameFr: 'Assuré', nameEn: 'Bold', increasedStat: 'defense', decreasedStat: 'attack'),
    Nature(identifier: 'docile', nameFr: 'Docile', nameEn: 'Docile'),
    Nature(identifier: 'relaxed', nameFr: 'Relax', nameEn: 'Relaxed', increasedStat: 'defense', decreasedStat: 'speed'),
    Nature(identifier: 'impish', nameFr: 'Malin', nameEn: 'Impish', increasedStat: 'defense', decreasedStat: 'special-attack'),
    Nature(identifier: 'lax', nameFr: 'Lâche', nameEn: 'Lax', increasedStat: 'defense', decreasedStat: 'special-defense'),
    Nature(identifier: 'timid', nameFr: 'Timide', nameEn: 'Timid', increasedStat: 'speed', decreasedStat: 'attack'),
    Nature(identifier: 'hasty', nameFr: 'Pressé', nameEn: 'Hasty', increasedStat: 'speed', decreasedStat: 'defense'),
    Nature(identifier: 'serious', nameFr: 'Sérieux', nameEn: 'Serious'),
    Nature(identifier: 'jolly', nameFr: 'Jovial', nameEn: 'Jolly', increasedStat: 'speed', decreasedStat: 'special-attack'),
    Nature(identifier: 'naive', nameFr: 'Naïf', nameEn: 'Naive', increasedStat: 'speed', decreasedStat: 'special-defense'),
    Nature(identifier: 'modest', nameFr: 'Modeste', nameEn: 'Modest', increasedStat: 'special-attack', decreasedStat: 'attack'),
    Nature(identifier: 'mild', nameFr: 'Doux', nameEn: 'Mild', increasedStat: 'special-attack', decreasedStat: 'defense'),
    Nature(identifier: 'quiet', nameFr: 'Discret', nameEn: 'Quiet', increasedStat: 'special-attack', decreasedStat: 'speed'),
    Nature(identifier: 'bashful', nameFr: 'Pudique', nameEn: 'Bashful'),
    Nature(identifier: 'rash', nameFr: 'Foufou', nameEn: 'Rash', increasedStat: 'special-attack', decreasedStat: 'special-defense'),
    Nature(identifier: 'calm', nameFr: 'Calme', nameEn: 'Calm', increasedStat: 'special-defense', decreasedStat: 'attack'),
    Nature(identifier: 'gentle', nameFr: 'Gentil', nameEn: 'Gentle', increasedStat: 'special-defense', decreasedStat: 'defense'),
    Nature(identifier: 'sassy', nameFr: 'Malpoli', nameEn: 'Sassy', increasedStat: 'special-defense', decreasedStat: 'speed'),
    Nature(identifier: 'careful', nameFr: 'Prudent', nameEn: 'Careful', increasedStat: 'special-defense', decreasedStat: 'special-attack'),
    Nature(identifier: 'quirky', nameFr: 'Bizarre', nameEn: 'Quirky'),
  ];

  static const statNamesFr = {
    'attack': 'Attaque',
    'defense': 'Défense',
    'speed': 'Vitesse',
    'special-attack': 'Atq. Spé.',
    'special-defense': 'Déf. Spé.',
  };

  static const statNamesEn = {
    'attack': 'Attack',
    'defense': 'Defense',
    'speed': 'Speed',
    'special-attack': 'Sp. Atk',
    'special-defense': 'Sp. Def',
  };

  static String getStatName(String stat, String language) =>
      language == 'fr' ? (statNamesFr[stat] ?? stat) : (statNamesEn[stat] ?? stat);

  /// Stats used as columns (excludes HP — natures don't affect HP)
  static const statColumns = ['attack', 'defense', 'special-attack', 'special-defense', 'speed'];
}
