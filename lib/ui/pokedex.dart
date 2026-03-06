import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/team_provider.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/widgets/pokemon_card.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
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
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
      );

      if (!mounted) return;
      if (result.hasException) {
        setState(() => _isLoading = false);
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
        _loadedPokedexId = pokedexId;
        _loadedWithoutPokedex = false;
      });
      return;
    }

    final result = await client.query(
      QueryOptions(
        document: gql(getPokemonsQuery),
        variables: {'limit': 2000, 'offset': 0, 'where': basicWhere},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
    );

    if (!mounted) return;
    if (result.hasException) {
      setState(() => _isLoading = false);
      return;
    }

    final data = result.data?['pokemon_v2_pokemon'] as List? ?? [];
    setState(() {
      _allPokemons = data
          .map((p) => Pokemon.fromListJson(p as Map<String, dynamic>))
          .toList();
      _isLoading = false;
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

    if (_allPokemons.isEmpty) {
      return const qr.LoadingWidget();
    }

    if (pokemons.isEmpty) {
      return qr.EmptyWidget(
        message: language == 'fr' ? 'Aucun Pokémon trouvé' : 'No Pokémon found',
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: pokemons.length,
      itemBuilder: (context, index) {
        final pokemon = pokemons[index];
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
          onLongPress: () => _showAddToTeam(context, pokemon),
        );
      },
    );
  }

  void _showAddToTeam(BuildContext context, Pokemon pokemon) {
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

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final availableTeams = teams.where((t) => t.pokemonIds.length < 6).toList();
        if (availableTeams.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              language == 'fr'
                  ? 'Toutes les équipes sont complètes'
                  : 'All teams are full',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }
        return SafeArea(
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
        );
      },
    );
  }
}
