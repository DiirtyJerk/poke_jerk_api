import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/location.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/users_datas.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/widgets/encounter_shared.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:provider/provider.dart';

class DetailLocationPage extends StatefulWidget {
  final GameLocation location;
  const DetailLocationPage({super.key, required this.location});

  @override
  State<DetailLocationPage> createState() => _DetailLocationPageState();
}

class _DetailLocationPageState extends State<DetailLocationPage> {
  List<LocationPokemonEncounter> _encounters = [];
  bool _loading = true;
  bool _pokemonFirst = true;
  late bool _uncapturedOnly;

  @override
  void initState() {
    super.initState();
    _uncapturedOnly = false; // will be set in didChangeDependencies
  }

  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _uncapturedOnly = context.read<UserSettings>().capturedFeature;
      _loadEncounters();
    }
  }

  Future<void> _loadEncounters() async {
    try {
      final client = GraphQLProvider.of(context).value;
      debugPrint('[DetailLocation] fetching encounters for location ${widget.location.id}...');
      final result = await client.query(QueryOptions(
        document: gql(getLocationDetailQuery),
        variables: {'locationId': widget.location.id},
        fetchPolicy: FetchPolicy.noCache,
      )).timeout(const Duration(seconds: 30));
      debugPrint('[DetailLocation] encounters query OK');
      if (!mounted) return;
      if (result.data != null) {
        final list = result.data!['pokemon_v2_encounter'] as List? ?? [];
        setState(() {
          _encounters = list
              .map((e) => LocationPokemonEncounter.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('[DetailLocation] _loadEncounters timeout/error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettings>();
    final language = settings.language;
    final showCapture = settings.capturedFeature;
    final filter = context.watch<GlobalFilterProvider>();
    final userDatas = context.watch<UserDatas>();
    final versionIds = filter.selectedVersionGroup?.versionIdentifiers;

    final filtered = (versionIds == null || versionIds.isEmpty)
        ? _encounters
        : _encounters.where((e) => versionIds.contains(e.versionIdentifier)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(locationIcon(widget.location.identifier), size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(widget.location.getTranslation(language))),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Text(
                    language == 'fr' ? 'Aucune rencontre' : 'No encounters',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                  value: true,
                                  icon: const Icon(Icons.catching_pokemon, size: 16),
                                  label: const Text('Pokémon'),
                                ),
                                ButtonSegment(
                                  value: false,
                                  icon: const Icon(Icons.directions_walk, size: 16),
                                  label: Text(language == 'fr' ? 'Méthode' : 'Method'),
                                ),
                              ],
                              selected: {_pokemonFirst},
                              onSelectionChanged: (v) => setState(() => _pokemonFirst = v.first),
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                textStyle: WidgetStatePropertyAll(
                                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          if (showCapture) ...[
                            const SizedBox(width: 8),
                            FilterChip(
                              avatar: Icon(
                                _uncapturedOnly
                                    ? Icons.catching_pokemon
                                    : Icons.catching_pokemon_outlined,
                                size: 16,
                                color: _uncapturedOnly ? const Color(0xFFE53935) : Colors.black54,
                              ),
                              label: Text(
                                language == 'fr' ? 'Manquants' : 'Missing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _uncapturedOnly ? const Color(0xFFE53935) : Colors.black87,
                                  fontWeight: _uncapturedOnly ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              selected: _uncapturedOnly,
                              onSelected: (v) => setState(() => _uncapturedOnly = v),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: _pokemonFirst
                          ? _buildPokemonFirstContent(filtered, language, userDatas: showCapture && _uncapturedOnly ? userDatas : null)
                          : _buildContent(filtered, language, userDatas: showCapture && _uncapturedOnly ? userDatas : null),
                    ),
                  ],
                ),
    );
  }

  int _totalChance(List<LocationPokemonEncounter> encs) {
    final areas = encs.map((e) => e.areaIdentifier).toSet();
    if (areas.length <= 1) {
      // Single area: sum chances by level
      final map = <String, int>{};
      for (final e in encs) {
        final key = '${e.minLevel}-${e.maxLevel}';
        map[key] = (map[key] ?? 0) + e.chance;
      }
      final total = map.values.fold(0, (sum, c) => sum + c);
      return total > 100 ? 100 : total;
    }
    // Multiple areas: average per area
    final perArea = <String, int>{};
    for (final area in areas) {
      final areaEncs = encs.where((e) => e.areaIdentifier == area);
      final map = <String, int>{};
      for (final e in areaEncs) {
        final key = '${e.minLevel}-${e.maxLevel}';
        map[key] = (map[key] ?? 0) + e.chance;
      }
      var total = map.values.fold(0, (sum, c) => sum + c);
      if (total > 100) total = 100;
      perArea[area] = total;
    }
    final avg = perArea.values.fold(0, (sum, c) => sum + c) ~/ perArea.length;
    return avg > 100 ? 100 : avg;
  }

  List<Widget> _buildPokemonTiles(List<LocationPokemonEncounter> encs, String language) {
    final byPokemon = <int, List<LocationPokemonEncounter>>{};
    for (final e in encs) {
      byPokemon.putIfAbsent(e.pokemonId, () => []).add(e);
    }
    final sortedIds = byPokemon.keys.toList()
      ..sort((a, b) {
        final chanceA = _totalChance(byPokemon[a]!);
        final chanceB = _totalChance(byPokemon[b]!);
        return chanceB.compareTo(chanceA);
      });
    return sortedIds
        .map((id) => _PokemonEncounterTile(encounters: byPokemon[id]!, language: language))
        .toList();
  }

  Widget _buildPokemonFirstContent(List<LocationPokemonEncounter> encounters, String language, {UserDatas? userDatas}) {
    final byVersion = <String, List<LocationPokemonEncounter>>{};
    for (final e in encounters) {
      byVersion.putIfAbsent(e.versionIdentifier, () => []).add(e);
    }
    final sortedVersions = byVersion.entries.toList()
      ..sort((a, b) => a.value.first.versionId.compareTo(b.value.first.versionId));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: sortedVersions.map((entry) {
        final byPokemon = <int, List<LocationPokemonEncounter>>{};
        for (final e in entry.value) {
          byPokemon.putIfAbsent(e.pokemonId, () => []).add(e);
        }

        // Filter uncaptured only
        var sortedIds = byPokemon.keys.toList();
        if (userDatas != null) {
          sortedIds = sortedIds.where((id) {
            final identifier = byPokemon[id]!.first.pokemonIdentifier;
            return !(userDatas.getUserPokemon(identifier)?.captured ?? false);
          }).toList();
        }

        // Sort alphabetically by pokemon name
        sortedIds.sort((a, b) {
          final nameA = byPokemon[a]!.first.getPokemonName(language);
          final nameB = byPokemon[b]!.first.getPokemonName(language);
          return nameA.compareTo(nameB);
        });

        final totalPokemon = sortedIds.length;

        return VersionHeader(
          versionIdentifier: entry.key,
          versionLabel: entry.value.first.getVersionName(language),
          subtitle: '$totalPokemon Pokémon',
          children: sortedIds
              .map((id) => _PokemonFirstTile(encounters: byPokemon[id]!, language: language))
              .toList(),
        );
      }).toList(),
    );
  }

  Widget _buildContent(List<LocationPokemonEncounter> encounters, String language, {UserDatas? userDatas}) {
    final byVersion = <String, List<LocationPokemonEncounter>>{};
    for (final e in encounters) {
      byVersion.putIfAbsent(e.versionIdentifier, () => []).add(e);
    }
    final sortedVersions = byVersion.entries.toList()
      ..sort((a, b) => a.value.first.versionId.compareTo(b.value.first.versionId));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: sortedVersions.map((entry) {
        // Group by method, then by pokemon within each method
        final byMethod = <String, List<LocationPokemonEncounter>>{};
        for (final e in entry.value) {
          byMethod.putIfAbsent(e.methodIdentifier, () => []).add(e);
        }

        // Count unique pokemon across all methods (after filter)
        final allUniquePokemonIds = <int>{};

        // Build pokemon tiles grouped by method, sorted alphabetically
        final sortedMethods = byMethod.entries.toList()
          ..sort((a, b) => a.value.first.getMethodName(language)
              .compareTo(b.value.first.getMethodName(language)));
        final children = <Widget>[];
        for (final methodEntry in sortedMethods) {
          var methodEncs = methodEntry.value;

          // Filter uncaptured
          if (userDatas != null) {
            final uncapturedIds = methodEncs.map((e) => e.pokemonId).toSet()
                .where((id) {
              final identifier = methodEncs.firstWhere((e) => e.pokemonId == id).pokemonIdentifier;
              return !(userDatas.getUserPokemon(identifier)?.captured ?? false);
            }).toSet();
            methodEncs = methodEncs.where((e) => uncapturedIds.contains(e.pokemonId)).toList();
          }

          if (methodEncs.isEmpty) continue;
          final pokemonTiles = _buildPokemonTiles(methodEncs, language);
          final methodPokemonCount = methodEncs.map((e) => e.pokemonId).toSet().length;
          allUniquePokemonIds.addAll(methodEncs.map((e) => e.pokemonId));

          final methodName = methodEncs.first.getMethodName(language);
          children.add(_MethodSection(
            methodName: methodName,
            icon: methodIcon(methodEntry.key),
            pokemonCount: methodPokemonCount,
            children: pokemonTiles,
          ));
        }

        if (children.isEmpty) return const SizedBox.shrink();

        return VersionHeader(
          versionIdentifier: entry.key,
          versionLabel: entry.value.first.getVersionName(language),
          subtitle: '${allUniquePokemonIds.length} Pokémon',
          children: children,
        );
      }).toList(),
    );
  }
}

class _MethodSection extends StatelessWidget {
  final String methodName;
  final IconData icon;
  final int pokemonCount;
  final List<Widget> children;

  const _MethodSection({
    required this.methodName,
    required this.icon,
    required this.pokemonCount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Colors.blueGrey.shade200, width: 1),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: border,
          collapsedShape: border,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
          leading: Icon(icon, size: 18, color: Colors.blueGrey.shade400),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  methodName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pokemonCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ),
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}

class _PokemonFirstTile extends StatefulWidget {
  final List<LocationPokemonEncounter> encounters;
  final String language;

  const _PokemonFirstTile({required this.encounters, required this.language});

  @override
  State<_PokemonFirstTile> createState() => _PokemonFirstTileState();
}

class _PokemonFirstTileState extends State<_PokemonFirstTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final first = widget.encounters.first;
    final language = widget.language;
    final settings = context.watch<UserSettings>();
    final showCapture = settings.capturedFeature;
    final userDatas = context.watch<UserDatas>();
    final isCaptured = userDatas.getUserPokemon(first.pokemonIdentifier)?.isCapturedIn(first.versionGroupId) ?? false;

    var globalMin = widget.encounters.first.minLevel;
    var globalMax = widget.encounters.first.maxLevel;
    for (final e in widget.encounters) {
      if (e.minLevel < globalMin) globalMin = e.minLevel;
      if (e.maxLevel > globalMax) globalMax = e.maxLevel;
    }
    final globalLevelText = globalMin == globalMax
        ? 'Niv. $globalMin'
        : 'Niv. $globalMin–$globalMax';

    final methods = mergeByMethod(
      entries: widget.encounters.map((e) => (
        key: e.methodIdentifier,
        label: e.getMethodName(language),
        slotId: e.slotId,
        minLevel: e.minLevel,
        maxLevel: e.maxLevel,
        chance: e.chance,
        area: e.getAreaName(language),
      )),
    );

    final pokemonAreaNames = _sortedAreaNames(widget.encounters, language);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showCapture)
                    GestureDetector(
                      onTap: () {
                        userDatas.capturedPokemon(first.pokemonIdentifier, !isCaptured, versionGroupId: first.versionGroupId);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          isCaptured ? Icons.catching_pokemon : Icons.catching_pokemon_outlined,
                          size: 22,
                          color: isCaptured ? const Color(0xFFE53935) : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  CachedNetworkImage(
                    imageUrl: first.spriteUrl,
                    width: 48,
                    height: 48,
                    placeholder: (_, _) => const SizedBox(
                      width: 48, height: 48,
                      child: Center(
                        child: Icon(Icons.catching_pokemon, color: Colors.grey, size: 24),
                      ),
                    ),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.catching_pokemon, color: Colors.grey, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.getPokemonName(language),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: first.pokemonTypes.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: TypeChip(type: t, language: language, fontSize: 9),
                          )).toList(),
                        ),
                        if (pokemonAreaNames.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            pokemonAreaNames.join(', '),
                            style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        globalLevelText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            ...methods.map((m) => MethodRow(method: m)),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPokemon(pokemonId: first.pokemonId),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: Text(
                                  language == 'fr' ? 'Voir le Pokémon' : 'View Pokémon',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _sortedAreaNames(List<LocationPokemonEncounter> encounters, String language) =>
    (encounters.map((e) => e.getAreaName(language)).where((a) => a.isNotEmpty).toSet().toList()..sort());

/// Merge encounters with same level range and area into a single entry with summed chance.
List<({String levelText, int chance, String area})> _mergeByLevel(List<LocationPokemonEncounter> encounters, {String language = 'fr', bool forceArea = false}) {
  final hasMultipleAreas = encounters.map((e) => e.areaIdentifier).toSet().length > 1;
  final showArea = hasMultipleAreas || forceArea;
  final map = <String, ({int chance, String area})>{};
  for (final e in encounters) {
    final levelPart = e.minLevel == e.maxLevel
        ? 'Niv. ${e.minLevel}'
        : 'Niv. ${e.minLevel}–${e.maxLevel}';
    final areaName = showArea ? e.getAreaName(language) : '';
    final key = showArea && areaName.isNotEmpty ? '$levelPart|$areaName' : levelPart;
    final existing = map[key];
    map[key] = (chance: (existing?.chance ?? 0) + e.chance, area: areaName);
  }
  final result = map.entries.map((e) => (
    levelText: e.key.split('|').first,
    chance: e.value.chance > 100 ? 100 : e.value.chance,
    area: e.value.area,
  )).toList();
  // Sort by area name, then by level text
  result.sort((a, b) {
    final cmp = a.area.compareTo(b.area);
    if (cmp != 0) return cmp;
    return a.levelText.compareTo(b.levelText);
  });
  return result;
}

class _PokemonEncounterTile extends StatefulWidget {
  final List<LocationPokemonEncounter> encounters;
  final String language;

  const _PokemonEncounterTile({required this.encounters, required this.language});

  @override
  State<_PokemonEncounterTile> createState() => _PokemonEncounterTileState();
}

class _PokemonEncounterTileState extends State<_PokemonEncounterTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final first = widget.encounters.first;
    final language = widget.language;
    final settings = context.watch<UserSettings>();
    final showCapture = settings.capturedFeature;
    final userDatas = context.watch<UserDatas>();
    final isCaptured = userDatas.getUserPokemon(first.pokemonIdentifier)?.isCapturedIn(first.versionGroupId) ?? false;

    var globalMin = widget.encounters.first.minLevel;
    var globalMax = widget.encounters.first.maxLevel;
    for (final e in widget.encounters) {
      if (e.minLevel < globalMin) globalMin = e.minLevel;
      if (e.maxLevel > globalMax) globalMax = e.maxLevel;
    }
    final globalLevelText = globalMin == globalMax
        ? 'Niv. $globalMin'
        : 'Niv. $globalMin–$globalMax';

    final mergedLevels = _mergeByLevel(widget.encounters, language: language, forceArea: true);
    // Average chance across areas if multiple
    final byArea = <String, List<LocationPokemonEncounter>>{};
    for (final e in widget.encounters) {
      (byArea[e.areaIdentifier] ??= []).add(e);
    }
    int totalChance;
    if (byArea.length <= 1) {
      totalChance = mergedLevels.fold(0, (sum, e) => sum + e.chance);
    } else {
      var areaSum = 0;
      for (final areaEncs in byArea.values) {
        var t = _mergeByLevel(areaEncs, language: language).fold(0, (sum, e) => sum + e.chance);
        if (t > 100) t = 100;
        areaSum += t;
      }
      totalChance = areaSum ~/ byArea.length;
    }
    if (totalChance > 100) totalChance = 100;
    final hasLevelDetail = mergedLevels.length > 1;

    final areaNames = _sortedAreaNames(widget.encounters, language);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: hasLevelDetail ? () => setState(() => _expanded = !_expanded) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showCapture)
                    GestureDetector(
                      onTap: () {
                        userDatas.capturedPokemon(first.pokemonIdentifier, !isCaptured, versionGroupId: first.versionGroupId);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          isCaptured ? Icons.catching_pokemon : Icons.catching_pokemon_outlined,
                          size: 22,
                          color: isCaptured ? const Color(0xFFE53935) : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  CachedNetworkImage(
                    imageUrl: first.spriteUrl,
                    width: 48,
                    height: 48,
                    placeholder: (_, _) => const SizedBox(
                      width: 48, height: 48,
                      child: Center(
                        child: Icon(Icons.catching_pokemon, color: Colors.grey, size: 24),
                      ),
                    ),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.catching_pokemon, color: Colors.grey, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.getPokemonName(language),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: first.pokemonTypes.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: TypeChip(type: t, language: language, fontSize: 9),
                          )).toList(),
                        ),
                        if (areaNames.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            areaNames.join(', '),
                            style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            globalLevelText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: chanceColor(totalChance),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$totalChance%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasLevelDetail) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              if (hasLevelDetail)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            ...mergedLevels.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    if (e.area.isNotEmpty) ...[
                                      Text(
                                        e.area,
                                        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400, fontStyle: FontStyle.italic),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      e.levelText,
                                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: chanceColor(e.chance).withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${e.chance}%',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPokemon(pokemonId: first.pokemonId),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: Text(
                                  language == 'fr' ? 'Voir le Pokémon' : 'View Pokémon',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
