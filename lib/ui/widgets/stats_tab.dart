import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/stat.dart';
import 'package:poke_jerk_api/model/type_chart.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';


enum _RadarMode { base, lv50, lv100 }

class StatsTab extends StatefulWidget {
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
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  _RadarMode _mode = _RadarMode.base;

  /// Returns (minStats, maxStats) for a given level. For base mode both are identical.
  (Map<Stat, int>, Map<Stat, int>) _computeRange(_RadarMode mode) {
    final pokemon = widget.pokemon;
    final isShedinja = pokemon.identifier == 'shedinja';
    final mins = <Stat, int>{};
    final maxs = <Stat, int>{};
    for (final entry in pokemon.stats.entries) {
      final base = entry.value;
      final isHp = entry.key.identifier == 'hp';
      if (mode == _RadarMode.base) {
        mins[entry.key] = base;
        maxs[entry.key] = base;
      } else {
        final level = mode == _RadarMode.lv50 ? 50 : 100;
        if (isShedinja && isHp) {
          mins[entry.key] = 1;
          maxs[entry.key] = 1;
        } else if (isHp) {
          mins[entry.key] = _calcHp(base, level, iv: 0, ev: 0);
          maxs[entry.key] = _calcHp(base, level, iv: 31, ev: 252);
        } else {
          mins[entry.key] = _calcStat(base, level, iv: 0, ev: 0, nature: 0.9);
          maxs[entry.key] = _calcStat(base, level, iv: 31, ev: 252, nature: 1.1);
        }
      }
    }
    return (mins, maxs);
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    final language = widget.language;
    final accentColor = widget.accentColor;
    final species = pokemon.species;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        _SectionHeader(
          title: language == 'fr' ? 'Faiblesses de type' : 'Type weaknesses',
          color: accentColor,
        ),
        const SizedBox(height: 10),
        _WeaknessSection(types: pokemon.types.map((t) => t.identifier).toList(), language: language),

        const SizedBox(height: 24),

        _SectionHeader(
          title: language == 'fr' ? 'Statistiques' : 'Stats',
          color: accentColor,
        ),
        const SizedBox(height: 8),
        // Mode selector
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_RadarMode>(
            segments: [
              ButtonSegment(value: _RadarMode.base, label: Text('Base', style: const TextStyle(fontSize: 12))),
              ButtonSegment(value: _RadarMode.lv50, label: Text('Niv. 50', style: const TextStyle(fontSize: 12))),
              ButtonSegment(value: _RadarMode.lv100, label: Text('Niv. 100', style: const TextStyle(fontSize: 12))),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Radar chart
        Builder(builder: (_) {
          final (minStats, maxStats) = _computeRange(_mode);
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(8),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: CustomPaint(
                painter: _StatRadarPainter(
                  stats: maxStats,
                  minStats: _mode != _RadarMode.base ? minStats : null,
                  accentColor: accentColor,
                  language: language,
                ),
              ),
            ),
          );
        }),

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
            ),
          ),
        );
      },
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

    // Separate weaknesses (>1) from resistances/immunities (<=1)
    const weakOrder = [4.0, 2.0];
    const resistOrder = [0.5, 0.25, 0.0];

    final weakRows = weakOrder
        .where((m) => groups.containsKey(m))
        .map((m) => MapEntry(m, groups[m]!))
        .toList();
    final resistRows = resistOrder
        .where((m) => groups.containsKey(m))
        .map((m) => MapEntry(m, groups[m]!))
        .toList();

    if (weakRows.isEmpty && resistRows.isEmpty) {
      return Text(
        language == 'fr' ? 'Aucune faiblesse notable' : 'No notable weakness',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (weakRows.isNotEmpty) ...[
            _GroupHeader(
              label: language == 'fr' ? 'Faiblesses' : 'Weaknesses',
              icon: Icons.arrow_downward_rounded,
              color: Colors.red.shade400,
            ),
            for (final entry in weakRows)
              _WeaknessRow(mult: entry.key, typeIds: entry.value, language: language),
          ],
          if (weakRows.isNotEmpty && resistRows.isNotEmpty)
            Divider(height: 1, color: Colors.grey.shade200),
          if (resistRows.isNotEmpty) ...[
            _GroupHeader(
              label: language == 'fr' ? 'Résistances' : 'Resistances',
              icon: Icons.shield_outlined,
              color: Colors.teal.shade400,
            ),
            for (final entry in resistRows)
              _WeaknessRow(mult: entry.key, typeIds: entry.value, language: language),
          ],
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _GroupHeader({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeaknessRow extends StatelessWidget {
  final double mult;
  final List<String> typeIds;
  final String language;

  const _WeaknessRow({required this.mult, required this.typeIds, required this.language});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MultiplierBadge(multiplier: mult),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: typeIds.map((id) => _TypeLabel(
                identifier: id,
                language: language,
              )).toList(),
            ),
          ),
        ],
      ),
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
    final textColor = ColorBuilder.textColorOn(color);

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

// ── Stat Range Table (min/max at Lv.50 & Lv.100) ────────────────────────────

int _calcHp(int base, int level, {required int iv, required int ev}) {
  return ((2 * base + iv + ev ~/ 4) * level ~/ 100) + level + 10;
}

int _calcStat(int base, int level, {required int iv, required int ev, required double nature}) {
  return (((2 * base + iv + ev ~/ 4) * level ~/ 100 + 5) * nature).floor();
}

// ─── Radar Chart Painter ──────────────────────────────────────────────────────

class _StatRadarPainter extends CustomPainter {
  final Map<Stat, int> stats;
  final Map<Stat, int>? minStats;
  final Color accentColor;
  final String language;

  _StatRadarPainter({
    required this.stats,
    this.minStats,
    required this.accentColor,
    required this.language,
  });

  double get _visualMax {
    final maxStat = stats.values.reduce(math.max).toDouble();
    // Round up to next 25 for clean rings, min 100
    return ((maxStat / 25).ceil() * 25).toDouble().clamp(100.0, 255.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 32;
    final statEntries = stats.entries.toList();
    final n = statEntries.length;
    final angleStep = 2 * math.pi / n;
    const startAngle = -math.pi / 2;

    // Grid rings
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final angle = startAngle + angleStep * (i % n);
        final pt = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
      // Scale label
      final scaleVal = (_visualMax * ring / 4).round();
      final scaleTp = TextPainter(
        text: TextSpan(
          text: '$scaleVal',
          style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scaleTp.paint(canvas, Offset(center.dx + 2, center.dy - r - scaleTp.height));
    }

    // Axes
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final pt = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, pt, gridPaint);
    }

    // Min polygon (drawn first, behind max)
    if (minStats != null) {
      final minEntries = minStats!.entries.toList();
      final minPath = Path();
      for (int i = 0; i <= n; i++) {
        final idx = i % n;
        final val = (minEntries[idx].value / _visualMax).clamp(0.0, 1.0);
        final angle = startAngle + angleStep * idx;
        final pt = Offset(
          center.dx + radius * val * math.cos(angle),
          center.dy + radius * val * math.sin(angle),
        );
        if (i == 0) { minPath.moveTo(pt.dx, pt.dy); } else { minPath.lineTo(pt.dx, pt.dy); }
      }
      canvas.drawPath(minPath, Paint()
        ..color = Colors.orange.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill);
      canvas.drawPath(minPath, Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }

    // Max / base polygon
    final dataPath = Path();
    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i <= n; i++) {
      final idx = i % n;
      final val = (statEntries[idx].value / _visualMax).clamp(0.0, 1.0);
      final angle = startAngle + angleStep * idx;
      final pt = Offset(
        center.dx + radius * val * math.cos(angle),
        center.dy + radius * val * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(pt.dx, pt.dy);
      } else {
        dataPath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Data points + labels
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final entry = statEntries[i];
      final val = (entry.value / _visualMax).clamp(0.0, 1.0);
      final angle = startAngle + angleStep * i;

      // Dot
      final pt = Offset(
        center.dx + radius * val * math.cos(angle),
        center.dy + radius * val * math.sin(angle),
      );
      canvas.drawCircle(pt, 3.5, dotPaint);

      // Label: stat name + value
      final labelRadius = radius + 20;
      final labelPt = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final name = _shortStatName(entry.key.identifier);
      final minVal = minStats?.entries.toList()[i].value;
      final valueText = minVal != null ? '$minVal - ${entry.value}' : '${entry.value}';
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            TextSpan(
              text: '\n$valueText',
              style: TextStyle(
                fontSize: minVal != null ? 9 : 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(labelPt.dx - tp.width / 2, labelPt.dy - tp.height / 2));
    }
  }

  String _shortStatName(String identifier) {
    final fr = language == 'fr';
    switch (identifier) {
      case 'hp': return 'PV';
      case 'attack': return fr ? 'ATQ' : 'ATK';
      case 'defense': return fr ? 'DÉF' : 'DEF';
      case 'special-attack': return fr ? 'A.Spé' : 'SpA';
      case 'special-defense': return fr ? 'D.Spé' : 'SpD';
      case 'speed': return fr ? 'VIT' : 'SPE';
      default: return identifier;
    }
  }

  @override
  bool shouldRepaint(covariant _StatRadarPainter oldDelegate) =>
      stats != oldDelegate.stats || minStats != oldDelegate.minStats || accentColor != oldDelegate.accentColor;
}
