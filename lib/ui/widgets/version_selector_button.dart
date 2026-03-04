import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/move.dart';
import 'package:poke_jerk_api/ui/widgets/version_group_chip.dart';

/// Bouton + bottom sheet de sélection de version.
/// Utilisé dans les onglets Capacités et Évolutions.
class VersionSelectorButton extends StatelessWidget {
  final List<MapEntry<int, PokemonMove>> versionGroups;
  final int? selectedId;
  final String language;
  final ValueChanged<int> onSelected;

  const VersionSelectorButton({
    super.key,
    required this.versionGroups,
    required this.selectedId,
    required this.language,
    required this.onSelected,
  });

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        language == 'fr' ? 'Filtrer par version' : 'Filter by version',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    if (selectedId != null)
                      TextButton(
                        onPressed: () {
                          onSelected(-1);
                          Navigator.pop(ctx);
                        },
                        child: Text(language == 'fr' ? 'Effacer' : 'Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: versionGroups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final entry = versionGroups[index];
                      final move = entry.value;
                      final isSelected = entry.key == selectedId;
                      final label = move.getVersionGroupName(language);
                      return AnimatedOpacity(
                        opacity: selectedId != null && !isSelected ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: GestureDetector(
                          onTap: () {
                            onSelected(entry.key);
                            Navigator.pop(ctx);
                          },
                          child: VersionGroupChip(
                            label: label,
                            versionIdentifiers: move.versionIdentifiers,
                            fillWidth: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMove = selectedId != null
        ? versionGroups.cast<MapEntry<int, PokemonMove>?>()
            .firstWhere((e) => e?.key == selectedId, orElse: () => null)
            ?.value
        : null;

    final label = selectedMove?.getVersionGroupName(language)
        ?? (language == 'fr' ? 'Version' : 'Version');
    final versionIds = selectedMove?.versionIdentifiers ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Center(
        child: GestureDetector(
          onTap: () => _showSheet(context),
          child: selectedMove != null
              ? VersionGroupChip(label: label, versionIdentifiers: versionIds)
              : Chip(
                  avatar: const Icon(Icons.sports_esports_outlined, size: 16, color: Colors.black87),
                  label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
        ),
      ),
    );
  }
}
