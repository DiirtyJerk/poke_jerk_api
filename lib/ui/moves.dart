import 'package:flutter/material.dart';
import 'package:poke_jerk_api/graphql/graphql_helper.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/move.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/detail_move.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/list_loading_skeleton.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:poke_jerk_api/ui/widgets/stat_badge.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:provider/provider.dart';

class MovesPage extends StatefulWidget {
  const MovesPage({super.key});

  @override
  State<MovesPage> createState() => _MovesPageState();
}

class _MovesPageState extends State<MovesPage> {
  final ScrollController _scrollController = ScrollController();

  List<Move> _allMoves = [];
  bool _isLoading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allMoves.isEmpty && !_isLoading) _loadAll();
  }

  Future<void> _loadAll() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final moves = await safeQuery<List<Move>>(
        context: context,
        query: getMovesQuery,
        tag: 'Moves',
        parser: (data) => (data['pokemon_v2_move'] as List)
            .map((m) => Move.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
      if (!mounted) return;
      setState(() { _allMoves = moves; _isLoading = false; });
    } catch (e) {
      debugPrint('[Moves] _loadAll error: $e');
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Move> _filteredMoves(GlobalFilterProvider filter, String language) {
    var list = _allMoves;

    if (filter.searchQuery.length >= 2) {
      final query = normalize(filter.searchQuery);
      list = list.where((m) => normalize(m.getTranslation(language)).contains(query)).toList();
    }

    if (filter.selectedGenerationId != null) {
      list = list.where((m) => m.generationId != null && m.generationId! <= filter.selectedGenerationId!).toList();
    }

    if (filter.selectedTypeIds.isNotEmpty) {
      list = list.where((m) => m.type != null && filter.selectedTypeIds.contains(m.type!.id)).toList();
    }

    list = List.of(list)
      ..sort((a, b) => normalize(a.getTranslation(language)).compareTo(normalize(b.getTranslation(language))));

    return list;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final filter = context.watch<GlobalFilterProvider>();
    final filtered = _filteredMoves(filter, language);

    if (_allMoves.isEmpty && _isLoading) return const MovesListSkeleton();
    if (_error != null && _allMoves.isEmpty) {
      return qr.ErrorWidget(message: _error!, onRetry: _loadAll);
    }
    if (filtered.isEmpty && !_isLoading) {
      return qr.EmptyWidget(message: tr(language, 'Aucune capacité trouvée', 'No moves found'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _MoveCard(move: filtered[index], language: language),
    );
  }
}

class _MoveCard extends StatelessWidget {
  final Move move;
  final String language;

  const _MoveCard({required this.move, required this.language});

  @override
  Widget build(BuildContext context) {
    final typeColor = move.type != null ? ColorBuilder.getTypeColor(move.type!) : Colors.grey;
    final damageIcon = switch (move.damageClass?.identifier) {
      'physical' => Icons.flash_on,
      'special'  => Icons.auto_awesome,
      _          => Icons.remove,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 0,
      color: typeColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: typeColor.withValues(alpha: 0.25), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailMove(moveId: move.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 36, child: Icon(damageIcon, size: 16, color: typeColor)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      move.getTranslation(language),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (move.type != null) TypeChip(type: move.type!, language: language, fontSize: 10),
                        const SizedBox(width: 6),
                        Icon(damageIcon, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          move.damageClass?.getTranslation(language) ?? '',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatBadge(label: tr(language, 'Puiss.', 'Power'), value: move.power > 0 ? '${move.power}' : '—'),
                  const SizedBox(width: 10),
                  StatBadge(label: 'PP', value: move.pp > 0 ? '${move.pp}' : '—'),
                  const SizedBox(width: 10),
                  StatBadge(label: tr(language, 'Préc.', 'Acc.'), value: move.accuracy > 0 ? '${move.accuracy}%' : '—'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
