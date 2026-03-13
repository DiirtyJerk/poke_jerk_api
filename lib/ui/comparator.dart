import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/comparator_provider.dart';
import 'package:poke_jerk_api/model/lightweight_pokemon.dart';
import 'package:poke_jerk_api/model/stat.dart';
import 'package:poke_jerk_api/model/type_chart.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/utils/sprite_utils.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:poke_jerk_api/ui/widgets/search_text_field.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:provider/provider.dart';

/// Colors for each comparison slot.
const List<Color> _slotColors = [
  Color(0xFFCC0000),
  Color(0xFF0F52BA),
  Color(0xFF228B22),
];

// ── Comparator Page ─────────────────────────────────────────────────────────

class ComparatorPage extends StatefulWidget {
  const ComparatorPage({super.key});

  @override
  State<ComparatorPage> createState() => _ComparatorPageState();
}

class _ComparatorPageState extends State<ComparatorPage> {
  final List<LightweightPokemon> _members = [];
  bool _loading = false;

  /// IDs we have already loaded data for — to avoid re-fetching.
  final Set<int> _loadedIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWithProvider();
  }

  /// Sync local _members list with the provider's pokemonIds.
  void _syncWithProvider() {
    final provider = context.read<ComparatorProvider>();
    final ids = provider.pokemonIds;

    // Remove members no longer in provider
    _members.removeWhere((m) => !ids.contains(m.id));
    _loadedIds.removeWhere((id) => !ids.contains(id));

    // Load any new IDs
    for (final id in ids) {
      if (!_loadedIds.contains(id)) {
        _loadPokemon(id);
      }
    }
  }

  Future<void> _loadPokemon(int pokemonId) async {
    if (_loadedIds.contains(pokemonId)) return;
    _loadedIds.add(pokemonId);

    setState(() => _loading = true);
    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.query(QueryOptions(
        document: gql(getTeamPokemonDataQuery),
        variables: {'ids': [pokemonId]},
        fetchPolicy: FetchPolicy.noCache,
      ));
      if (!mounted) return;
      if (result.data != null) {
        final list = result.data!['pokemon_v2_pokemon'] as List? ?? [];
        if (list.isNotEmpty) {
          final member = LightweightPokemon.fromJson(list.first as Map<String, dynamic>);
          // Only add if provider still has this ID
          final provider = context.read<ComparatorProvider>();
          if (provider.contains(pokemonId)) {
            setState(() => _members.add(member));
          }
        }
      }
    } catch (_) {
      _loadedIds.remove(pokemonId);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _removePokemon(int index) {
    if (index >= 0 && index < _members.length) {
      final id = _members[index].id;
      context.read<ComparatorProvider>().removePokemon(id);
      setState(() {
        _members.removeAt(index);
        _loadedIds.remove(id);
      });
    }
  }

  void _addFromPicker(int pokemonId) {
    final provider = context.read<ComparatorProvider>();
    if (provider.addPokemon(pokemonId)) {
      _loadPokemon(pokemonId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final provider = context.watch<ComparatorProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(language == 'fr' ? 'Comparateur' : 'Comparator'),
        actions: [
          if (_members.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: language == 'fr' ? 'Tout vider' : 'Clear all',
              onPressed: () {
                provider.clear();
                setState(() {
                  _members.clear();
                  _loadedIds.clear();
                });
              },
            ),
        ],
      ),
      body: _members.isEmpty && !_loading
          ? _EmptyState(language: language, onAdd: () => _showPicker(context, language))
          : _members.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(language),
      floatingActionButton: !provider.isFull
          ? FloatingActionButton(
              onPressed: () => _showPicker(context, language),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent(String language) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(members: _members, language: language, onRemove: _removePokemon),
          const SizedBox(height: 20),
          _SectionTitle(language == 'fr' ? 'Stats de base' : 'Base stats'),
          const SizedBox(height: 8),
          _RadarSection(members: _members, language: language),
          const SizedBox(height: 8),
          _StatBarsSection(members: _members, language: language),
          const SizedBox(height: 20),
          _SectionTitle(language == 'fr' ? 'Faiblesses de type' : 'Type weaknesses'),
          const SizedBox(height: 8),
          _WeaknessComparison(members: _members, language: language),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, String language) {
    final client = GraphQLProvider.of(context).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => _PokemonPicker(
          scrollController: scroll,
          language: language,
          excludeIds: _members.map((m) => m.id).toSet(),
          client: client,
          onSelect: (id) {
            Navigator.pop(ctx);
            _addFromPicker(id);
          },
        ),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String language;
  final VoidCallback onAdd;

  const _EmptyState({required this.language, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            language == 'fr'
                ? 'Ajoute jusqu\'à ${ComparatorProvider.maxCompare} Pokémon\npour les comparer'
                : 'Add up to ${ComparatorProvider.maxCompare} Pokémon\nto compare them',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(language == 'fr' ? 'Ajouter un Pokémon' : 'Add a Pokémon'),
          ),
        ],
      ),
    );
  }
}

