import 'package:flutter/material.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';

/// Chip de groupe de version : même design split que le sélecteur du Pokédex.
/// Gauche : fond blanc + icône noire. Droite : sections colorées par version.
/// [fillWidth] : si true, les sections colorées s'étirent pour remplir la largeur disponible.
class VersionGroupChip extends StatelessWidget {
  final String label;
  final List<String> versionIdentifiers;
  final IconData icon;
  final bool fillWidth;

  const VersionGroupChip({
    super.key,
    required this.label,
    required this.versionIdentifiers,
    this.icon = Icons.sports_esports_outlined,
    this.fillWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sections colorées : une par version identifiée
    final parts = label.split('/');
    final colors = versionIdentifiers
        .map((id) => ColorBuilder.getVersionColor(id))
        .toList();
    if (colors.isEmpty) colors.add(Colors.blueGrey);

    Color textColorFor(Color bg) => ColorBuilder.textColorOn(bg);

    final coloredSections = <Widget>[];
    for (int i = 0; i < parts.length; i++) {
      final color = colors[i < colors.length ? i : colors.length - 1];
      if (i > 0) {
        coloredSections.add(Container(width: 1, color: Colors.white24));
      }
      final section = Container(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          parts[i],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColorFor(color),
          ),
        ),
      );
      coloredSections.add(fillWidth ? Expanded(child: section) : section);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(icon, size: 16, color: Colors.black87),
              ),
              Container(width: 1, color: const Color(0xFFDDDDDD)),
              ...coloredSections,
            ],
          ),
        ),
      ),
    );
  }
}
