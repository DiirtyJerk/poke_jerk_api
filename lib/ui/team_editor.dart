import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/stat.dart';
import 'package:poke_jerk_api/model/team_provider.dart';
import 'package:poke_jerk_api/model/type_chart.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/user_team.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:poke_jerk_api/ui/widgets/search_text_field.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:provider/provider.dart';

/// Lightweight pokemon data for team analysis.
class _TeamMember {
  final int id;
  final String identifier;
  final Map<int, String> names;
  final List<TypePokemon> types;
  final Map<Stat, int> stats;

  _TeamMember({
    required this.id,
    required this.identifier,
    required this.names,
    required this.types,
    required this.stats,
  });

  String getTranslation(String language) => localizedName(names, language, identifier);

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  factory _TeamMember.fromJson(Map<String, dynamic> json) {
    final types = <TypePokemon>[];
    for (final t in (json['pokemon_v2_pokemontypes'] as List? ?? [])) {
      if (t['pokemon_v2_type'] != null) {
        types.add(TypePokemon.fromJson(t['pokemon_v2_type'] as Map<String, dynamic>));
      }
    }
    final stats = <Stat, int>{};
    for (final s in (json['pokemon_v2_pokemonstats'] as List? ?? [])) {
      if (s['pokemon_v2_stat'] != null) {
        final stat = Stat.fromJson(s['pokemon_v2_stat'] as Map<String, dynamic>);
        stats[stat] = s['base_stat'] as int? ?? 0;
      }
    }
    final names = <int, String>{};
    final specy = json['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
    if (specy != null) {
      for (final n in (specy['pokemon_v2_pokemonspeciesnames'] as List? ?? [])) {
        names[n['language_id'] as int] = n['name'] as String;
      }
    }
    return _TeamMember(
      id: json['id'] as int,
      identifier: json['name'] as String,
      names: names,
      types: types,
      stats: stats,
    );
  }
}

class TeamEditorPage extends StatefulWidget {
  final UserTeam team;
  const TeamEditorPage({super.key, required this.team});

