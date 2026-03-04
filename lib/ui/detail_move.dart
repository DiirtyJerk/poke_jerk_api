import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/move.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:provider/provider.dart';

class DetailMove extends StatelessWidget {
  final int moveId;

  const DetailMove({super.key, required this.moveId});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;

    return Query(
      options: QueryOptions(
        document: gql(getMoveDetailQuery),
        variables: {'moveId': moveId},
        fetchPolicy: FetchPolicy.cacheFirst,
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
        final langId = language == 'fr' ? 5 : 9;
        String flavorText = '';
        for (final ft in flavorTexts) {
          if (ft['language_id'] == langId) {
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
          // Skip alt forms (id > 10000)
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
                        language == 'fr'
                            ? 'Pokémon (${pokemons.length})'
                            : 'Pokémon (${pokemons.length})',
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
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
    );
  }
}

class _PokemonEntry {
  final int id;
  final Map<int, String> names;
  final List<TypePokemon> types;

  _PokemonEntry({required this.id, required this.names, required this.types});

  String getTranslation(String language) {
    final langId = language == 'fr' ? 5 : 9;
    return names[langId] ?? names[9] ?? '';
  }

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
