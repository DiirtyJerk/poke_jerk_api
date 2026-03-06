import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/encounter.dart';
import 'package:poke_jerk_api/model/location.dart';
import 'package:poke_jerk_api/model/version_filter.dart';
import 'package:poke_jerk_api/ui/detail_location.dart';
import 'package:poke_jerk_api/ui/widgets/encounter_shared.dart';

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
      padding: const EdgeInsets.all(12),
      children: sortedEntries.map((entry) {
        final byLocation = <int, List<LocationEncounter>>{};
        for (final e in entry.value) {
          byLocation.putIfAbsent(e.locationId, () => []).add(e);
        }

        return VersionHeader(
          versionIdentifier: entry.key,
          versionLabel: entry.value.first.getVersionName(language),
          subtitle: '${byLocation.length} ${language == 'fr' ? 'lieux' : 'locations'}',
          children: byLocation.entries.map((locEntry) {
            final encounters = locEntry.value;
            final first = encounters.first;
            return _LocationCard(
              locationId: first.locationId,
              locationIdentifier: first.locationIdentifier,
              locationName: first.getLocationName(language),
              locationNames: first.locationNames,
              encounters: encounters,
              language: language,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final int locationId;
  final String locationIdentifier;
  final String locationName;
  final Map<int, String> locationNames;
  final List<LocationEncounter> encounters;
  final String language;

  const _LocationCard({
    required this.locationId,
    required this.locationIdentifier,
    required this.locationName,
    required this.locationNames,
    required this.encounters,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final methods = mergeByMethod(
      entries: encounters.map((e) => (
        key: e.getMethodName('en'),
        label: e.getMethodName(language),
        slotId: e.slotId,
        minLevel: e.minLevel,
        maxLevel: e.maxLevel,
        chance: e.chance,
      )),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLocationPage(
              location: GameLocation(
                id: locationId,
                identifier: locationIdentifier,
                names: locationNames,
              ),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(locationIcon(locationName), size: 16, color: Colors.blueGrey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 6),
              ...methods.map((m) => MethodRow(method: m)),
            ],
          ),
        ),
      ),
    );
  }
}
