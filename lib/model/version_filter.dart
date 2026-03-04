/// Filtre de version sélectionné dans le Pokédex,
/// transmis aux onglets Capacités, Évolutions et Localisations du détail.
class VersionFilter {
  /// ID du groupe de versions (ex: 1 pour Rouge/Bleu) — utilisé par les capacités.
  final int versionGroupId;

  /// Identifiants des versions individuelles (ex: ['red', 'blue']) — utilisé par les localisations.
  final List<String> versionIdentifiers;

  /// ID du Pokédex régional sélectionné — utilisé par les évolutions.
  final int? pokedexId;

  /// ID de génération du groupe de versions — utilisé par les évolutions.
  final int generationId;

  const VersionFilter({
    required this.versionGroupId,
    required this.versionIdentifiers,
    this.pokedexId,
    required this.generationId,
  });
}
