import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
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

  const DetailPokemon({super.key, required this.pokemonId, this.versionFilter});

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
        return _DetailView(pokemon: pokemon, versionFilter: versionFilter);
      },
    );
  }
}

class _DetailView extends StatefulWidget {
  final Pokemon pokemon;
  final VersionFilter? versionFilter;

  const _DetailView({required this.pokemon, this.versionFilter});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _outerScrollController = ScrollController();
  final Set<int> _scrollableTabs = {0, 1, 2, 3, 4};
  late final _AdaptiveScrollPhysics _scrollPhysics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollPhysics = _AdaptiveScrollPhysics(
      shouldResist: () => !_scrollableTabs.contains(_tabController.index),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (!_scrollableTabs.contains(_tabController.index) &&
        _outerScrollController.hasClients &&
        _outerScrollController.offset > 0) {
      _outerScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateTabScrollable(int index, double innerMaxExtent) {
    // Account for header collapse: inner viewport grows by headerExtent
    // when header fully collapses. Content fits if innerMaxExtent <= headerExtent.
    final headerExtent = _outerScrollController.hasClients
        ? _outerScrollController.position.maxScrollExtent
        : 0.0;
    final needsScroll = innerMaxExtent > headerExtent;
    if (needsScroll) {
      _scrollableTabs.add(index);
    } else {
      _scrollableTabs.remove(index);
    }
  }

  Widget _wrapTab(int index, Widget child) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axisDirection == AxisDirection.down ||
            metrics.axisDirection == AxisDirection.up) {
          _updateTabScrollable(index, metrics.maxScrollExtent);
        }
        return false;
      },
      child: child,
    );
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
        controller: _outerScrollController,
        physics: _scrollPhysics,
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
                IconButton(
                  icon: Icon(
                    (userData?.captured ?? false)
                        ? Icons.catching_pokemon
                        : Icons.catching_pokemon_outlined,
                  ),
                  onPressed: () => userDatas.capturedPokemon(
                    pokemon.identifier,
                    !(userData?.captured ?? false),
                  ),
                ),
            ],
            title: Text(
              pokemon.getTranslation(language),
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
            _wrapTab(0, StatsTab(pokemon: pokemon, language: language, accentColor: bgColor)),
            _wrapTab(1, EvolutionChainWidget(
              evolutions: pokemon.species?.evolutions ?? [],
              moves: pokemon.moves,
              language: language,
              currentPokemonId: pokemon.id,
              externalMaxGeneration: widget.versionFilter?.generationId,
              externalPokedexId: widget.versionFilter?.pokedexId,
            )),
            _wrapTab(2, VariantsTab(pokemon: pokemon, language: language, accentColor: bgColor)),
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

// ──────────────────────────────────────────────────────────────────────────────
// Scroll physics that lets the user drag but springs back to expanded header
// ──────────────────────────────────────────────────────────────────────────────

class _AdaptiveScrollPhysics extends ScrollPhysics {
  final bool Function() shouldResist;

  _AdaptiveScrollPhysics({required this.shouldResist, super.parent});

  @override
  _AdaptiveScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _AdaptiveScrollPhysics(
      shouldResist: shouldResist,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final base = super.applyPhysicsToUserOffset(position, offset);
    return shouldResist() ? base * 0.15 : base;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (shouldResist() && position.pixels > position.minScrollExtent) {
      return ScrollSpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 0.3,
          stiffness: 200,
          ratio: 1.0,
        ),
        position.pixels,
        position.minScrollExtent,
        velocity,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
