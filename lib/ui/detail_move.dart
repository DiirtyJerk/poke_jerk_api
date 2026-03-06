import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/move.dart';
import 'package:poke_jerk_api/model/pokedex_filter_data.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/filter_bottom_sheet.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:poke_jerk_api/ui/widgets/version_group_chip.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:provider/provider.dart';

class DetailMove extends StatefulWidget {
  final int moveId;

  const DetailMove({super.key, required this.moveId});

  @override
  State<DetailMove> createState() => _DetailMoveState();
}

class _DetailMoveState extends State<DetailMove> {
  VersionGroup? _localVersionGroup;
  int? _localPokedexId;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final filter = context.watch<GlobalFilterProvider>();
    final activeVg = _localVersionGroup ?? filter.selectedVersionGroup;
    final activePokedexId = _localVersionGroup != null
        ? _localPokedexId
        : filter.selectedPokedexId;

    final Map<String, dynamic> pokemonMovesWhere;
    if (activeVg != null) {
      final vgFilter = <String, dynamic>{'version_group_id': {'_eq': activeVg.id}};
      if (activePokedexId != null) {
        vgFilter['pokemon_v2_pokemon'] = {
          'pokemon_v2_pokemonspecy': {
            'pokemon_v2_pokemondexnumbers': {
              'pokedex_id': {'_eq': activePokedexId},
            },
          },
        };
      }
      pokemonMovesWhere = vgFilter;
    } else {
      pokemonMovesWhere = {};
    }

    return Query(
      options: QueryOptions(
        document: gql(getMoveDetailQuery),
        variables: {
          'moveId': widget.moveId,
          'pokemonMovesWhere': pokemonMovesWhere,
        },
        fetchPolicy: FetchPolicy.noCache,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading && result.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const qr.LoadingWidget(),
          );
        }

