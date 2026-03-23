import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/nature.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:provider/provider.dart';

class NaturesPage extends StatefulWidget {
  const NaturesPage({super.key});

  @override
  State<NaturesPage> createState() => _NaturesPageState();
}

class _NaturesPageState extends State<NaturesPage> {
  String? _selectedStat; // filter by increased stat

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stats = Nature.statColumns;
    final natures = _selectedStat != null
        ? Nature.all.where((n) => n.increasedStat == _selectedStat).toList()
        : Nature.all;

    const cellW = 56.0;
    const cellH = 36.0;
    const nameW = 80.0;

    return Column(
      children: [
        // Stat filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              FilterChip(
                label: Text(language == 'fr' ? 'Toutes' : 'All', style: const TextStyle(fontSize: 11)),
                selected: _selectedStat == null,
                onSelected: (_) => setState(() => _selectedStat = null),
                visualDensity: VisualDensity.compact,
              ),
              ...stats.map((s) => FilterChip(
                    label: Text(Nature.getStatName(s, language), style: const TextStyle(fontSize: 11)),
                    selected: _selectedStat == s,
                    onSelected: (_) => setState(() => _selectedStat = _selectedStat == s ? null : s),
                    visualDensity: VisualDensity.compact,
                  )),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: nameW,
                        height: cellH,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        ),
                        child: Text(
                          'Nature',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      ...stats.map((s) => Container(
                            width: cellW,
                            height: cellH,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              border: Border(
                                left: BorderSide(color: theme.dividerColor, width: 0.5),
                              ),
                            ),
                            child: Text(
                              Nature.getStatName(s, language),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )),
                    ],
                  ),
                  // Nature rows
                  ...natures.map((nature) {
                    return Row(
                      children: [
                        Container(
                          width: nameW,
                          height: cellH,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
                          ),
                          child: Text(
                            nature.getName(language),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: nature.isNeutral ? FontWeight.normal : FontWeight.w600,
                              color: nature.isNeutral
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ...stats.map((stat) {
                          final isUp = nature.increasedStat == stat;
                          final isDown = nature.decreasedStat == stat;

                          Color? bg;
                          Color textColor = theme.colorScheme.onSurface;
                          IconData? icon;

                          if (isUp) {
                            bg = isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9);
                            textColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
                            icon = Icons.arrow_upward;
                          } else if (isDown) {
                            bg = isDark ? const Color(0xFF7F0000) : const Color(0xFFFFEBEE);
                            textColor = isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
                            icon = Icons.arrow_downward;
                          }

                          return Container(
                            width: cellW,
                            height: cellH,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bg,
                              border: Border(
                                top: BorderSide(color: theme.dividerColor, width: 0.5),
                                left: BorderSide(color: theme.dividerColor, width: 0.5),
                              ),
                            ),
                            child: icon != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, size: 12, color: textColor),
                                      const SizedBox(width: 1),
                                      Text(
                                        isUp ? '+10%' : '-10%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
