import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/users_datas.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/widgets/capture_progress_bar.dart';
import 'package:poke_jerk_api/ui/widgets/list_loading_skeleton.dart';
import 'package:poke_jerk_api/ui/widgets/pokemon_actions_sheet.dart';
import 'package:poke_jerk_api/ui/widgets/pokemon_card.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:poke_jerk_api/ui/widgets/ranking_sheet.dart';
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
    if (filter.filtersLoaded && filter.filtersLoadError == null && _allPokemons.isEmpty && !_isLoading) {
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

    setState(() { _isLoading = true; _error = null; });

    try {
      final client = GraphQLProvider.of(context).value;
      const queryTimeout = Duration(seconds: 30);

      final pokedexId = filter.selectedPokedexId;

      if (pokedexId != null) {
        final regionalForm = filter.selectedVersionGroup?.regionalForm;

        debugPrint('[Pokedex] fetching by pokedex $pokedexId...');
        final result = await client.query(QueryOptions(
          document: gql(getPokemonsByPokedexQuery),
          variables: {'pokedexId': pokedexId},
          fetchPolicy: FetchPolicy.noCache,
        )).timeout(queryTimeout);
        debugPrint('[Pokedex] pokedex query OK');

        if (!mounted) return;
        if (result.hasException) {
          setState(() { _error = result.exception.toString(); _isLoading = false; });
          return;
        }

        final entries = result.data?['pokemon_v2_pokemondexnumber'] as List? ?? [];
        final pokemons = <Pokemon>[];
        for (final entry in entries) {
          final specyJson = entry['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
          if (specyJson == null) continue;
          final allForms = specyJson['pokemon_v2_pokemons'] as List?;
          if (allForms == null || allForms.isEmpty) continue;

          final picked = _pickForm(allForms, regionalForm);
          if (picked == null) continue;

          final pokemonJson = Map<String, dynamic>.from(picked);
          pokemonJson['pokemon_v2_pokemonspecy'] = {
            'generation_id': specyJson['generation_id'],
            'pokemon_v2_pokemonspeciesnames': specyJson['pokemon_v2_pokemonspeciesnames'],
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

      // Include default forms + regional forms (alola, galar, hisui, paldea)
      const regionalFormNames = ['alola', 'galar', 'hisui', 'paldea'];
      const where = {
        '_or': [
          {'is_default': {'_eq': true}},
          {
            'pokemon_v2_pokemonforms': {
              'form_name': {'_in': regionalFormNames},
            },
          },
        ],
      };

      debugPrint('[Pokedex] fetching all pokemon...');
      final result = await client.query(QueryOptions(
        document: gql(getPokemonsQuery),
        variables: {'limit': 2500, 'offset': 0, 'where': where},
        fetchPolicy: FetchPolicy.noCache,
      )).timeout(queryTimeout);
      debugPrint('[Pokedex] all pokemon query OK');

      if (!mounted) return;
      if (result.hasException) {
        setState(() { _error = result.exception.toString(); _isLoading = false; });
        return;
      }

      final data = result.data?['pokemon_v2_pokemon'] as List? ?? [];
      final parsed = data.map((p) => Pokemon.fromListJson(p as Map<String, dynamic>)).toList();
      // Sort: by national dex ID, then base form first (lower pokemon id = base)
      parsed.sort((a, b) {
        final cmp = a.nationalId.compareTo(b.nationalId);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });
      setState(() {
        _allPokemons = parsed;
        _isLoading = false;
        _error = null;
        _loadedPokedexId = null;
        _loadedWithoutPokedex = true;
      });
    } catch (e, st) {
      debugPrint('[Pokedex] _loadAll ERROR: $e\n$st');
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Map<String, dynamic>? _pickForm(List allForms, String? regionalForm) {
    Map<String, dynamic>? defaultForm;
    for (final f in allForms) {
      final form = f as Map<String, dynamic>;
      final forms = form['pokemon_v2_pokemonforms'] as List?;
      final formName = (forms != null && forms.isNotEmpty)
          ? (forms.first['form_name'] as String? ?? '')
          : '';
      if (regionalForm != null && formName == regionalForm) return form;
      if (form['is_default'] == true) defaultForm = form;
    }
    return defaultForm ?? (allForms.isNotEmpty ? allForms.first as Map<String, dynamic> : null);
  }

  void _reload() {
    if (_isLoading) return;
    final filter = context.read<GlobalFilterProvider>();
    final needsReload =
        (filter.selectedPokedexId != _loadedPokedexId) &&
        (_loadedWithoutPokedex || _loadedPokedexId != null || filter.selectedPokedexId != null);
    if (!needsReload) return;
    setState(() => _allPokemons = []);
    _loadAll();
  }

  List<Pokemon> _filteredPokemons(GlobalFilterProvider filter, String language) {
    var list = _allPokemons;

    if (filter.searchQuery.length >= 2) {
      final query = normalize(filter.searchQuery);
      list = list.where((p) => normalize(p.getTranslation(language)).contains(query)).toList();
    }

    if (filter.selectedTypeIds.isNotEmpty) {
      list = list
          .where((p) => filter.selectedTypeIds.every((id) => p.types.any((t) => t.id == id)))
          .toList();
    }

    if (filter.selectedGenerationId != null) {
      list = list.where((p) => p.generationId == filter.selectedGenerationId).toList();
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
          (_loadedWithoutPokedex || _loadedPokedexId != null || filter.selectedPokedexId != null);
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
    if (filter.filtersLoadError != null && _allPokemons.isEmpty) {
      return qr.ErrorWidget(
        message: filter.filtersLoadError!,
        onRetry: () {
          final client = GraphQLProvider.of(context).value;
          filter.retryLoadFilters(client);
        },
      );
    }
    if (_error != null && _allPokemons.isEmpty) {
      return qr.ErrorWidget(message: _error!, onRetry: _loadAll);
    }
    if (pokemons.isEmpty) {
      return qr.EmptyWidget(
        message: tr(language, 'Aucun Pokémon trouvé', 'No Pokémon found'),
      );
    }

    // Capture filter
    final showCapture = settings.capturedFeature;
    final vgId = filter.selectedVersionGroup?.id;
    final capturedCount = showCapture
        ? pokemons.where((p) => userDatas.getUserPokemon(p.identifier)?.isCapturedIn(vgId) ?? false).length
        : 0;

    final displayedPokemons = showCapture && _captureFilter != 0
        ? pokemons.where((p) {
            final isCaptured = userDatas.getUserPokemon(p.identifier)?.isCapturedIn(vgId) ?? false;
            return _captureFilter == 1 ? isCaptured : !isCaptured;
          }).toList()
        : pokemons;

    return Column(
      children: [
        if (showCapture)
          GestureDetector(
            onTap: () => setState(() => _captureFilter = (_captureFilter + 1) % 3),
            child: CaptureProgressBar(
              captured: capturedCount,
              total: pokemons.length,
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
                          formName: pokemon.formName,
                        ),
                      ),
                    ),
                    onLongPress: () => showPokemonActionsSheet(context, pokemon),
                  );
                },
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'ranking',
                  onPressed: () => showRankingSheet(
                    context,
                    pokemons: displayedPokemons,
                    language: language,
                    filter: filter,
                  ),
                  child: const Icon(Icons.emoji_events_outlined),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
