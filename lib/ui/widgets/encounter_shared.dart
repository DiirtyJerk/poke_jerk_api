import 'package:flutter/material.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class EncounterSlot {
  final int minLevel;
  final int maxLevel;
  final int chance;
  final String area;

  EncounterSlot({required this.minLevel, required this.maxLevel, required this.chance, this.area = ''});
}

class MergedMethod {
  final String methodName;
  final String methodKey;
  int minLevel;
  int maxLevel;
  int totalChance;
  final List<EncounterSlot> slots;

  MergedMethod({
    required this.methodName,
    required this.methodKey,
    required this.minLevel,
    required this.maxLevel,
    required this.totalChance,
    required this.slots,
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Color chanceColor(int chance) {
  if (chance >= 30) return Colors.green;
  if (chance >= 10) return Colors.orange;
  return Colors.red.shade400;
}

IconData methodIcon(String identifier) {
  final lower = identifier.toLowerCase();
  if (lower.contains('surf') || lower.contains('eau')) return Icons.water;
  if (lower.contains('canne') || lower.contains('rod') || lower.contains('fish')) return Icons.phishing;
  if (lower.contains('rock') || lower.contains('roc') || lower.contains('éclat')) return Icons.landscape;
  if (lower.contains('headbutt') || lower.contains('tête')) return Icons.park;
  return Icons.directions_walk;
}

IconData locationIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('route')) return Icons.route;
  if (lower.contains('grotte') || lower.contains('cave') || lower.contains('tunnel') || lower.contains('mont') || lower.contains('mt-')) return Icons.landscape;
  if (lower.contains('mer') || lower.contains('lac') || lower.contains('sea') || lower.contains('lake') || lower.contains('étang') || lower.contains('pond') || lower.contains('river')) return Icons.water;
  if (lower.contains('forêt') || lower.contains('forest') || lower.contains('bois') || lower.contains('woods')) return Icons.forest;
  if (lower.contains('ville') || lower.contains('city') || lower.contains('town')) return Icons.location_city;
  if (lower.contains('tour') || lower.contains('tower') || lower.contains('château') || lower.contains('castle')) return Icons.castle;
  if (lower.contains('île') || lower.contains('island')) return Icons.sailing;
  return Icons.place;
}

/// Merges encounters by method key, summing chances and widening level ranges.
/// [getKey] extracts the stable grouping key (e.g. English method name or identifier).
/// [getLabel] extracts the display label (localized method name).
List<MergedMethod> mergeByMethod({
  required Iterable<({String key, String label, int slotId, int minLevel, int maxLevel, int chance, String area})> entries,
  bool sort = true,
}) {
  final byMethod = <String, MergedMethod>{};
  for (final e in entries) {
    if (byMethod.containsKey(e.key)) {
      final m = byMethod[e.key]!;
      m.totalChance += e.chance;
      if (e.minLevel < m.minLevel) m.minLevel = e.minLevel;
      if (e.maxLevel > m.maxLevel) m.maxLevel = e.maxLevel;
      m.slots.add(EncounterSlot(minLevel: e.minLevel, maxLevel: e.maxLevel, chance: e.chance, area: e.area));
    } else {
      byMethod[e.key] = MergedMethod(
        methodName: e.label,
        methodKey: e.key,
        minLevel: e.minLevel,
        maxLevel: e.maxLevel,
        totalChance: e.chance,
        slots: [EncounterSlot(minLevel: e.minLevel, maxLevel: e.maxLevel, chance: e.chance, area: e.area)],
      );
    }
  }
  final methods = byMethod.values.toList();
  for (final m in methods) {
    // Average across areas if multiple
    final areas = m.slots.map((s) => s.area).toSet();
    if (areas.length > 1 && areas.any((a) => a.isNotEmpty)) {
      final perArea = <String, int>{};
      for (final area in areas) {
        final areaSlots = m.slots.where((s) => s.area == area);
        // Merge same level range within area
        final merged = <String, int>{};
        for (final s in areaSlots) {
          final key = '${s.minLevel}-${s.maxLevel}';
          merged[key] = (merged[key] ?? 0) + s.chance;
        }
        var t = merged.values.fold(0, (sum, c) => sum + c);
        if (t > 100) t = 100;
        perArea[area] = t;
      }
      m.totalChance = perArea.values.fold(0, (sum, c) => sum + c) ~/ perArea.length;
    }
    if (m.totalChance > 100) m.totalChance = 100;
  }
  if (sort) methods.sort((a, b) => b.totalChance.compareTo(a.totalChance));
  return methods;
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

/// Expandable version header bar with colored background and chevron animation.
class VersionHeader extends StatefulWidget {
  final String versionIdentifier;
  final String versionLabel;
  final String subtitle;
  final List<Widget> children;

  const VersionHeader({
    super.key,
    required this.versionIdentifier,
    required this.versionLabel,
    required this.subtitle,
    required this.children,
  });

  @override
  State<VersionHeader> createState() => _VersionHeaderState();
}

class _VersionHeaderState extends State<VersionHeader>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ColorBuilder.getVersionColor(widget.versionIdentifier);
    final textColor = ColorBuilder.getVersionTextColor(widget.versionIdentifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (_iconController.isAnimating) return;
              _expanded ? _iconController.reverse() : _iconController.forward();
              setState(() => _expanded = !_expanded);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    widget.versionLabel,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.subtitle,
                    style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_iconController),
                    child: Icon(Icons.expand_more, color: textColor.withValues(alpha: 0.7), size: 18),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: _iconController,
              curve: Curves.easeInOut,
            ),
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(children: widget.children),
            ),
          ),
        ],
      ),
    );
  }
}