  @override
  State<TeamEditorPage> createState() => _TeamEditorPageState();
}

class _TeamEditorPageState extends State<TeamEditorPage> {
  List<_TeamMember> _members = [];
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final ids = widget.team.pokemonIds;
    if (ids.isEmpty) {
      setState(() => _members = []);
      return;
    }
    setState(() => _loading = true);
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(getTeamPokemonDataQuery),
      variables: {'ids': ids},
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    ));
    if (result.data != null) {
      final list = result.data!['pokemon_v2_pokemon'] as List? ?? [];
      final memberMap = <int, _TeamMember>{};
      for (final p in list) {
        final m = _TeamMember.fromJson(p as Map<String, dynamic>);
        memberMap[m.id] = m;
      }
      // Maintain order from team
      setState(() {
        _members = ids.map((id) => memberMap[id]).whereType<_TeamMember>().toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _addPokemon() {
    if (widget.team.pokemonIds.length >= 6) return;
    final language = context.read<UserSettings>().language;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PokemonPicker(
        language: language,
        onSelected: (pokemonId) {
          context.read<TeamProvider>().addPokemon(widget.team, pokemonId);
          _loadMembers();
        },
      ),
    );
  }

  void _removePokemon(int index) {
    context.read<TeamProvider>().removePokemon(widget.team, index);
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    context.watch<TeamProvider>(); // rebuild on changes

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _renameDialog(language),
          ),
        ],
      ),
      body: _loading && _members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ─── Slots grid ────────────────────
                _buildSlotsGrid(language),
                const SizedBox(height: 24),
                // ─── Type Coverage ──────────────────
                if (_members.isNotEmpty) ...[
                  _SectionTitle(
                    title: language == 'fr' ? 'Couverture de types' : 'Type coverage',
                  ),
                  const SizedBox(height: 8),
                  _TypeCoverageTable(members: _members, language: language),
                  const SizedBox(height: 24),
                  // ─── Team Radar ──────────────────
                  _SectionTitle(
                    title: language == 'fr' ? 'Profil de l\'équipe' : 'Team profile',
                  ),
                  const SizedBox(height: 8),
                  _TeamRadar(members: _members, language: language),
                  const SizedBox(height: 24),
                  // ─── Suggestions ──────────────────
                  _SectionTitle(
                    title: language == 'fr' ? 'Suggestions' : 'Suggestions',
                  ),
                  const SizedBox(height: 8),
                  _Suggestions(
                    members: _members,
                    language: language,
                    team: widget.team,
                    onPokemonAdded: () => _loadMembers(),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
    );
  }

  Widget _buildSlotsGrid(String language) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, i) {
        final hasMember = i < _members.length;
        if (hasMember) {
          final m = _members[i];
          return _SlotCard(
            member: m,
            language: language,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailPokemon(pokemonId: m.id)),
            ),
            onRemove: () => _removePokemon(i),
          );
        }
        final canAdd = widget.team.pokemonIds.length < 6;
        return _EmptySlot(onTap: canAdd ? _addPokemon : null);
      },
    );
  }

  void _renameDialog(String language) {
    final controller = TextEditingController(text: widget.team.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(language == 'fr' ? 'Renommer' : 'Rename'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(language == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<TeamProvider>().renameTeam(widget.team, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─── Slot Widgets ─────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final _TeamMember member;
  final String language;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SlotCard({
    required this.member,
    required this.language,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: member.spriteUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: Icon(Icons.catching_pokemon, color: Colors.grey),
                      ),
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.catching_pokemon, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.getTranslation(language),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: member.types
                        .map((t) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: TypeChip(type: t, language: language, fontSize: 8),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final VoidCallback? onTap;
  const _EmptySlot({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(
            Icons.add_circle_outline,
            size: 36,
            color: onTap != null ? Colors.grey.shade400 : Colors.grey.shade200,
          ),
        ),
      ),
    );
  }
}

// ─── Pokemon Picker ───────────────────────────────────────────────────────────

class _PokemonPicker extends StatefulWidget {
  final String language;
  final void Function(int pokemonId) onSelected;

  const _PokemonPicker({required this.language, required this.onSelected});

  @override
  State<_PokemonPicker> createState() => _PokemonPickerState();
}

class _PokemonPickerState extends State<_PokemonPicker> {
  List<Pokemon> _allPokemon = [];
  bool _loading = true;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allPokemon.isEmpty) _loadPokemon();
  }

  Future<void> _loadPokemon() async {
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(getPokemonsQuery),
      variables: {
        'limit': 2000,
        'offset': 0,
        'where': {'is_default': {'_eq': true}},
      },
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    ));
    if (result.data != null) {
      final list = result.data!['pokemon_v2_pokemon'] as List? ?? [];
      setState(() {
        _allPokemon = list
            .map((p) => Pokemon.fromListJson(p as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    }
  }

  List<Pokemon> get _filtered {
    if (_search.isEmpty) return _allPokemon;
    final q = normalize(_search);
    return _allPokemon.where((p) {
      return normalize(p.getTranslation(widget.language)).contains(q) ||
          normalize(p.identifier).contains(q) ||
          p.id.toString().contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchTextField(
              controller: _searchController,
              search: _search,
              language: widget.language,
              onChanged: (v) => setState(() => _search = v.trim()),
              onCleared: () {
                _searchController.clear();
                setState(() => _search = '');
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final p = _filtered[i];
                      return ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: p.officialArtworkUrl,
                          width: 40,
                          height: 40,
                          placeholder: (_, _) => const SizedBox(width: 40, height: 40),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.catching_pokemon, size: 28),
                        ),
                        title: Text(
                          p.getTranslation(widget.language),
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Row(
                          children: [
                            Text('#${p.id} ',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                            ...p.types.map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: TypeChip(
                                      type: t,
                                      language: widget.language,
                                      fontSize: 9),
                                )),
                          ],
                        ),
                        dense: true,
                        onTap: () {
                          widget.onSelected(p.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

// ─── Type Coverage Table ──────────────────────────────────────────────────────

class _TypeCoverageTable extends StatefulWidget {
  final List<_TeamMember> members;
  final String language;

  const _TypeCoverageTable({required this.members, required this.language});

  @override
  State<_TypeCoverageTable> createState() => _TypeCoverageTableState();
}

class _TypeCoverageTableState extends State<_TypeCoverageTable> {
  final _headerScrollCtrl = ScrollController();
  final _bodyScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _headerScrollCtrl.addListener(() {
      if (_bodyScrollCtrl.hasClients &&
          _bodyScrollCtrl.offset != _headerScrollCtrl.offset) {
        _bodyScrollCtrl.jumpTo(_headerScrollCtrl.offset);
      }
    });
    _bodyScrollCtrl.addListener(() {
      if (_headerScrollCtrl.hasClients &&
          _headerScrollCtrl.offset != _bodyScrollCtrl.offset) {
        _headerScrollCtrl.jumpTo(_bodyScrollCtrl.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollCtrl.dispose();
    _bodyScrollCtrl.dispose();
    super.dispose();
  }

  static const _cellW = 36.0;
  static const _cellH = 30.0;
  static const _labelW = 75.0;
  static const _headerH = 68.0;

  @override
  Widget build(BuildContext context) {
    final members = widget.members;
    final language = widget.language;
    final charts = members
        .map((m) => TypeChart.computeDefenseChart(
            m.types.map((t) => t.identifier).toList()))
        .toList();
    final types = TypeChart.allTypes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: fixed label + scrollable type headers
          SizedBox(
            height: _headerH,
            child: Row(
              children: [
                const SizedBox(width: _labelW),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: types.map((t) {
                        final color = ColorBuilder.getTypeColorByIdentifier(t);
                        final name = TypeChart.getTypeName(t, language);
                        return SizedBox(
                          width: _cellW,
                          height: _headerH,
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: RotatedBox(
                                      quarterTurns: -1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body: fixed labels column + scrollable cells
          Row(
            children: [
              // Fixed labels
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(members.length, (i) => SizedBox(
                    width: _labelW,
                    height: _cellH,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          members[i].getTranslation(language),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  )),
                  const Divider(height: 1),
                  SizedBox(
                    width: _labelW,
                    height: _cellH,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              // Scrollable cells
              Expanded(
                child: SingleChildScrollView(
                  controller: _bodyScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(members.length, (i) => Row(
                        children: types.map((t) {
                          final mult = charts[i][t] ?? 1.0;
                          return _buildCell(mult);
                        }).toList(),
                      )),
                      const Divider(height: 1),
                      Row(
                        children: types.map((t) => _buildSummaryCell(t, charts)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(double mult) {
    return Container(
      width: _cellW,
      height: _cellH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _multColor(mult),
        border: Border.all(color: Colors.grey.shade100, width: 0.5),
      ),
      child: mult != 1.0
          ? Text(
              _multLabel(mult),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _multTextColor(mult),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryCell(String t, List<Map<String, double>> charts) {
    int weakCount = 0;
    int resistCount = 0;
    for (final chart in charts) {
      final mult = chart[t] ?? 1.0;
      if (mult >= 2.0) weakCount++;
      if (mult < 1.0) resistCount++;
    }
    return Container(
      width: _cellW,
      height: _cellH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: weakCount > resistCount
            ? Colors.orange.shade600.withValues(alpha: 0.12)
            : resistCount > weakCount
                ? Colors.teal.shade400.withValues(alpha: 0.12)
                : null,
        border: Border.all(color: Colors.grey.shade100, width: 0.5),
      ),
      child: Text(
        weakCount > 0 ? '-$weakCount' : resistCount > 0 ? '+$resistCount' : '',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: weakCount > 0 ? Colors.orange.shade700 : Colors.teal.shade700,
        ),
      ),
    );
  }

  // Same color scheme as type_chart_page.dart
  Color? _multColor(double mult) {
    if (mult >= 4.0) return Colors.red.shade600.withValues(alpha: 0.15);
    if (mult >= 2.0) return Colors.orange.shade600.withValues(alpha: 0.15);
    if (mult == 0.0) return Colors.grey.shade600.withValues(alpha: 0.15);
    if (mult <= 0.25) return Colors.teal.shade300.withValues(alpha: 0.15);
    if (mult < 1.0) return Colors.teal.shade400.withValues(alpha: 0.15);
    return null;
  }

  Color _multTextColor(double mult) {
    if (mult >= 4.0) return Colors.red.shade600;
    if (mult >= 2.0) return Colors.orange.shade700;
    if (mult == 0.0) return Colors.grey.shade600;
    return Colors.teal.shade700;
  }

  String _multLabel(double mult) {
    if (mult == 0.0) return '×0';
    if (mult == 0.25) return '¼';
    if (mult == 0.5) return '½';
    if (mult == 2.0) return '×2';
    if (mult == 4.0) return '×4';
    return '×${mult.toStringAsFixed(mult.truncateToDouble() == mult ? 0 : 1)}';
  }
}


// ─── Team Radar ──────────────────────────────────────────────────────────────

class _TeamRadar extends StatefulWidget {
  final List<_TeamMember> members;
  final String language;

  const _TeamRadar({required this.members, required this.language});

  @override
  State<_TeamRadar> createState() => _TeamRadarState();
}

class _TeamRadarState extends State<_TeamRadar> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final members = widget.members;
    final language = widget.language;
    if (members.isEmpty) return const SizedBox.shrink();

    // Use identifiers as keys since Stat doesn't override ==
    final statEntries = members.first.stats.entries.toList();
    final statIds = statEntries.map((e) => e.key.identifier).toList();
    final statLabels = statEntries.map((e) => e.key).toList();

    // Per-member data with type color
    final memberData = members.map((m) {
      final color = m.types.isNotEmpty
          ? ColorBuilder.getTypeColor(m.types.first)
          : Colors.grey;
      // Map by identifier for reliable lookup
      final byId = <String, int>{};
      for (final e in m.stats.entries) {
        byId[e.key.identifier] = e.value;
      }
      final values = statIds.map((id) => (byId[id] ?? 0).toDouble()).toList();
      return _MemberRadarData(
        name: m.getTranslation(language),
        color: color,
        values: values,
      );
    }).toList();

    // Clamp selection if team changed
    if (_selectedIndex != null && _selectedIndex! >= memberData.length) {
      _selectedIndex = null;
    }

    // Averages + global max for scale
    double globalMax = 0;
    final avgValues = List.generate(statLabels.length, (i) {
      double sum = 0;
      for (final m in memberData) {
        sum += m.values[i];
        if (m.values[i] > globalMax) globalMax = m.values[i];
      }
      return sum / memberData.length;
    });
    final visualMax = ((globalMax / 50).ceil() * 50).toDouble().clamp(100.0, 300.0);

    // Identify weak stats
    final fr = language == 'fr';
    final warnings = <String>[];
    for (int i = 0; i < statLabels.length; i++) {
      final name = _shortStatName(statLabels[i].identifier, fr);
      if (avgValues[i] < 70) {
        warnings.add('$name ${fr ? 'faible' : 'low'} (${avgValues[i].round()})');
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: CustomPaint(
                painter: _TeamRadarPainter(
                  statLabels: statLabels,
                  memberData: memberData,
                  avgValues: avgValues,
                  visualMax: visualMax,
                  language: language,
                  selectedIndex: _selectedIndex,
                ),
              ),
            ),
          ),
          // Legend: tappable items
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: List.generate(memberData.length, (i) {
                final m = memberData[i];
                final selected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedIndex = selected ? null : i;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? m.color.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? m.color : Colors.grey.shade300,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: m.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          m.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? m.color : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_selectedIndex == null && warnings.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warnings.join(', '),
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  static String _shortStatName(String identifier, bool fr) {
    switch (identifier) {
      case 'hp': return 'PV';
      case 'attack': return fr ? 'ATQ' : 'ATK';
      case 'defense': return fr ? 'DÉF' : 'DEF';
      case 'special-attack': return fr ? 'A.Spé' : 'SpA';
      case 'special-defense': return fr ? 'D.Spé' : 'SpD';
      case 'speed': return fr ? 'VIT' : 'SPE';
      default: return identifier;
    }
  }
}

class _MemberRadarData {
  final String name;
  final Color color;
  final List<double> values;
  const _MemberRadarData({required this.name, required this.color, required this.values});
}

class _TeamRadarPainter extends CustomPainter {
  final List<Stat> statLabels;
  final List<_MemberRadarData> memberData;
  final List<double> avgValues;
  final double visualMax;
  final String language;
  final int? selectedIndex;

  _TeamRadarPainter({
    required this.statLabels,
    required this.memberData,
    required this.avgValues,
    required this.visualMax,
    required this.language,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 32;
    final n = statLabels.length;
    final angleStep = 2 * math.pi / n;
    const startAngle = -math.pi / 2;

    // Grid rings
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      _drawPolygon(canvas, center, r, n, startAngle, angleStep, gridPaint);
      final scaleVal = (visualMax * ring / 4).round();
      final scaleTp = TextPainter(
        text: TextSpan(
          text: '$scaleVal',
          style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scaleTp.paint(canvas, Offset(center.dx + 2, center.dy - r - scaleTp.height));
    }

    // Axes
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final pt = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.drawLine(center, pt, gridPaint);
    }

    final hasSelection = selectedIndex != null;

    if (hasSelection) {
      // Selected mode: show only the selected member's polygon
      final member = memberData[selectedIndex!];
      _drawMemberPolygon(canvas, center, radius, n, startAngle, angleStep, member, 0.3, 0.9, 2.5);

      // Dots + labels with individual values
      final dotPaint = Paint()..color = member.color..style = PaintingStyle.fill;
      for (int i = 0; i < n; i++) {
        final val = (member.values[i] / visualMax).clamp(0.0, 1.0);
        final angle = startAngle + angleStep * i;
        final pt = Offset(
          center.dx + radius * val * math.cos(angle),
          center.dy + radius * val * math.sin(angle),
        );
        canvas.drawCircle(pt, 3.5, dotPaint);
      }
      _drawLabels(canvas, center, radius, n, startAngle, angleStep, member.values, member.color);
    } else {
      // Overview: all member polygons + average line
      for (final member in memberData) {
        _drawMemberPolygon(canvas, center, radius, n, startAngle, angleStep, member, 0.2, 0.7, 1.5);
      }

      // Average polygon
      final avgPath = _buildPolygonPath(center, radius, n, startAngle, angleStep, avgValues);
      canvas.drawPath(avgPath, Paint()
        ..color = Colors.blueGrey.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);

      // Average dots
      final dotPaint = Paint()..color = Colors.blueGrey.shade700..style = PaintingStyle.fill;
      for (int i = 0; i < n; i++) {
        final val = (avgValues[i] / visualMax).clamp(0.0, 1.0);
        final angle = startAngle + angleStep * i;
        final pt = Offset(
          center.dx + radius * val * math.cos(angle),
          center.dy + radius * val * math.sin(angle),
        );
        canvas.drawCircle(pt, 3, dotPaint);
      }
      _drawLabels(canvas, center, radius, n, startAngle, angleStep, avgValues, Colors.blueGrey.shade700);
    }
  }

  void _drawMemberPolygon(Canvas canvas, Offset center, double radius, int n,
      double startAngle, double angleStep, _MemberRadarData member,
      double fillAlpha, double strokeAlpha, double strokeWidth) {
    final path = _buildPolygonPath(center, radius, n, startAngle, angleStep, member.values);
    canvas.drawPath(path, Paint()
      ..color = member.color.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = member.color.withValues(alpha: strokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth);
  }

  Path _buildPolygonPath(Offset center, double radius, int n,
      double startAngle, double angleStep, List<double> values) {
    final path = Path();
    for (int i = 0; i <= n; i++) {
      final idx = i % n;
      final val = (values[idx] / visualMax).clamp(0.0, 1.0);
      final angle = startAngle + angleStep * idx;
      final pt = Offset(
        center.dx + radius * val * math.cos(angle),
        center.dy + radius * val * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, int n,
      double startAngle, double angleStep, List<double> values, Color valueColor) {
    final fr = language == 'fr';
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = radius + 20;
      final labelPt = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );
      final name = _shortStatName(statLabels[i].identifier, fr);
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: name,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            TextSpan(
              text: '\n${values[i].round()}',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: valueColor),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(labelPt.dx - tp.width / 2, labelPt.dy - tp.height / 2));
    }
  }

  void _drawPolygon(Canvas canvas, Offset center, double r, int n,
      double startAngle, double angleStep, Paint paint) {
    final path = Path();
    for (int i = 0; i <= n; i++) {
      final angle = startAngle + angleStep * (i % n);
      final pt = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  static String _shortStatName(String identifier, bool fr) {
    switch (identifier) {
      case 'hp': return 'PV';
      case 'attack': return fr ? 'ATQ' : 'ATK';
      case 'defense': return fr ? 'DÉF' : 'DEF';
      case 'special-attack': return fr ? 'A.Spé' : 'SpA';
      case 'special-defense': return fr ? 'D.Spé' : 'SpD';
      case 'speed': return fr ? 'VIT' : 'SPE';
      default: return identifier;
    }
  }

  @override
  bool shouldRepaint(covariant _TeamRadarPainter oldDelegate) => true;
}

// ─── Suggestions ──────────────────────────────────────────────────────────────

class _Suggestions extends StatefulWidget {
  final List<_TeamMember> members;
  final String language;
  final UserTeam team;
  final VoidCallback onPokemonAdded;

  const _Suggestions({
    required this.members,
    required this.language,
    required this.team,
    required this.onPokemonAdded,
  });

  @override
  State<_Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends State<_Suggestions> {
  List<Pokemon> _candidatePool = [];
  bool _loading = false;
  int? _lastPokedexId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pokedexId = context.watch<GlobalFilterProvider>().selectedPokedexId;
    if (pokedexId != _lastPokedexId) {
      _lastPokedexId = pokedexId;
      _loadCandidates(pokedexId);
    }
  }

  Future<void> _loadCandidates(int? pokedexId) async {
    setState(() => _loading = true);
    final client = GraphQLProvider.of(context).value;

    if (pokedexId != null) {
      final result = await client.query(QueryOptions(
        document: gql(getPokemonsByPokedexQuery),
        variables: {'pokedexId': pokedexId},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ));
      if (result.data != null && mounted) {
        final entries = result.data!['pokemon_v2_pokemondexnumber'] as List? ?? [];
        _candidatePool = entries.expand((e) {
          final specy = e['pokemon_v2_pokemonspecy'] as Map<String, dynamic>?;
          if (specy == null) return <Pokemon>[];
          final pokemons = specy['pokemon_v2_pokemons'] as List? ?? [];
          return pokemons
              .where((p) => p['is_default'] == true)
              .map((p) {
                final merged = Map<String, dynamic>.from(p as Map<String, dynamic>);
                merged['pokemon_v2_pokemonspecy'] = specy;
                return Pokemon.fromListJson(merged);
              });
        }).toList();
      }
    } else {
      final result = await client.query(QueryOptions(
        document: gql(getPokemonsQuery),
        variables: {
          'limit': 2000,
          'offset': 0,
          'where': {'is_default': {'_eq': true}},
        },
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ));
      if (result.data != null && mounted) {
        final list = result.data!['pokemon_v2_pokemon'] as List? ?? [];
        _candidatePool = list
            .map((p) => Pokemon.fromListJson(p as Map<String, dynamic>))
            .toList();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Analyse team weaknesses and uncovered types.
  ({List<String> weakTypes, List<String> uncoveredTypes}) _analyzeTeam() {
    final charts = widget.members
        .map((m) => TypeChart.computeDefenseChart(
            m.types.map((t) => t.identifier).toList()))
        .toList();
    final teamTypeIds = widget.members
        .expand((m) => m.types.map((t) => t.identifier))
        .toSet();

    final weakTypes = <String>[];
    final uncoveredTypes = <String>[];

    for (final type in TypeChart.allTypes) {
      int weakCount = 0;
      for (final chart in charts) {
        if ((chart[type] ?? 1.0) >= 2.0) weakCount++;
      }
      if (weakCount > widget.members.length / 2) weakTypes.add(type);

      bool covered = false;
      for (final stab in teamTypeIds) {
        final mult = TypeChart.computeDefenseChart([type])[stab];
        if (mult != null && mult > 1.0) {
          covered = true;
          break;
        }
      }
      if (!covered) uncoveredTypes.add(type);
    }

    return (weakTypes: weakTypes, uncoveredTypes: uncoveredTypes);
  }

  /// Score candidates and return top 5.
  List<Pokemon> _getTopSuggestions(
      List<String> weakTypes, List<String> uncoveredTypes) {
    final currentIds = widget.team.pokemonIds.toSet();
    final candidates =
        _candidatePool.where((p) => !currentIds.contains(p.id)).toList();

    final scored = candidates.map((pokemon) {
      double score = 0;
      final typeIds = pokemon.types.map((t) => t.identifier).toList();
      final defChart = TypeChart.computeDefenseChart(typeIds);

      // Defensive: resist team weaknesses
      for (final weak in weakTypes) {
        final mult = defChart[weak] ?? 1.0;
        if (mult < 1.0) score += 2.0;
        if (mult == 0.0) score += 1.0;
      }

      // Offensive: STAB coverage for uncovered types
      for (final uncovered in uncoveredTypes) {
        final targetChart = TypeChart.computeDefenseChart([uncovered]);
        for (final stab in typeIds) {
          final mult = targetChart[stab] ?? 1.0;
          if (mult > 1.0) {
            score += 1.5;
            break;
          }
        }
      }

      return (pokemon: pokemon, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .where((s) => s.score > 0)
        .take(5)
        .map((s) => s.pokemon)
        .toList();
  }

  void _onSuggestionTap(Pokemon pokemon) {
    if (widget.team.pokemonIds.length < 6) {
      context.read<TeamProvider>().addPokemon(widget.team, pokemon.id);
      widget.onPokemonAdded();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPokemon(pokemonId: pokemon.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analyzeTeam();
    final weakTypes = analysis.weakTypes;
    final uncoveredTypes = analysis.uncoveredTypes;
    final language = widget.language;
    final globalFilter = context.watch<GlobalFilterProvider>();

    final suggestions = _candidatePool.isNotEmpty
        ? _getTopSuggestions(weakTypes, uncoveredTypes)
        : <Pokemon>[];

    final versionLabel = globalFilter.selectedVersionGroup != null
        ? globalFilter.selectedVersionGroup!.getName(language)
        : (language == 'fr' ? 'Global' : 'Global');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weakTypes.isEmpty && uncoveredTypes.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  language == 'fr'
                      ? 'Bonne couverture de types !'
                      : 'Good type coverage!',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        if (weakTypes.isNotEmpty)
          _SuggestionRow(
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            label: language == 'fr'
                ? 'Faiblesses communes :'
                : 'Common weaknesses:',
            types: weakTypes,
            language: language,
          ),
        if (uncoveredTypes.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SuggestionRow(
            icon: Icons.shield_outlined,
            color: Colors.orange,
            label: language == 'fr'
                ? 'Types non couverts (attaque) :'
                : 'Uncovered types (offense):',
            types: uncoveredTypes,
            language: language,
          ),
        ],
        // ─── Pokémon suggestions ─────────────
        if (_loading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ] else if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Text(
                language == 'fr'
                    ? 'Pokémon recommandés'
                    : 'Recommended Pokémon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  versionLabel,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _SuggestionCard(
                pokemon: suggestions[i],
                language: language,
                isFull: widget.team.pokemonIds.length >= 6,
                onTap: () => _onSuggestionTap(suggestions[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Pokemon pokemon;
  final String language;
  final bool isFull;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.pokemon,
    required this.language,
    required this.isFull,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 95,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: pokemon.officialArtworkUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const Center(
                          child: Icon(Icons.catching_pokemon, color: Colors.grey),
                        ),
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.catching_pokemon, color: Colors.grey),
                      ),
                      if (!isFull)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pokemon.getTranslation(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: pokemon.types
                      .map((t) => TypeChip(type: t, language: language, fontSize: 7))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final List<String> types;
  final String language;

  const _SuggestionRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.types,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 12, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: types.map((t) {
              final c = ColorBuilder.getTypeColorByIdentifier(t);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  TypeChart.getTypeName(t, language),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
