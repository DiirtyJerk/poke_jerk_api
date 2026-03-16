import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/version_filter.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/users_datas.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/detail_loading_skeleton.dart';
import 'package:poke_jerk_api/ui/widgets/encounters_tab.dart';
import 'package:poke_jerk_api/ui/widgets/evolution_chain.dart';
import 'package:poke_jerk_api/ui/widgets/moves_tab.dart';
import 'package:poke_jerk_api/ui/widgets/pokemon_header.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:poke_jerk_api/ui/widgets/stats_tab.dart';
import 'package:poke_jerk_api/ui/widgets/variants_tab.dart';
import 'package:provider/provider.dart';

class DetailPokemon extends StatelessWidget {
  final int pokemonId;
  final VersionFilter? versionFilter;
  final String? formName;

  const DetailPokemon({super.key, required this.pokemonId, this.versionFilter, this.formName});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(getPokemonDetailQuery),
        variables: {'id': pokemonId},
        fetchPolicy: FetchPolicy.noCache,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return DetailLoadingSkeleton(pokemonId: pokemonId);
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(),
            body: qr.ErrorWidget(
              message: result.exception.toString(),
              onRetry: refetch,
            ),
          );
        }

        final data = result.data?['pokemon_v2_pokemon_by_pk'] as Map<String, dynamic>?;
        if (data == null) {
          return Scaffold(appBar: AppBar(), body: const qr.EmptyWidget());
        }

        final pokemon = Pokemon.fromDetailJson(data);
        final effectiveFilter = versionFilter ??
            context.read<GlobalFilterProvider>().versionFilter;
        return _DetailView(pokemon: pokemon, versionFilter: effectiveFilter, formName: formName);
      },
    );
  }
}

class _DetailView extends StatefulWidget {
  final Pokemon pokemon;
  final VersionFilter? versionFilter;
  final String? formName;

  const _DetailView({required this.pokemon, this.versionFilter, this.formName});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _displayName(Pokemon pokemon, String language) {
    // If opened from a regional form, find the matching variant name
    final formName = widget.formName;
    if (formName != null && formName.isNotEmpty) {
      final variant = pokemon.variants
          .cast<PokemonVariant?>()
          .firstWhere((v) => v?.formName == formName, orElse: () => null);
      if (variant != null) {
        final name = variant.getTranslation(language);
        if (name.isNotEmpty) return name;
      }
    }
    return pokemon.getTranslation(language);
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final userDatas = context.watch<UserDatas>();
    final pokemon = widget.pokemon;
    final userData = userDatas.getUserPokemon(pokemon.identifier);

    final primaryType = pokemon.types.isNotEmpty ? pokemon.types.first : null;
    final bgColor = primaryType != null
        ? ColorBuilder.getTypeColor(primaryType)
        : Colors.blueGrey;
    final bgColorDark = Color.lerp(bgColor, Colors.black, 0.25)!;

    return Scaffold(
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: bgColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  (userData?.favorited ?? false) ? Icons.star : Icons.star_border,
                ),
                onPressed: () => userDatas.favoritedPokemon(
                  pokemon.identifier,
                  !(userData?.favorited ?? false),
                ),
              ),
              if (UserSettings().capturedFeature)
                Builder(builder: (context) {
                  final vgId = context.watch<GlobalFilterProvider>().selectedVersionGroup?.id;
                  final isCaptured = userData?.isCapturedIn(vgId) ?? false;
                  return IconButton(
                    icon: Icon(
                      isCaptured
                          ? Icons.catching_pokemon
                          : Icons.catching_pokemon_outlined,
                      color: isCaptured
                          ? const Color(0xFFE53935)
                          : Colors.white70,
                      size: 28,
                    ),
                    onPressed: () => userDatas.capturedPokemon(
                      pokemon.identifier,
                      !isCaptured,
                      versionGroupId: vgId,
                    ),
                  );
                }),
            ],
            title: Text(
              _displayName(pokemon, language),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: PokemonHeader(
                pokemon: pokemon,
                language: language,
                bgColor: bgColor,
                bgColorDark: bgColorDark,
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: bgColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: bgColor,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: language == 'fr' ? 'Stats' : 'Stats'),
                  Tab(text: language == 'fr' ? 'Évolutions' : 'Evolutions'),
                  Tab(text: language == 'fr' ? 'Variantes' : 'Variants'),
                  Tab(text: language == 'fr' ? 'Capacités' : 'Moves'),
                  Tab(text: language == 'fr' ? 'Localisations' : 'Locations'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            StatsTab(pokemon: pokemon, language: language, accentColor: bgColor),
            EvolutionChainWidget(
              evolutions: pokemon.species?.evolutions ?? [],
              moves: pokemon.moves,
              language: language,
              currentPokemonId: pokemon.id,
              externalMaxGeneration: widget.versionFilter?.generationId,
              externalPokedexId: widget.versionFilter?.pokedexId,
              externalVersionGroupId: widget.versionFilter?.versionGroupId,
              externalFormName: widget.formName,
            ),
            VariantsTab(pokemon: pokemon, language: language, accentColor: bgColor),
            MovesTab(
              moves: pokemon.moves,
              language: language,
              versionFilter: widget.versionFilter,
            ),
            EncountersTab(
              encounters: pokemon.encounters,
              language: language,
              versionFilter: widget.versionFilter,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TabBar delegate
// ──────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 2 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

