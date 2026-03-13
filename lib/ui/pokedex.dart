import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/team_provider.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/comparator_provider.dart';
import 'package:poke_jerk_api/model/users_datas.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/widgets/pokemon_card.dart';
import 'package:poke_jerk_api/ui/widgets/list_loading_skeleton.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/utils/sprite_utils.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:provider/provider.dart';

class Pokedex extends StatefulWidget {
  const Pokedex({super.key});

  @override
  State<Pokedex> createState() => _PokedexState();
}

class _PokedexState extends State<Pokedex> {
  final ScrollController _scrollController = ScrollController();

  List<Pokemon> _allPokemons = [];
  bool _isLoading = false;
  String? _error;

  // Capture filter: 0 = all, 1 = captured only, 2 = not captured only
  int _captureFilter = 0;

  // Track which filter was used to load, to detect changes
  int? _loadedPokedexId;
  bool _loadedWithoutPokedex = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final filter = context.read<GlobalFilterProvider>();
    if (filter.filtersLoaded && _allPokemons.isEmpty && !_isLoading) {
      _loadAll();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_isLoading) return;
    final filter = context.read<GlobalFilterProvider>();

    setState(() => _isLoading = true);

    final client = GraphQLProvider.of(context).value;
    const basicWhere = {
      'is_default': {'_eq': true},
    };

    final pokedexId = filter.selectedPokedexId;

