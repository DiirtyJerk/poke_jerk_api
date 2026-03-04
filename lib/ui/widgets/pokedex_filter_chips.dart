import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/pokedex_filter_data.dart';
import 'package:poke_jerk_api/ui/widgets/version_group_chip.dart';

class FilterChip2 extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData icon;

  const FilterChip2({
    super.key,
    required this.label,
    required this.isActive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFCC0000);
    final borderColor = isActive ? activeColor : const Color(0xFFDDDDDD);
    final textColor = isActive ? activeColor : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class VersionChip extends StatelessWidget {
  final String label;
  final VersionGroup? selected;

  const VersionChip({
    super.key,
    required this.label,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (selected == null || selected!.versionIdentifiers.isEmpty) {
      return FilterChip2(
        label: label,
        isActive: false,
        icon: Icons.sports_esports_outlined,
      );
    }
    return VersionGroupChip(
      label: label,
      versionIdentifiers: selected!.versionIdentifiers,
      icon: Icons.sports_esports_outlined,
    );
  }
}

class SplitChip extends StatelessWidget {
  final IconData icon;
  final List<String> labels;
  final List<Color> colors;

  const SplitChip({
    super.key,
    required this.icon,
    required this.labels,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    Color textColorFor(Color bg) =>
        bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

    final coloredSections = <Widget>[];
    for (int i = 0; i < labels.length; i++) {
      final color = colors[i < colors.length ? i : colors.length - 1];
      if (i > 0) {
        coloredSections.add(Container(width: 1, color: Colors.white24));
      }
      coloredSections.add(
        Container(
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          child: Text(
            labels[i],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColorFor(color),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(icon, size: 14, color: Colors.black87),
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
