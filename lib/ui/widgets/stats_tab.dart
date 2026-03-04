import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/type_chart.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/stat_bar.dart';

class StatsTab extends StatelessWidget {
  final Pokemon pokemon;
  final String language;
  final Color accentColor;

  const StatsTab({
    super.key,
    required this.pokemon,
    required this.language,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final species = pokemon.species;
    final total = pokemon.stats.values.fold(0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SectionHeader(
          title: language == 'fr' ? 'Faiblesses de type' : 'Type weaknesses',
          color: accentColor,
        ),
        const SizedBox(height: 10),
        _WeaknessSection(types: pokemon.types.map((t) => t.identifier).toList(), language: language),

        const SizedBox(height: 24),

        _SectionHeader(
          title: language == 'fr' ? 'Stats de base' : 'Base stats',
          color: accentColor,
        ),
        const SizedBox(height: 8),
        ...pokemon.stats.entries.map(
          (e) => StatBar(stat: e.key, value: e.value, language: language),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  language == 'fr' ? 'Total' : 'Total',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$total',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (species != null) ...[
          _SectionHeader(
            title: language == 'fr' ? 'Informations' : 'Information',
            color: accentColor,
          ),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
              _InfoItem(
                icon: Icons.catching_pokemon,
                label: language == 'fr' ? 'Taux de capture' : 'Capture rate',
                value: '${species.captureRate.toString().replaceAll('.', ',')} %',
              ),
              _InfoItem(
                icon: Icons.people_outline,
                label: language == 'fr' ? 'Genre' : 'Gender',
                value: _genderText(species.genderRate, language),
              ),
              if (species.isLegendary)
                _InfoItem(
                  icon: Icons.auto_awesome,
                  label: language == 'fr' ? 'Statut' : 'Status',
                  value: language == 'fr' ? 'Légendaire' : 'Legendary',
                ),
              if (species.isMythical)
                _InfoItem(
                  icon: Icons.auto_awesome,
                  label: language == 'fr' ? 'Statut' : 'Status',
                  value: language == 'fr' ? 'Fabuleux' : 'Mythical',
                ),
              if (species.isBaby)
                _InfoItem(
                  icon: Icons.child_friendly,
                  label: language == 'fr' ? 'Statut' : 'Status',
                  value: language == 'fr' ? 'Bébé' : 'Baby',
                ),
            ],
          ),
        ],

        if (pokemon.forms.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            title: language == 'fr' ? 'Formes alternatives' : 'Alternate forms',
            color: accentColor,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: pokemon.forms.map((f) {
              return Chip(
                label: Text(f.getTranslation(language),
                    style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _genderText(int genderRate, String language) {
    if (genderRate == -1) return language == 'fr' ? 'Asexué' : 'Genderless';
    if (genderRate == 0) return language == 'fr' ? '100% Mâle' : '100% Male';
    if (genderRate == 8) return language == 'fr' ? '100% Femelle' : '100% Female';
    final female = (genderRate / 8 * 100).round();
    return '$female% ♀  ${100 - female}% ♂';
  }
}

// ── Section titre ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

// ── Faiblesses ─────────────────────────────────────────────────────────────────

class _WeaknessSection extends StatelessWidget {
  final List<String> types;
  final String language;

  const _WeaknessSection({required this.types, required this.language});

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();

    final chart = TypeChart.computeDefenseChart(types);

    final groups = <double, List<String>>{};
    chart.forEach((type, mult) =>
        groups.putIfAbsent(mult, () => []).add(type));

    const displayOrder = [4.0, 2.0, 0.0, 0.25, 0.5];
    final rows = displayOrder
        .where((m) => groups.containsKey(m))
        .map((m) => MapEntry(m, groups[m]!))
        .toList();

    if (rows.isEmpty) {
      return Text(
        language == 'fr' ? 'Aucune faiblesse notable' : 'No notable weakness',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      );
    }

    return Column(
      children: rows.map((entry) {
        final mult = entry.key;
        final typeIds = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MultiplierBadge(multiplier: mult),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: typeIds.map((id) => _TypeLabel(
                    identifier: id,
                    language: language,
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MultiplierBadge extends StatelessWidget {
  final double multiplier;

  const _MultiplierBadge({required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    if (multiplier == 0.0) {
      label = '×0';
      color = Colors.grey.shade600;
    } else if (multiplier == 0.25) {
      label = '¼';
      color = Colors.teal.shade300;
    } else if (multiplier == 0.5) {
      label = '½';
      color = Colors.teal.shade400;
    } else if (multiplier == 2.0) {
      label = '×2';
      color = Colors.orange.shade600;
    } else {
      label = '×4';
      color = Colors.red.shade600;
    }

    return Container(
      width: 34,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  final String identifier;
  final String language;

  const _TypeLabel({required this.identifier, required this.language});

  @override
  Widget build(BuildContext context) {
    final color = ColorBuilder.getTypeColorByIdentifier(identifier);
    final name = TypeChart.getTypeName(identifier, language);
    final lum = color.computeLuminance();
    final textColor = lum > 0.4 ? Colors.black87 : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Grille d'informations ──────────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.label,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    Text(item.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }),
      ),
    );
  }
}