    if (pokedexId != null) {
      final regionalForm = filter.selectedVersionGroup?.regionalForm;

      final result = await client.query(
        QueryOptions(
          document: gql(getPokemonsByPokedexQuery),
          variables: {'pokedexId': pokedexId},
          fetchPolicy: FetchPolicy.noCache,
        ),
      );

      if (!mounted) return;
      if (result.hasException) {
        setState(() { _error = result.exception.toString(); _isLoading = false; });
        return;
      }

      final entries =
          result.data?['pokemon_v2_pokemondexnumber'] as List? ?? [];
      final pokemons = <Pokemon>[];
      for (final entry in entries) {
        final specyJson =
            entry['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
        if (specyJson == null) continue;
        final allForms = specyJson['pokemon_v2_pokemons'] as List?;
        if (allForms == null || allForms.isEmpty) continue;

        // Pick the best form: regional match > default
        final picked = _pickForm(allForms, regionalForm);
        if (picked == null) continue;

        final pokemonJson = Map<String, dynamic>.from(picked);
        pokemonJson['pokemon_v2_pokemonspecy'] = {
          'generation_id': specyJson['generation_id'],
          'pokemon_v2_pokemonspeciesnames':
              specyJson['pokemon_v2_pokemonspeciesnames'],
        };
        pokemonJson['pokedex_number'] = entry['pokedex_number'] as int?;
        pokemons.add(Pokemon.fromListJson(pokemonJson));
      }

      setState(() {
        _allPokemons = pokemons;
        _isLoading = false;
        _error = null;
        _loadedPokedexId = pokedexId;
        _loadedWithoutPokedex = false;
      });
      return;
    }

    final result = await client.query(
      QueryOptions(
        document: gql(getPokemonsQuery),
        variables: {'limit': 2000, 'offset': 0, 'where': basicWhere},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (!mounted) return;
    if (result.hasException) {
      setState(() { _error = result.exception.toString(); _isLoading = false; });
      return;
    }

    final data = result.data?['pokemon_v2_pokemon'] as List? ?? [];
    setState(() {
      _allPokemons = data
          .map((p) => Pokemon.fromListJson(p as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      _error = null;
      _loadedPokedexId = null;
      _loadedWithoutPokedex = true;
    });
  }

  /// Pick the best pokemon form for this pokédex.
  /// If [regionalForm] is set (e.g. "galar"), prefer a form matching that name.
  /// Otherwise fall back to the default form.
  Map<String, dynamic>? _pickForm(List allForms, String? regionalForm) {
    Map<String, dynamic>? defaultForm;
    for (final f in allForms) {
      final form = f as Map<String, dynamic>;
      final forms = form['pokemon_v2_pokemonforms'] as List?;
      final formName = (forms != null && forms.isNotEmpty)
          ? (forms.first['form_name'] as String? ?? '')
          : '';
      if (regionalForm != null && formName == regionalForm) {
        return form;
      }
      if (form['is_default'] == true) {
        defaultForm = form;
      }
    }
    return defaultForm ?? (allForms.isNotEmpty ? allForms.first as Map<String, dynamic> : null);
  }

  void _reload() {
    setState(() => _allPokemons = []);
    _loadAll();
  }

  List<Pokemon> _filteredPokemons(
    GlobalFilterProvider filter,
    String language,
  ) {
    var list = _allPokemons;

    if (filter.searchQuery.length >= 2) {
      final query = normalize(filter.searchQuery);
      list = list
          .where((p) => normalize(p.getTranslation(language)).contains(query))
          .toList();
    }

    if (filter.selectedTypeIds.isNotEmpty) {
      list = list
          .where(
            (p) => filter.selectedTypeIds.every(
              (id) => p.types.any((t) => t.id == id),
            ),
          )
          .toList();
    }

    if (filter.selectedGenerationId != null) {
      list = list
          .where((p) => p.generationId == filter.selectedGenerationId)
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final filter = context.watch<GlobalFilterProvider>();

    // Reload if the pokedex filter changed
    if (filter.filtersLoaded) {
      final needsReload =
          (filter.selectedPokedexId != _loadedPokedexId) &&
          (_loadedWithoutPokedex ||
              _loadedPokedexId != null ||
              filter.selectedPokedexId != null);
      if (needsReload && !_isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reload();
        });
      }
    }

    return _buildBody(language, filter);
  }

  Widget _buildBody(String language, GlobalFilterProvider filter) {
    final pokemons = _filteredPokemons(filter, language);
    final settings = context.watch<UserSettings>();
    final userDatas = context.watch<UserDatas>();

    if (_allPokemons.isEmpty && (_isLoading || !filter.filtersLoaded)) {
      return const PokedexListSkeleton();
    }
    if (_error != null && _allPokemons.isEmpty) {
      return qr.ErrorWidget(message: _error!, onRetry: _loadAll);
    }

    if (pokemons.isEmpty) {
      return qr.EmptyWidget(
        message: language == 'fr' ? 'Aucun Pokémon trouvé' : 'No Pokémon found',
      );
    }

    // Capture filter
    final showCapture = settings.capturedFeature;
    final allCount = pokemons.length;
    final capturedCount = showCapture
        ? pokemons.where((p) => userDatas.getUserPokemon(p.identifier)?.captured ?? false).length
        : 0;

    // Apply capture filter
    final displayedPokemons = showCapture && _captureFilter != 0
        ? pokemons.where((p) {
            final isCaptured = userDatas.getUserPokemon(p.identifier)?.captured ?? false;
            return _captureFilter == 1 ? isCaptured : !isCaptured;
          }).toList()
        : pokemons;

    return Column(
      children: [
        if (showCapture)
          GestureDetector(
            onTap: () => setState(() => _captureFilter = (_captureFilter + 1) % 3),
            child: _CaptureProgressBar(
              captured: capturedCount,
              total: allCount,
              language: language,
              filterMode: _captureFilter,
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: displayedPokemons.length,
                itemBuilder: (context, index) {
                  final pokemon = displayedPokemons[index];
                  return PokemonCard(
                    pokemon: pokemon,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPokemon(
                          pokemonId: pokemon.id,
                          versionFilter: filter.versionFilter,
                        ),
                      ),
                    ),
                    onLongPress: () => _showLongPressMenu(context, pokemon, filter),
                  );
                },
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'ranking',
                  onPressed: () => _showRanking(context, displayedPokemons, language, filter),
                  child: const Icon(Icons.emoji_events_outlined),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRanking(BuildContext context, List<Pokemon> pokemons, String language, GlobalFilterProvider filter) {
    // Stat identifiers in display order
    const statKeys = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    String? selectedStat; // null = total
    int? selectedTypeId; // null = all types

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Filter by type
          var filtered = List<Pokemon>.from(pokemons);
          if (selectedTypeId != null) {
            filtered = filtered.where((p) => p.types.any((t) => t.id == selectedTypeId)).toList();
          }

          // Sort pokémon by selected stat
          if (selectedStat == null) {
            filtered.sort((a, b) => b.totalStats.compareTo(a.totalStats));
          } else {
            filtered.sort((a, b) {
              final va = a.stats.entries.where((e) => e.key.identifier == selectedStat).firstOrNull?.value ?? 0;
              final vb = b.stats.entries.where((e) => e.key.identifier == selectedStat).firstOrNull?.value ?? 0;
              return vb.compareTo(va);
            });
          }
          final top = filtered.take(20).toList();

          String chipLabel(String? key) {
            if (key == null) return 'Total';
            final fr = language == 'fr';
            switch (key) {
              case 'hp': return 'PV';
              case 'attack': return fr ? 'ATQ' : 'ATK';
              case 'defense': return fr ? 'DÉF' : 'DEF';
              case 'special-attack': return fr ? 'A.Spé' : 'SpA';
              case 'special-defense': return fr ? 'D.Spé' : 'SpD';
              case 'speed': return fr ? 'VIT' : 'SPE';
              default: return key;
            }
          }

          int statValue(Pokemon p, String? key) {
            if (key == null) return p.totalStats;
            return p.stats.entries.where((e) => e.key.identifier == key).firstOrNull?.value ?? 0;
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    language == 'fr' ? 'Classement' : 'Ranking',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                // Stat chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _RankingChip(
                        label: 'Total',
                        selected: selectedStat == null,
                        onTap: () => setSheetState(() => selectedStat = null),
                      ),
                      ...statKeys.map((key) => _RankingChip(
                        label: chipLabel(key),
                        selected: selectedStat == key,
                        onTap: () => setSheetState(() => selectedStat = key),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedTypeId = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: selectedTypeId == null ? Colors.grey : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                              border: selectedTypeId == null
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                            child: Text(
                              language == 'fr' ? 'Tous' : 'All',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      ...filter.types.map((type) {
                        final color = ColorBuilder.getTypeColor(type);
                        final isSelected = selectedTypeId == type.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedTypeId = type.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? color : color.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                              child: Text(
                                type.getTranslation(language),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: top.isEmpty
                      ? Center(
                          child: Text(
                            language == 'fr' ? 'Aucun Pokémon' : 'No Pokémon',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: top.length,
                          itemBuilder: (ctx, index) {
                            final p = top[index];
                            final val = statValue(p, selectedStat);
                            final maxVal = top.isNotEmpty ? statValue(top.first, selectedStat) : 1;
                            final name = p.getTranslation(language);
                            final imgUrl = p.spriteUrl ?? pokemonArtworkUrl(p.id);
                            final rankColor = index == 0
                                ? const Color(0xFFFFD700)
                                : index == 1
                                    ? const Color(0xFFC0C0C0)
                                    : index == 2
                                        ? const Color(0xFFCD7F32)
                                        : Colors.grey;
                            return InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPokemon(
                                      pokemonId: p.id,
                                      versionFilter: filter.versionFilter,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: Row(
                                  children: [
                                    // Rank number
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${index + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: index < 3 ? 18 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: rankColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Sprite
                                    Image.network(
                                      imgUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
                                    ),
                                    const SizedBox(width: 8),
                                    // Name, types, stat bar
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: p.types
                                                .map((t) => Padding(
                                                      padding: const EdgeInsets.only(right: 4),
                                                      child: TypeChip(type: t, language: language, fontSize: 9),
                                                    ))
                                                .toList(),
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: maxVal > 0 ? val / maxVal : 0,
                                              backgroundColor: Colors.grey.shade200,
                                              color: p.types.isNotEmpty
                                                  ? ColorBuilder.getTypeColor(p.types.first)
                                                  : Theme.of(context).colorScheme.primary,
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Stat value
                                    Text(
                                      '$val',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLongPressMenu(BuildContext context, Pokemon pokemon, GlobalFilterProvider filter) {
    final language = context.read<UserSettings>().language;
    final name = pokemon.getTranslation(language);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            // Compare
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: Text(language == 'fr' ? 'Ajouter au comparateur' : 'Add to comparator'),
              onTap: () {
                Navigator.pop(ctx);
                final comp = context.read<ComparatorProvider>();
                if (comp.contains(pokemon.id)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(language == 'fr'
                        ? '$name est déjà dans le comparateur'
                        : '$name is already in the comparator'),
                    duration: const Duration(seconds: 2),
                  ));
                } else if (comp.isFull) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(language == 'fr'
                        ? 'Le comparateur est plein (${ComparatorProvider.maxCompare} max)'
                        : 'Comparator is full (${ComparatorProvider.maxCompare} max)'),
                    duration: const Duration(seconds: 2),
                  ));
                } else {
                  comp.addPokemon(pokemon.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(language == 'fr'
                        ? '$name ajouté au comparateur (${comp.count}/${ComparatorProvider.maxCompare})'
                        : '$name added to comparator (${comp.count}/${ComparatorProvider.maxCompare})'),
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
            ),
            // Add to team
            ListTile(
              leading: const Icon(Icons.groups),
              title: Text(language == 'fr' ? 'Ajouter à une équipe' : 'Add to a team'),
              onTap: () {
                Navigator.pop(ctx);
                _showTeamPicker(context, pokemon);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTeamPicker(BuildContext context, Pokemon pokemon) {
    final teamProvider = context.read<TeamProvider>();
    final teams = teamProvider.teams;
    final language = context.read<UserSettings>().language;

    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language == 'fr'
              ? 'Créez d\'abord une équipe'
              : 'Create a team first'),
        ),
      );
      return;
    }

    final availableTeams = teams.where((t) => t.pokemonIds.length < 6).toList();
    if (availableTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language == 'fr'
              ? 'Toutes les équipes sont complètes'
              : 'All teams are full'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                language == 'fr'
                    ? 'Ajouter ${pokemon.getTranslation(language)} à…'
                    : 'Add ${pokemon.getTranslation(language)} to…',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...availableTeams.map((team) => ListTile(
                  leading: const Icon(Icons.groups),
                  title: Text(team.name),
                  subtitle: Text('${team.pokemonIds.length}/6'),
                  onTap: () {
                    teamProvider.addPokemon(team, pokemon.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(language == 'fr'
                            ? '${pokemon.getTranslation(language)} ajouté à ${team.name}'
                            : '${pokemon.getTranslation(language)} added to ${team.name}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CaptureProgressBar extends StatelessWidget {
  final int captured;
  final int total;
  final String language;
  final int filterMode; // 0 = all, 1 = captured, 2 = not captured

  const _CaptureProgressBar({
    required this.captured,
    required this.total,
    required this.language,
    this.filterMode = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? captured / total : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);
    final complete = captured == total && total > 0;

    final fr = language == 'fr';
    final filterLabel = filterMode == 1
        ? (fr ? 'Capturés' : 'Captured')
        : filterMode == 2
            ? (fr ? 'Non capturés' : 'Not captured')
            : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: complete
            ? const Color(0xFFE8F5E9)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.catching_pokemon : Icons.catching_pokemon_outlined,
            size: 20,
            color: complete ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$captured / $total',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        if (filterLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: filterMode == 1
                                  ? const Color(0xFFE53935).withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              filterLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: filterMode == 1 ? const Color(0xFFE53935) : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.grey.shade300,
                    color: complete ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RankingChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
