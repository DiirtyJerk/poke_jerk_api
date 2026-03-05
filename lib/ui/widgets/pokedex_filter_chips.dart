import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/pokedex_filter_data.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/version_group_chip.dart';
import 'package:provider/provider.dart';

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
  final VersionGroup? dlcSelected;

  const VersionChip({
    super.key,
    required this.label,
    this.selected,
    this.dlcSelected,
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

    // DLC selected: show parent colors + DLC badge
    if (dlcSelected != null) {
      return _DlcVersionChip(
        parentGroup: selected!,
        dlcGroup: dlcSelected!,
      );
    }

    return VersionGroupChip(
      label: label,
      versionIdentifiers: selected!.versionIdentifiers,
      icon: Icons.sports_esports_outlined,
    );
  }
}

class _DlcVersionChip extends StatelessWidget {
  final VersionGroup parentGroup;
  final VersionGroup dlcGroup;

  const _DlcVersionChip({
    required this.parentGroup,
    required this.dlcGroup,
  });

  Color _textOn(Color bg) => ColorBuilder.textColorOn(bg);

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final parentLabel = parentGroup.getName(language);
    final dlcLabel = dlcGroup.getName(language);

    final parentParts = parentLabel.split('/').map((s) => s.trim()).toList();
    final parentColors = parentGroup.versionIdentifiers
        .map((id) => ColorBuilder.getVersionColor(id))
        .toList();
    if (parentColors.isEmpty) parentColors.add(Colors.blueGrey);

    final dlcColor = ColorBuilder.getVersionGroupColor(dlcGroup.identifier);

    const double iconWidth = 26;

    return IntrinsicWidth(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDDDDD)),
          ),
          position: DecorationPosition.foreground,
          child: ColoredBox(
            color: dlcColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Line 1: game icon + parent version colored sections
              IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: iconWidth,
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: const Icon(Icons.sports_esports_outlined, size: 14, color: Colors.black87),
                    ),
                    Container(width: 1, color: const Color(0xFFDDDDDD)),
                    for (int i = 0; i < parentParts.length; i++) ...[
                      if (i > 0) Container(width: 1, color: Colors.white24),
                      Expanded(
                        child: Container(
                          color: parentColors[i < parentColors.length ? i : parentColors.length - 1],
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          alignment: Alignment.center,
                          child: Text(
                            parentParts[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _textOn(parentColors[i < parentColors.length ? i : parentColors.length - 1]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFDDDDDD)),
              // Line 2: puzzle icon + DLC colored section
              IntrinsicHeight(
                child: ColoredBox(
                  color: dlcColor,
                  child: Row(
                    children: [
                      Container(
                        width: iconWidth,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Icon(Icons.extension_outlined, size: 14, color: Colors.black87),
                      ),
                      Container(width: 1, color: const Color(0xFFDDDDDD)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: Text(
                            dlcLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _textOn(dlcColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
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
    Color textColorFor(Color bg) => ColorBuilder.textColorOn(bg);

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
