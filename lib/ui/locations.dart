import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/location.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/detail_location.dart';
import 'package:poke_jerk_api/ui/widgets/encounter_shared.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:provider/provider.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  List<GameLocation> _allLocations = [];
  bool _loading = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _loadAll();
  }

  Future<void> _loadAll() async {
    _loaded = true;
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(getLocationsQuery),
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    ));
    if (result.data != null) {
      final list = result.data!['pokemon_v2_location'] as List? ?? [];
      setState(() {
        _allLocations =
            list.map((l) => GameLocation.fromJson(l as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  List<GameLocation> _filtered(String language, String search, List<int>? versionIds) {
    var result = _allLocations;

    // Filter by version
    if (versionIds != null && versionIds.isNotEmpty) {
      result = result.where((loc) => loc.versionIds.any((v) => versionIds.contains(v))).toList();
    }

    // Filter by search
    if (search.isNotEmpty) {
      final q = normalize(search);
      result = result.where((loc) {
        return normalize(loc.getTranslation(language)).contains(q) ||
            normalize(loc.identifier).contains(q) ||
            normalize(loc.getRegionTranslation(language)).contains(q);
      }).toList();
    }

    // Sort alphabetically by translated name
    result = List.of(result)
      ..sort((a, b) => normalize(a.getTranslation(language))
          .compareTo(normalize(b.getTranslation(language))));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final filter = context.watch<GlobalFilterProvider>();
    final versionIds = filter.selectedVersionGroup?.versionIds;
    final hasVersionFilter = versionIds != null && versionIds.isNotEmpty;
    final locations = _filtered(language, filter.searchQuery, versionIds);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (locations.isEmpty) {
      return Center(
        child: Text(
          language == 'fr' ? 'Aucun lieu trouvé' : 'No locations found',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
      );
    }

    // Group by region
    final grouped = <int?, List<GameLocation>>{};
    for (final loc in locations) {
      grouped.putIfAbsent(loc.regionId, () => []).add(loc);
    }
    final regionIds = grouped.keys.toList()
      ..sort((a, b) => (a ?? 999).compareTo(b ?? 999));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: regionIds.length,
      itemBuilder: (_, i) {
        final regionId = regionIds[i];
        final locs = grouped[regionId]!;
        final regionName = locs.first.getRegionTranslation(language);
        final displayName = regionName.isNotEmpty
            ? regionName
            : (language == 'fr' ? 'Autre' : 'Other');

        return _RegionSection(
          regionName: displayName,
          locations: locs,
          language: language,
          initiallyExpanded: hasVersionFilter,
        );
      },
    );
  }
}

class _RegionSection extends StatefulWidget {
  final String regionName;
  final List<GameLocation> locations;
  final String language;
  final bool initiallyExpanded;

  const _RegionSection({
    required this.regionName,
    required this.locations,
    required this.language,
    required this.initiallyExpanded,
  });

  @override
  State<_RegionSection> createState() => _RegionSectionState();
}

class _RegionSectionState extends State<_RegionSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isAnimating) return;
    _expanded ? _controller.reverse() : _controller.forward();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.public, size: 18, color: Colors.blueGrey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    widget.regionName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.locations.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                    child: Icon(Icons.expand_more, size: 18, color: Colors.blueGrey.shade400),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: widget.locations
                    .map((loc) => _LocationTile(
                          location: loc,
                          language: widget.language,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailLocationPage(location: loc),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final GameLocation location;
  final String language;
  final VoidCallback onTap;

  const _LocationTile({
    required this.location,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = locationIcon(location.identifier);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blueGrey.shade400, size: 18),
        ),
        title: Text(
          location.getTranslation(language),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        onTap: onTap,
      ),
    );
  }
}
