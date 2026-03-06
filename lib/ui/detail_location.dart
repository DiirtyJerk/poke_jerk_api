import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/location.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _loadEncounters();
  }

  Future<void> _loadEncounters() async {
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(getLocationDetailQuery),
      variables: {'locationId': widget.location.id},
      fetchPolicy: FetchPolicy.noCache,
    ));
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
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final filter = context.watch<GlobalFilterProvider>();
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
              : _buildContent(filtered, language),
    );
  }

  int _totalChance(List<LocationPokemonEncounter> encs) {
    final seen = <int>{};
    var total = 0;
    for (final e in encs) {
      if (seen.add(e.slotId)) total += e.chance;
    }
    return total > 100 ? 100 : total;
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

  Widget _buildContent(List<LocationPokemonEncounter> encounters, String language) {
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

        final totalPokemon = entry.value.map((e) => e.pokemonId).toSet().length;
        final hasMultipleMethods = byMethod.length > 1;

        // Build pokemon tiles grouped by method, sorted alphabetically
        final sortedMethods = byMethod.entries.toList()
          ..sort((a, b) => a.value.first.getMethodName(language)
              .compareTo(b.value.first.getMethodName(language)));
        final children = <Widget>[];
        for (final methodEntry in sortedMethods) {
          final methodEncs = methodEntry.value;
          final pokemonTiles = _buildPokemonTiles(methodEncs, language);

          if (hasMultipleMethods) {
            final methodName = methodEncs.first.getMethodName(language);
            children.add(_MethodSection(
              methodName: methodName,
              icon: methodIcon(methodEntry.key),
              pokemonCount: methodEncs.map((e) => e.pokemonId).toSet().length,
              children: pokemonTiles,
            ));
          } else {
            children.addAll(pokemonTiles);
          }
        }

        return VersionHeader(
          versionIdentifier: entry.key,
          versionLabel: entry.value.first.getVersionName(language),
          subtitle: '$totalPokemon Pokémon',
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

class _PokemonEncounterTile extends StatelessWidget {
  final List<LocationPokemonEncounter> encounters;
  final String language;

  const _PokemonEncounterTile({required this.encounters, required this.language});

  @override
  Widget build(BuildContext context) {
    final first = encounters.first;

    final methods = mergeByMethod(
      entries: encounters.map((e) => (
        key: e.methodIdentifier,
        label: e.getMethodName(language),
        slotId: e.slotId,
        minLevel: e.minLevel,
        maxLevel: e.maxLevel,
        chance: e.chance,
      )),
    );

    final globalMin = encounters.map((e) => e.minLevel).reduce((a, b) => a < b ? a : b);
    final globalMax = encounters.map((e) => e.maxLevel).reduce((a, b) => a > b ? a : b);
    final globalLevelText = globalMin == globalMax
        ? 'Niv. $globalMin'
        : 'Niv. $globalMin–$globalMax';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPokemon(pokemonId: first.pokemonId),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
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
                ],
              ),
              const SizedBox(height: 8),
              ...methods.map((m) => MethodRow(method: m)),
            ],
          ),
        ),
      ),
    );
  }
}