// ── Section title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

// ── Header row ──────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final List<LightweightPokemon> members;
  final String language;
  final void Function(int) onRemove;

  const _HeaderRow({required this.members, required this.language, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(members.length, (i) {
        final m = members[i];
        return Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Center(
                        child: CachedNetworkImage(
                          imageUrl: m.spriteUrl,
                          height: 80,
                          width: 80,
                          placeholder: (context, url) => const SizedBox(
                            height: 80, width: 80,
                            child: Center(child: Icon(Icons.catching_pokemon, size: 32, color: Colors.grey)),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.catching_pokemon, size: 32, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        top: 0, right: 0,
                        child: InkWell(
                          onTap: () => onRemove(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.getTranslation(language),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _slotColors[i],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: m.types.map((t) => TypeChip(type: t, language: language, fontSize: 10)).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Radar section ───────────────────────────────────────────────────────────

class _RadarSection extends StatelessWidget {
  final List<LightweightPokemon> members;
  final String language;

  const _RadarSection({required this.members, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: CustomPaint(
          painter: _ComparisonRadarPainter(
            members: members,
            colors: _slotColors,
            language: language,
          ),
        ),
      ),
    );
  }
}

// ── Stat bars section ───────────────────────────────────────────────────────

class _StatBarsSection extends StatelessWidget {
  final List<LightweightPokemon> members;
  final String language;

  const _StatBarsSection({required this.members, required this.language});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final statKeys = members.first.stats.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          for (final stat in statKeys) ...[
            _StatBarRow(stat: stat, members: members, language: language),
            if (stat != statKeys.last) const SizedBox(height: 6),
          ],
          const Divider(height: 16),
          _TotalRow(members: members, language: language),
        ],
      ),
    );
  }
}

class _StatBarRow extends StatelessWidget {
  final Stat stat;
  final List<LightweightPokemon> members;
  final String language;

  const _StatBarRow({required this.stat, required this.members, required this.language});

  @override
  Widget build(BuildContext context) {
    final maxVal = 255.0;
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            _shortStatName(stat.identifier, language),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: Column(
            children: List.generate(members.length, (i) {
              final val = members[i].stats[stat] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: val / maxVal,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(_slotColors[i]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$val',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _slotColors[i]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final List<LightweightPokemon> members;
  final String language;

  const _TotalRow({required this.members, required this.language});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            'Total',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(members.length, (i) {
              return Expanded(
                child: Text(
                  '${members[i].totalStats}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _slotColors[i],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Weakness comparison ─────────────────────────────────────────────────────

class _WeaknessComparison extends StatelessWidget {
  final List<LightweightPokemon> members;
  final String language;

  const _WeaknessComparison({required this.members, required this.language});

  @override
  Widget build(BuildContext context) {
    // Compute defense chart for each member
    final charts = members.map((m) {
      return TypeChart.computeDefenseChart(m.types.map((t) => t.identifier).toList());
    }).toList();

    // Get all type identifiers
    final allTypes = charts.isNotEmpty ? charts.first.keys.toList() : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                const SizedBox(width: 80),
                ...List.generate(members.length, (i) => Expanded(
                  child: Text(
                    members[i].getTranslation(language),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _slotColors[i]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            ),
          ),
          const Divider(height: 1),
          // Type rows — only show types where at least one member has non-1x multiplier
          for (final type in allTypes)
            if (charts.any((c) => c[type] != 1.0))
              _WeaknessTypeRow(
                typeId: type,
                multipliers: charts.map((c) => c[type] ?? 1.0).toList(),
                language: language,
              ),
        ],
      ),
    );
  }
}

class _WeaknessTypeRow extends StatelessWidget {
  final String typeId;
  final List<double> multipliers;
  final String language;

  const _WeaknessTypeRow({
    required this.typeId,
    required this.multipliers,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ColorBuilder.getTypeColorByIdentifier(typeId),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                TypeChart.getTypeName(typeId, language),
                style: TextStyle(
                  color: ColorBuilder.textColorOn(ColorBuilder.getTypeColorByIdentifier(typeId)),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ...List.generate(multipliers.length, (i) => Expanded(
            child: _MultiplierCell(multiplier: multipliers[i]),
          )),
        ],
      ),
    );
  }
}

class _MultiplierCell extends StatelessWidget {
  final double multiplier;

  const _MultiplierCell({required this.multiplier});

  @override
  Widget build(BuildContext context) {
    if (multiplier == 1.0) return const SizedBox.shrink();

    final String label;
    final Color color;
    if (multiplier == 0.0) {
      label = '×0'; color = Colors.grey.shade600;
    } else if (multiplier == 0.25) {
      label = '¼'; color = Colors.teal.shade400;
    } else if (multiplier == 0.5) {
      label = '½'; color = Colors.teal.shade300;
    } else if (multiplier == 2.0) {
      label = '×2'; color = Colors.orange.shade600;
    } else {
      label = '×4'; color = Colors.red.shade600;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Pokemon Picker ──────────────────────────────────────────────────────────

class _PokemonPicker extends StatefulWidget {
  final ScrollController scrollController;
  final String language;
  final Set<int> excludeIds;
  final void Function(int pokemonId) onSelect;
  final GraphQLClient client;

  const _PokemonPicker({
    required this.scrollController,
    required this.language,
    required this.excludeIds,
    required this.onSelect,
    required this.client,
  });

  @override
  State<_PokemonPicker> createState() => _PokemonPickerState();
}

class _PokemonPickerState extends State<_PokemonPicker> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPokemon = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadPokemon();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon() async {
    try {
      final result = await widget.client.query(QueryOptions(
        document: gql(getPokemonsQuery),
        variables: const {
          'limit': 2000,
          'offset': 0,
          'where': {'is_default': {'_eq': true}},
        },
        fetchPolicy: FetchPolicy.noCache,
      ));
      if (!mounted) return;
      if (result.data != null) {
        setState(() {
          _allPokemon = (result.data!['pokemon_v2_pokemon'] as List)
              .cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final query = normalize(_searchController.text);
    var list = _allPokemon.where((p) => !widget.excludeIds.contains(p['id']));
    if (query.isNotEmpty) {
      list = list.where((p) {
        final speciesNames = p['pokemon_v2_pokemonspecy']?['pokemon_v2_pokemonspeciesnames'] as List? ?? [];
        return speciesNames.any((n) => normalize(n['name'] as String).contains(query));
      });
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SearchTextField(
            controller: _searchController,
            search: _searchController.text,
            language: widget.language,
            onChanged: (val) => setState(() {}),
            onCleared: () {
              _searchController.clear();
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final id = p['id'] as int;
                    final speciesNames = (p['pokemon_v2_pokemonspecy']?['pokemon_v2_pokemonspeciesnames'] as List? ?? []);
                    final langId = widget.language == 'fr' ? 5 : 9;
                    final name = speciesNames.firstWhere(
                      (n) => n['language_id'] == langId,
                      orElse: () => speciesNames.isNotEmpty ? speciesNames.first : {'name': p['name']},
                    )['name'] as String;
                    final spriteUrl = pokemonSpriteUrl(id);

                    return InkWell(
                      onTap: () => widget.onSelect(id),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              imageUrl: spriteUrl,
                              width: 36, height: 36,
                              placeholder: (context, url) => const Icon(Icons.catching_pokemon, size: 24, color: Colors.grey),
                              errorWidget: (context, url, error) => const Icon(Icons.catching_pokemon, size: 24, color: Colors.grey),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('#$id', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Multi-pokemon radar painter ─────────────────────────────────────────────

class _ComparisonRadarPainter extends CustomPainter {
  final List<LightweightPokemon> members;
  final List<Color> colors;
  final String language;

  _ComparisonRadarPainter({
    required this.members,
    required this.colors,
    required this.language,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (members.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 32;
    final statKeys = members.first.stats.keys.toList();
    final n = statKeys.length;
    if (n == 0) return;

    final angleStep = 2 * math.pi / n;
    const startAngle = -math.pi / 2;

    // Compute visual max across all members
    int globalMax = 100;
    for (final m in members) {
      for (final v in m.stats.values) {
        if (v > globalMax) globalMax = v;
      }
    }
    final visualMax = ((globalMax / 25).ceil() * 25).toDouble().clamp(100.0, 255.0);

    // Grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final angle = startAngle + angleStep * (i % n);
        final pt = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, gridPaint);

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

    // Data polygons
    for (int mi = 0; mi < members.length; mi++) {
      final m = members[mi];
      final color = colors[mi % colors.length];
      final dataPath = Path();

      for (int i = 0; i <= n; i++) {
        final idx = i % n;
        final val = ((m.stats[statKeys[idx]] ?? 0) / visualMax).clamp(0.0, 1.0);
        final angle = startAngle + angleStep * idx;
        final pt = Offset(center.dx + radius * val * math.cos(angle), center.dy + radius * val * math.sin(angle));
        i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
      }

      canvas.drawPath(dataPath, Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill);
      canvas.drawPath(dataPath, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0);

      // Dots
      for (int i = 0; i < n; i++) {
        final val = ((m.stats[statKeys[i]] ?? 0) / visualMax).clamp(0.0, 1.0);
        final angle = startAngle + angleStep * i;
        final pt = Offset(center.dx + radius * val * math.cos(angle), center.dy + radius * val * math.sin(angle));
        canvas.drawCircle(pt, 3, Paint()..color = color);
      }
    }

    // Labels
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = radius + 20;
      final labelPt = Offset(center.dx + labelRadius * math.cos(angle), center.dy + labelRadius * math.sin(angle));

      final name = _shortStatName(statKeys[i].identifier, language);
      final tp = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(labelPt.dx - tp.width / 2, labelPt.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ComparisonRadarPainter old) =>
      members != old.members || colors != old.colors;
}

String _shortStatName(String identifier, String language) {
  final fr = language == 'fr';
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