        final data = result.data?['pokemon_v2_move_by_pk'] as Map<String, dynamic>?;
        if (data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: qr.EmptyWidget(
              message: language == 'fr' ? 'Capacité introuvable' : 'Move not found',
            ),
          );
        }

        final move = Move.fromJson(data);
        final typeColor = move.type != null
            ? ColorBuilder.getTypeColor(move.type!)
            : Colors.grey;

        // Flavor text
        final flavorTexts = data['pokemon_v2_moveflavortexts'] as List? ?? [];
        final lid = langId(language);
        String flavorText = '';
        for (final ft in flavorTexts) {
          if (ft['language_id'] == lid) {
            flavorText = (ft['flavor_text'] as String? ?? '').replaceAll('\n', ' ');
            break;
          }
        }
        if (flavorText.isEmpty && flavorTexts.isNotEmpty) {
          flavorText = (flavorTexts.first['flavor_text'] as String? ?? '').replaceAll('\n', ' ');
        }

        // Pokémon list
        final pokemonMoves = data['pokemon_v2_pokemonmoves'] as List? ?? [];
        final pokemons = <_PokemonEntry>[];
        for (final pm in pokemonMoves) {
          final pkmn = pm['pokemon_v2_pokemon'] as Map<String, dynamic>?;
          if (pkmn == null) continue;
          final id = pkmn['id'] as int;
          if (id > 10000) continue;
          final speciesNames = <int, String>{};
          final species = pkmn['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
          if (species != null) {
            for (final n in (species['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
              speciesNames[n['language_id'] as int] = n['name'] as String;
            }
          }
          final types = <TypePokemon>[];
          for (final pt in (pkmn['pokemon_v2_pokemontypes'] as List? ?? [])) {
            types.add(TypePokemon.fromJson(pt['pokemon_v2_type'] as Map<String, dynamic>));
          }
          pokemons.add(_PokemonEntry(
            id: id,
            names: speciesNames,
            types: types,
          ));
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: typeColor,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          HSLColor.fromColor(typeColor).withLightness(0.3).toColor(),
                          typeColor,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              move.getTranslation(language),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (move.type != null)
                                  TypeChip(type: move.type!, language: language),
                                if (move.damageClass != null) ...[
                                  const SizedBox(width: 8),
                                  _DamageClassBadge(
                                    damageClass: move.damageClass!,
                                    language: language,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatCard(
                            label: language == 'fr' ? 'Puissance' : 'Power',
                            value: move.power > 0 ? '${move.power}' : '—',
                            color: typeColor,
                          ),
                          _StatCard(
                            label: 'PP',
                            value: move.pp > 0 ? '${move.pp}' : '—',
                            color: typeColor,
                          ),
                          _StatCard(
                            label: language == 'fr' ? 'Précision' : 'Accuracy',
                            value: move.accuracy > 0 ? '${move.accuracy}%' : '—',
                            color: typeColor,
                          ),
                          _StatCard(
                            label: language == 'fr' ? 'Priorité' : 'Priority',
                            value: '${move.priority}',
                            color: typeColor,
                          ),
                        ],
                      ),
                      if (flavorText.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          flavorText,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Version selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showVersionPicker(context, filter, language),
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

              // Pokémon list header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        margin: const EdgeInsets.only(right: 8),
                        color: typeColor,
                      ),
                      Text(
                        'Pokémon (${pokemons.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pokémon list
              if (pokemons.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = pokemons[index];
                      return _PokemonTile(
                        entry: p,
                        language: language,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPokemon(pokemonId: p.id),
                          ),
                        ),
                      );
                    },
                    childCount: pokemons.length,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      activeVg != null
                          ? (language == 'fr'
                              ? 'Aucun Pokémon dans ${activeVg.getName(language)}'
                              : 'No Pokémon in ${activeVg.getName(language)}')
                          : (language == 'fr'
                              ? 'Aucun Pokémon'
                              : 'No Pokémon'),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
    );
  }

  void _showVersionPicker(BuildContext context, GlobalFilterProvider filter, String language) {
    if (!filter.filtersLoaded || filter.versionGroups.isEmpty) return;
    final activeVg = _localVersionGroup ?? filter.selectedVersionGroup;

    showFilterBottomSheet(
      context: context,
      title: language == 'fr' ? 'Filtrer par version' : 'Filter by version',
      language: language,
      showClear: activeVg != null,
      onClear: () => setState(() {
        _localVersionGroup = null;
        _localPokedexId = null;
      }),
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
                  _selectLocalVersionGroup(context, g, language);
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

  void _selectLocalVersionGroup(BuildContext context, VersionGroup group, String language) {
    if (group.pokedexes.length <= 1) {
      setState(() {
        _localVersionGroup = group;
        _localPokedexId = group.pokedexes.isNotEmpty ? group.pokedexes.first.id : null;
      });
      return;
    }

    final color = ColorBuilder.getVersionGroupColor(group.identifier);
    showDialog<PokedexEntry>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Row(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(group.getName(language)),
          ],
        ),
        children: group.pokedexes
            .map((d) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(d.name),
                  ),
                ))
            .toList(),
      ),
    ).then((dex) {
      if (dex != null) {
        setState(() {
          _localVersionGroup = group;
          _localPokedexId = dex.id;
        });
      }
    });
  }
}

class _PokemonEntry {
  final int id;
  final Map<int, String> names;
  final List<TypePokemon> types;

  _PokemonEntry({required this.id, required this.names, required this.types});

  String getTranslation(String language) => localizedName(names, language, '');

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}

class _DamageClassBadge extends StatelessWidget {
  final DamageClass damageClass;
  final String language;

  const _DamageClassBadge({required this.damageClass, required this.language});

  @override
  Widget build(BuildContext context) {
    final icon = switch (damageClass.identifier) {
      'physical' => Icons.flash_on,
      'special'  => Icons.auto_awesome,
      _          => Icons.remove,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            damageClass.getTranslation(language),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _PokemonTile extends StatelessWidget {
  final _PokemonEntry entry;
  final String language;
  final VoidCallback onTap;

  const _PokemonTile({
    required this.entry,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: entry.spriteUrl,
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        placeholder: (_, _) => const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.catching_pokemon, color: Colors.grey, size: 24),
        ),
        errorWidget: (_, _, _) =>
            const Icon(Icons.catching_pokemon, size: 24, color: Colors.grey),
      ),
      title: Text(entry.getTranslation(language)),
      subtitle: Wrap(
        spacing: 4,
        children: entry.types
            .map((t) => TypeChip(type: t, language: language, fontSize: 9))
            .toList(),
      ),
      trailing: Text(
        '#${entry.id.toString().padLeft(4, '0')}',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}
