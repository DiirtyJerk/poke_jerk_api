import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokedex_filter_data.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/detail_move.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/filter_bottom_sheet.dart';
import 'package:poke_jerk_api/utils/sprite_utils.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/ui/widgets/version_group_chip.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:provider/provider.dart';

class DetailItem extends StatelessWidget {
  final int itemId;

  const DetailItem({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;

    return Query(
      options: QueryOptions(
        document: gql(getItemDetailQuery),
        variables: {'itemId': itemId},
        fetchPolicy: FetchPolicy.noCache,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading && result.data == null) {
          return Scaffold(appBar: AppBar(), body: const qr.LoadingWidget());
        }

        final data = result.data?['pokemon_v2_item_by_pk'] as Map<String, dynamic>?;
        if (data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: qr.EmptyWidget(
              message: language == 'fr' ? 'Objet introuvable' : 'Item not found',
            ),
          );
        }

        return _DetailContent(data: data, language: language);
      },
    );
  }
}

class _DetailContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final String language;

  const _DetailContent({required this.data, required this.language});

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  VersionGroup? _localVersionGroup;

  String get language => widget.language;
  Map<String, dynamic> get data => widget.data;

  String _localizedName(List? raw) {
    if (raw == null) return '';
    final lid = langId(language);
    for (final n in raw) {
      if (n['language_id'] == lid) return n['name'] as String;
    }
    for (final n in raw) {
      if (n['language_id'] == 9) return n['name'] as String;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<GlobalFilterProvider>();
    final activeVg = _localVersionGroup ?? filter.selectedVersionGroup;
    final activeVersionIds = activeVg?.versionIds ?? [];
    final activeVgId = activeVg?.id;

    final identifier = data['name'] as String;
    final cost = data['cost'] as int? ?? 0;
    final flingPower = data['fling_power'] as int?;
    final itemName = _localizedName(data['pokemon_v2_itemnames'] as List?);

    final cat = data['pokemon_v2_itemcategory'] as Map<String, dynamic>?;
    final categoryName = cat != null
        ? _localizedName(cat['pokemon_v2_itemcategorynames'] as List?)
        : '';

    // Flavor text
    final flavorTexts = data['pokemon_v2_itemflavortexts'] as List? ?? [];
    String flavorText = '';
    final lid = langId(language);
    for (final ft in flavorTexts) {
      if (ft['language_id'] == lid) {
        flavorText = (ft['flavor_text'] as String? ?? '').replaceAll('\n', ' ');
        break;
      }
    }
    if (flavorText.isEmpty && flavorTexts.isNotEmpty) {
      flavorText = (flavorTexts.first['flavor_text'] as String? ?? '').replaceAll('\n', ' ');
    }

    // Effect text
    final effectTexts = data['pokemon_v2_itemeffecttexts'] as List? ?? [];
    String effectText = '';
    for (final et in effectTexts) {
      if (et['language_id'] == lid) {
        effectText = et['short_effect'] as String? ?? '';
        break;
      }
    }
    if (effectText.isEmpty && effectTexts.isNotEmpty) {
      effectText = effectTexts.first['short_effect'] as String? ?? '';
    }

    // Pokemon holding this item
    final pokemonItems = data['pokemon_v2_pokemonitems'] as List? ?? [];
    final holdEntries = <_HoldEntry>[];
    for (final pi in pokemonItems) {
      final pkmnData = pi['pokemon_v2_pokemon'] as Map<String, dynamic>?;
      if (pkmnData == null) continue;
      final pkmnId = pkmnData['id'] as int;
      if (pkmnId > 10000) continue;

      final speciesNames = <int, String>{};
      final species = pkmnData['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
      if (species != null) {
        for (final n in (species['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
          speciesNames[n['language_id'] as int] = n['name'] as String;
        }
      }

      final types = <TypePokemon>[];
      for (final pt in (pkmnData['pokemon_v2_pokemontypes'] as List? ?? [])) {
        types.add(TypePokemon.fromJson(pt['pokemon_v2_type'] as Map<String, dynamic>));
      }

      final versionData = pi['pokemon_v2_version'] as Map<String, dynamic>?;
      final versionName = versionData != null
          ? _localizedName(versionData['pokemon_v2_versionnames'] as List?)
          : '';
      final versionIdentifier = versionData?['name'] as String? ?? '';

      holdEntries.add(_HoldEntry(
        pokemonId: pkmnId,
        pokemonNames: speciesNames,
        types: types,
        rarity: pi['rarity'] as int? ?? 0,
        versionName: versionName,
        versionId: versionData?['id'] as int? ?? 0,
        versionIdentifier: versionIdentifier,
      ));
    }

    // Filter held entries by active version
    final filteredHoldEntries = activeVersionIds.isNotEmpty
        ? holdEntries.where((h) => activeVersionIds.contains(h.versionId)).toList()
        : holdEntries;

    // Group hold entries by version identifier, then by pokemon
    final holdByVersion = <String, List<_HoldEntry>>{};
    for (final h in filteredHoldEntries) {
      holdByVersion.putIfAbsent(h.versionIdentifier, () => []).add(h);
    }
    final sortedHoldVersions = holdByVersion.entries.toList()
      ..sort((a, b) => a.value.first.versionId.compareTo(b.value.first.versionId));

    // Machines (TM/HM)
    final machines = data['pokemon_v2_machines'] as List? ?? [];
    final machineEntries = <_MachineEntry>[];
    for (final m in machines) {
      final moveData = m['pokemon_v2_move'] as Map<String, dynamic>?;
      if (moveData == null) continue;
      final moveName = _localizedName(moveData['pokemon_v2_movenames'] as List?);
      final moveType = moveData['pokemon_v2_type'] as Map<String, dynamic>?;

      final vgData = m['pokemon_v2_versiongroup'] as Map<String, dynamic>?;
      final vgId = vgData?['id'] as int? ?? 0;
      final versionNames = <String>[];
      if (vgData != null) {
        for (final v in (vgData['pokemon_v2_versions'] as List? ?? [])) {
          final vn = _localizedName(v['pokemon_v2_versionnames'] as List?);
          if (vn.isNotEmpty) versionNames.add(vn);
        }
      }

      machineEntries.add(_MachineEntry(
        number: m['machine_number'] as int? ?? 0,
        moveId: moveData['id'] as int,
        moveName: moveName,
        moveType: moveType != null ? TypePokemon.fromJson(moveType) : null,
        versions: versionNames.join(' / '),
        versionGroupId: vgId,
      ));
    }

    // Filter machines by active version group
    final filteredMachines = activeVgId != null
        ? machineEntries.where((m) => m.versionGroupId == activeVgId).toList()
        : machineEntries;

    // Evolutions triggered by this item
    final evoRaw = data['pokemon_v2_pokemonevolutions'] as List? ?? [];
    final evoEntries = <_EvolutionEntry>[];
    final seenEvoIds = <int>{};
    for (final evo in evoRaw) {
      final species = evo['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
      if (species == null) continue;
      final toSpeciesId = species['id'] as int;
      if (seenEvoIds.contains(toSpeciesId)) continue;
      seenEvoIds.add(toSpeciesId);

      final fromSpeciesId = species['evolves_from_species_id'] as int?;
      final generationId = species['generation_id'] as int? ?? 0;

      final dexNumbers = species['pokemon_v2_pokemondexnumbers'] as List? ?? [];
      final pokedexIds = dexNumbers.map((d) => d['pokedex_id'] as int).toSet();

      final toNames = <int, String>{};
      for (final n in (species['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
        toNames[n['language_id'] as int] = n['name'] as String;
      }

      final pokemons = species['pokemon_v2_pokemons'] as List? ?? [];
      final toPokemonId = pokemons.isNotEmpty ? (pokemons.first['id'] as int) : toSpeciesId;

      final toTypes = <TypePokemon>[];
      if (pokemons.isNotEmpty) {
        for (final pt in (pokemons.first['pokemon_v2_pokemontypes'] as List? ?? [])) {
          toTypes.add(TypePokemon.fromJson(pt['pokemon_v2_type'] as Map<String, dynamic>));
        }
      }

      evoEntries.add(_EvolutionEntry(
        fromSpeciesId: fromSpeciesId,
        toPokemonId: toPokemonId,
        toNames: toNames,
        toTypes: toTypes,
        generationId: generationId,
        pokedexIds: pokedexIds,
      ));
    }

    // Filter evolutions by selected pokédex
    final selectedPokedexId = filter.selectedPokedexId;
    final filteredEvoEntries = selectedPokedexId != null
        ? evoEntries.where((e) => e.pokedexIds.contains(selectedPokedexId)).toList()
        : evoEntries;

    final spriteUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$identifier.png';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.teal,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Row(
              children: [
                CachedNetworkImage(
                  imageUrl: spriteUrl,
                  width: 32,
                  height: 32,
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.inventory_2, size: 32, color: Colors.white54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName.isNotEmpty ? itemName : identifier,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(32),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  children: [
                    if (categoryName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    if (cost > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$cost ₽',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],


                  ],
                ),
              ),
            ),
          ),

          // ── Description ──
          if (flavorText.isNotEmpty || effectText.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (flavorText.isNotEmpty)
                      Text(flavorText, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    if (flavorText.isNotEmpty && effectText.isNotEmpty)
                      const SizedBox(height: 8),
                    if (effectText.isNotEmpty)
                      Text(effectText, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

          // ── Stats row ──
          if (cost > 0 || flingPower != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (cost > 0)
                      _InfoChip(label: language == 'fr' ? 'Prix' : 'Cost', value: '$cost ₽'),
                    if (cost > 0 && flingPower != null) const SizedBox(width: 12),
                    if (flingPower != null)
                      _InfoChip(label: language == 'fr' ? 'Lancer' : 'Fling', value: '$flingPower'),
                  ],
                ),
              ),
            ),

          // ── Version selector (centered chip, same style as VersionSelectorButton) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Center(
                child: GestureDetector(
                  onTap: () => _showVersionPicker(context, filter),
                  child: activeVg != null
                      ? VersionGroupChip(
                          label: activeVg.getName(language),
                          versionIdentifiers: activeVg.versionIdentifiers,
                        )
                      : Chip(
                          avatar: const Icon(Icons.sports_esports_outlined, size: 16, color: Colors.black87),
                          label: Text(
                            language == 'fr' ? 'Version' : 'Version',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                ),
              ),
            ),
          ),

          // ── Obtention: Purchase ──
          if (cost > 0) ...[
            _SectionHeader(
              title: language == 'fr' ? 'Achat' : 'Purchase',
              icon: Icons.storefront_outlined,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Card(
                  elevation: 0,
                  color: Colors.teal.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.teal.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            language == 'fr'
                                ? 'Disponible en boutique'
                                : 'Available in shops',
                            style: TextStyle(fontSize: 13, color: Colors.teal.shade800),
                          ),
                        ),
                        Text(
                          '$cost ₽',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Obtention: Held by wild Pokemon ──
          if (filteredHoldEntries.isNotEmpty) ...[
            _SectionHeader(
              title: language == 'fr'
                  ? 'Tenu par des Pokémon sauvages (${_uniquePokemonCount(filteredHoldEntries)})'
                  : 'Held by wild Pokémon (${_uniquePokemonCount(filteredHoldEntries)})',
              icon: Icons.catching_pokemon,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: sortedHoldVersions.map((entry) {
                    final versionId = entry.key;
                    final entries = entry.value;
                    final bgColor = ColorBuilder.getVersionColor(versionId);
                    final textColor = ColorBuilder.getVersionTextColor(versionId);
                    final versionLabel = entries.first.versionName;

                    // Group by pokemon within this version
                    final byPokemon = <int, List<_HoldEntry>>{};
                    for (final h in entries) {
                      byPokemon.putIfAbsent(h.pokemonId, () => []).add(h);
                    }

                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: activeVgId != null,
                        tilePadding: const EdgeInsets.only(left: 0, right: 8, top: 4),
                        childrenPadding: EdgeInsets.zero,
                        title: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$versionLabel (${byPokemon.length})',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        children: byPokemon.entries.map((pkmnEntry) {
                          final pkmnId = pkmnEntry.key;
                          final pkmnEntries = pkmnEntry.value;
                          final first = pkmnEntries.first;
                          final pkmnName = localizedName(first.pokemonNames, language, '');
                          return _HoldPokemonTile(
                            pokemonId: pkmnId,
                            name: pkmnName,
                            types: first.types,
                            rarity: first.rarity,
                            language: language,
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ] else if (holdEntries.isNotEmpty && activeVgId != null) ...[
            _SectionHeader(
              title: language == 'fr' ? 'Tenu par des Pokémon sauvages' : 'Held by wild Pokémon',
              icon: Icons.catching_pokemon,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  language == 'fr'
                      ? 'Aucun Pokémon ne tient cet objet dans ${activeVg!.getName(language)}'
                      : 'No Pokémon holds this item in ${activeVg!.getName(language)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],

          // ── Evolutions triggered by this item ──
          if (filteredEvoEntries.isNotEmpty) ...[
            _SectionHeader(
              title: language == 'fr'
                  ? 'Évolutions (${filteredEvoEntries.length})'
                  : 'Evolutions (${filteredEvoEntries.length})',
              icon: Icons.swap_horiz,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final evo = filteredEvoEntries[index];
                  final toName = localizedName(evo.toNames, language, '');
                  final fromId = evo.fromSpeciesId;
                  final toId = evo.toPokemonId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Card(
                      elevation: 0,
                      color: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailPokemon(pokemonId: toId)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              if (fromId != null) ...[
                                CachedNetworkImage(
                                  imageUrl: pokemonSpriteUrl(fromId),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const SizedBox(width: 48, height: 48),
                                  errorWidget: (_, _, _) =>
                                      const Icon(Icons.catching_pokemon, size: 24, color: Colors.grey),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 18, color: Colors.teal.shade700),
                                const SizedBox(width: 4),
                              ],
                              CachedNetworkImage(
                                imageUrl: pokemonSpriteUrl(toId),
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => const SizedBox(width: 48, height: 48),
                                errorWidget: (_, _, _) =>
                                    const Icon(Icons.catching_pokemon, size: 24, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      toName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal.shade900,
                                      ),
                                    ),
                                    if (evo.toTypes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: evo.toTypes
                                            .map((t) => TypeChip(type: t, language: language, fontSize: 9))
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '#${toId.toString().padLeft(4, '0')}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: filteredEvoEntries.length,
              ),
            ),
          ],

          // ── TM/HM ──
          if (filteredMachines.isNotEmpty) ...[
            _SectionHeader(
              title: language == 'fr' ? 'CT / CS' : 'TM / HM',
              icon: Icons.album_outlined,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = filteredMachines[index];
                  final typeColor = m.moveType != null
                      ? ColorBuilder.getTypeColor(m.moveType!)
                      : Colors.grey;
                  return ListTile(
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                    ),
                    title: Text('CT${m.number.toString().padLeft(2, '0')} — ${m.moveName}'),
                    subtitle: activeVgId != null
                        ? null
                        : Text(m.versions,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailMove(moveId: m.moveId)),
                    ),
                  );
                },
                childCount: filteredMachines.length,
              ),
            ),
          ] else if (machineEntries.isNotEmpty && activeVgId != null) ...[
            _SectionHeader(
              title: language == 'fr' ? 'CT / CS' : 'TM / HM',
              icon: Icons.album_outlined,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  language == 'fr'
                      ? 'Aucune CT/CS dans ${activeVg!.getName(language)}'
                      : 'No TM/HM in ${activeVg!.getName(language)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  int _uniquePokemonCount(List<_HoldEntry> entries) {
    return entries.map((e) => e.pokemonId).toSet().length;
  }

  void _showVersionPicker(BuildContext context, GlobalFilterProvider filter) {
    if (!filter.filtersLoaded || filter.versionGroups.isEmpty) return;
    final activeVg = _localVersionGroup ?? filter.selectedVersionGroup;

    showFilterBottomSheet(
      context: context,
      title: language == 'fr' ? 'Filtrer par version' : 'Filter by version',
      language: language,
      showClear: activeVg != null,
      onClear: () => setState(() => _localVersionGroup = null),
      builder: (scrollController) {
        return ListView.separated(
          controller: scrollController,
          itemCount: filter.versionGroups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final g = filter.versionGroups[index];
            final isSelected = activeVg?.id == g.id;
            return AnimatedOpacity(
              opacity: activeVg != null && !isSelected ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _localVersionGroup = g);
                },
                child: VersionGroupChip(
                  label: g.getName(language),
                  versionIdentifiers: g.versionIdentifiers,
                  fillWidth: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const _SectionHeader({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(width: 4, height: 18, margin: const EdgeInsets.only(right: 8), color: Colors.teal),
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.teal.shade700),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HoldPokemonTile extends StatelessWidget {
  final int pokemonId;
  final String name;
  final List<TypePokemon> types;
  final int rarity;
  final String language;

  const _HoldPokemonTile({
    required this.pokemonId,
    required this.name,
    required this.types,
    required this.rarity,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final spriteUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png';

    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: spriteUrl,
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        placeholder: (_, _) => const SizedBox(
          width: 44, height: 44,
          child: Icon(Icons.catching_pokemon, color: Colors.grey, size: 24),
        ),
        errorWidget: (_, _, _) =>
            const Icon(Icons.catching_pokemon, size: 24, color: Colors.grey),
      ),
      title: Text(name),
      subtitle: Wrap(
        spacing: 4,
        children: types.map((t) => TypeChip(type: t, language: language, fontSize: 9)).toList(),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rarity%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          Text(
            '#${pokemonId.toString().padLeft(4, '0')}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPokemon(pokemonId: pokemonId)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _HoldEntry {
  final int pokemonId;
  final Map<int, String> pokemonNames;
  final List<TypePokemon> types;
  final int rarity;
  final String versionName;
  final int versionId;
  final String versionIdentifier;

  _HoldEntry({
    required this.pokemonId,
    required this.pokemonNames,
    required this.types,
    required this.rarity,
    required this.versionName,
    required this.versionId,
    required this.versionIdentifier,
  });
}

class _MachineEntry {
  final int number;
  final int moveId;
  final String moveName;
  final TypePokemon? moveType;
  final String versions;
  final int versionGroupId;

  _MachineEntry({
    required this.number,
    required this.moveId,
    required this.moveName,
    required this.moveType,
    required this.versions,
    required this.versionGroupId,
  });
}

class _EvolutionEntry {
  final int? fromSpeciesId;
  final int toPokemonId;
  final Map<int, String> toNames;
  final List<TypePokemon> toTypes;
  final int generationId;
  final Set<int> pokedexIds;

  _EvolutionEntry({
    required this.fromSpeciesId,
    required this.toPokemonId,
    required this.toNames,
    required this.toTypes,
    required this.generationId,
    required this.pokedexIds,
  });
}
