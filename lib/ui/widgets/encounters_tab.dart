import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/encounter.dart';
import 'package:poke_jerk_api/model/version_filter.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';

class EncountersTab extends StatelessWidget {
  final List<LocationEncounter> encounters;
  final String language;
  final VersionFilter? versionFilter;

  const EncountersTab({
    super.key,
    required this.encounters,
    required this.language,
    this.versionFilter,
  });

  @override
  Widget build(BuildContext context) {
    final ids = versionFilter?.versionIdentifiers;
    final filtered = (ids == null || ids.isEmpty)
        ? encounters
        : encounters.where((e) => ids.contains(e.versionIdentifier)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          language == 'fr'
              ? 'Non trouvable dans la nature'
              : 'Not found in the wild',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group by version, sorted chronologically
    final grouped = <String, List<LocationEncounter>>{};
    for (final e in filtered) {
      grouped.putIfAbsent(e.versionIdentifier, () => []).add(e);
    }
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.value.first.versionId.compareTo(b.value.first.versionId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sortedEntries.map((entry) {
        final label = entry.value.first.getVersionName(language);
        return _VersionGroup(
          versionIdentifier: entry.key,
          versionLabel: label,
          encounters: entry.value,
          language: language,
        );
      }).toList(),
    );
  }
}

class _VersionGroup extends StatelessWidget {
  final String versionIdentifier;
  final String versionLabel;
  final List<LocationEncounter> encounters;
  final String language;

  const _VersionGroup({
    required this.versionIdentifier,
    required this.versionLabel,
    required this.encounters,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = ColorBuilder.getVersionColor(versionIdentifier);
    final textColor = ColorBuilder.getVersionTextColor(versionIdentifier);

    // Group by location name, preserving encounter order
    final byLocation = <String, List<LocationEncounter>>{};
    for (final e in encounters) {
      byLocation.putIfAbsent(e.getLocationName(language), () => []).add(e);
    }

    // Deduplicate within each location (same method + same levels + same chance)
    final deduped = byLocation.map((loc, list) {
      final seen = <String>{};
      final unique = list.where((e) {
        final key = '${e.getMethodName(language)}_${e.minLevel}_${e.maxLevel}_${e.chance}';
        return seen.add(key);
      }).toList();
      return MapEntry(loc, unique);
    });

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.only(left: 0, right: 8, top: 6),
        childrenPadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$versionLabel (${deduped.length})',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        children: deduped.entries
            .map((entry) => _LocationCard(
                  locationName: entry.key,
                  encounters: entry.value,
                  language: language,
                ))
            .toList(),
      ),
    );
  }
}

class _MergedSlot {
  final String method;
  final int minLevel;
  final int maxLevel;
  final int chance;
  const _MergedSlot({required this.method, required this.minLevel, required this.maxLevel, required this.chance});
}

class _LocationCard extends StatelessWidget {
  final String locationName;
  final List<LocationEncounter> encounters;
  final String language;

  const _LocationCard({
    required this.locationName,
    required this.encounters,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    // Fusionner les slots de même méthode + même plage de niveaux (additionner les chances)
    final merged = <String, _MergedSlot>{};
    for (final e in encounters) {
      final method = e.getMethodName(language);
      final key = '${method}_${e.minLevel}_${e.maxLevel}';
      if (merged.containsKey(key)) {
        final existing = merged[key]!;
        merged[key] = _MergedSlot(method: method, minLevel: existing.minLevel, maxLevel: existing.maxLevel, chance: existing.chance + e.chance);
      } else {
        merged[key] = _MergedSlot(method: method, minLevel: e.minLevel, maxLevel: e.maxLevel, chance: e.chance);
      }
    }
    final slots = merged.values.toList()..sort((a, b) => a.minLevel.compareTo(b.minLevel));

    // Statistiques globales
    var minLvl = slots.first.minLevel;
    var maxLvl = slots.first.maxLevel;
    var totalChance = 0;
    for (final s in slots) {
      if (s.minLevel < minLvl) minLvl = s.minLevel;
      if (s.maxLevel > maxLvl) maxLvl = s.maxLevel;
      totalChance += s.chance;
    }

    final hasDetail = slots.length > 1;

    Widget summary = Row(
      children: [
        Expanded(
          child: Text(locationName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Text('Niv. $minLvl–$maxLvl', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('$totalChance%', textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
      ],
    );

    Widget summaryWithMethod = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary,
        const SizedBox(height: 2),
        Text(
          slots.first.method,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );

    if (!hasDetail) {
      return Card(
        margin: const EdgeInsets.only(bottom: 6),
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: summaryWithMethod,
        ),
      );
    }

    String? lastMethod;
    final detailRows = <Widget>[];
    for (final slot in slots) {
      final showMethod = slot.method != lastMethod;
      lastMethod = slot.method;
      detailRows.add(_EncounterSlotRow(slot: slot, showMethod: showMethod));
    }

    return _ExpandableLocationCard(
      locationName: locationName,
      minLvl: minLvl,
      maxLvl: maxLvl,
      totalChance: totalChance,
      detailRows: detailRows,
    );
  }
}

class _ExpandableLocationCard extends StatefulWidget {
  final String locationName;
  final int minLvl;
  final int maxLvl;
  final int totalChance;
  final List<Widget> detailRows;

  const _ExpandableLocationCard({
    required this.locationName,
    required this.minLvl,
    required this.maxLvl,
    required this.totalChance,
    required this.detailRows,
  });

  @override
  State<_ExpandableLocationCard> createState() =>
      _ExpandableLocationCardState();
}

class _ExpandableLocationCardState extends State<_ExpandableLocationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(widget.locationName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  Text('Niv. ${widget.minLvl}–${widget.maxLvl}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text('${widget.totalChance}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(children: widget.detailRows),
              ),
          ],
        ),
      ),
    );
  }
}

class _EncounterSlotRow extends StatelessWidget {
  final _MergedSlot slot;
  final bool showMethod;

  const _EncounterSlotRow({required this.slot, required this.showMethod});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: showMethod
                ? Text(
                    slot.method,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  )
                : const SizedBox.shrink(),
          ),
          Text(
            'Niv. ${slot.minLevel}–${slot.maxLevel}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${slot.chance}%',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