/// Method row with long-press expandable slot detail.
class MethodRow extends StatefulWidget {
  final MergedMethod method;
  const MethodRow({super.key, required this.method});

  @override
  State<MethodRow> createState() => _MethodRowState();
}

class _MethodRowState extends State<MethodRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    final levelText = method.minLevel == method.maxLevel
        ? 'Niv. ${method.minLevel}'
        : 'Niv. ${method.minLevel}–${method.maxLevel}';
    // Count unique level+area combinations after merge
    final uniqueEntries = method.slots.map((s) {
      final lvl = s.minLevel == s.maxLevel ? '${s.minLevel}' : '${s.minLevel}-${s.maxLevel}';
      return '${s.area}|$lvl';
    }).toSet();
    final hasDetail = uniqueEntries.length > 1;

    return GestureDetector(
      onTap: hasDetail ? () => setState(() => _expanded = !_expanded) : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(methodIcon(method.methodKey), size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          method.methodName,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                      if (hasDetail)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  levelText,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: chanceColor(method.totalChance),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${method.totalChance}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _expanded ? _buildSlotDetail(method) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotDetail(MergedMethod method) {
    final areasWithNames = method.slots.map((s) => s.area).where((a) => a.isNotEmpty).toSet();
    final showArea = areasWithNames.isNotEmpty;

    // Merge slots with same level range + area
    final merged = <String, ({int chance, String area})>{};
    final sorted = List<EncounterSlot>.from(method.slots)
      ..sort((a, b) {
        final cmp = a.area.compareTo(b.area);
        if (cmp != 0) return cmp;
        return a.minLevel.compareTo(b.minLevel);
      });
    for (final slot in sorted) {
      final levelPart = slot.minLevel == slot.maxLevel
          ? 'Niv. ${slot.minLevel}'
          : 'Niv. ${slot.minLevel}–${slot.maxLevel}';
      final key = showArea && slot.area.isNotEmpty ? '$levelPart|${slot.area}' : levelPart;
      final existing = merged[key];
      merged[key] = (chance: (existing?.chance ?? 0) + slot.chance, area: slot.area);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 2, bottom: 4),
      child: Column(
        children: merged.entries.map((e) {
          final chance = e.value.chance > 100 ? 100 : e.value.chance;
          final levelText = e.key.split('|').first;
          final area = e.value.area;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                if (area.isNotEmpty) ...[
                  Text(area, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
                  const SizedBox(width: 6),
                ],
                Text(levelText, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const Spacer(),
                Container(
                  width: 38,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: chanceColor(chance).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$chance%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
