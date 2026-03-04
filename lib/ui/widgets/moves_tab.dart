import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/move.dart';
import 'package:poke_jerk_api/model/version_filter.dart';
import 'package:poke_jerk_api/ui/detail_move.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/stat_badge.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/ui/widgets/version_selector_button.dart';

// Ordre d'affichage des méthodes d'apprentissage
const _methodOrder = ['level-up', 'machine', 'egg', 'tutor'];

int _methodPriority(String identifier) {
  final i = _methodOrder.indexOf(identifier);
  return i < 0 ? _methodOrder.length : i;
}

class MovesTab extends StatefulWidget {
  final List<PokemonMove> moves;
  final String language;
  final VersionFilter? versionFilter;

  const MovesTab({
    super.key,
    required this.moves,
    required this.language,
    this.versionFilter,
  });

  @override
  State<MovesTab> createState() => _MovesTabState();
}

class _MovesTabState extends State<MovesTab> {
  int? _selectedVersionGroupId;

  @override
  void initState() {
    super.initState();
    if (widget.versionFilter != null) {
      _selectedVersionGroupId = widget.versionFilter!.versionGroupId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final externalFilter = widget.versionFilter != null;

    // Dédupliquer les groupes de version disponibles, triés par ID
    final vgMap = <int, PokemonMove>{};
    for (final m in widget.moves) {
      vgMap.putIfAbsent(m.versionGroupId, () => m);
    }
    final versionGroups = vgMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final filtered = _selectedVersionGroupId == null
        ? widget.moves
        : widget.moves.where((m) => m.versionGroupId == _selectedVersionGroupId).toList();

    // Group by learn method identifier, then sort each group by level
    final grouped = <String, List<PokemonMove>>{};
    for (final m in filtered) {
      grouped.putIfAbsent(m.learnMethod.identifier, () => []).add(m);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        if (a.level != b.level) return a.level.compareTo(b.level);
        return a.move.getTranslation(widget.language)
            .compareTo(b.move.getTranslation(widget.language));
      });
    }

    // Ordonner les sections par méthode
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => _methodPriority(a.key).compareTo(_methodPriority(b.key)));

    return Column(
      children: [
        if (!externalFilter)
          VersionSelectorButton(
            versionGroups: versionGroups,
            selectedId: _selectedVersionGroupId,
            language: widget.language,
            onSelected: (id) => setState(() => _selectedVersionGroupId = id == -1 ? null : id),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    widget.language == 'fr' ? 'Aucune capacité' : 'No moves',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: sortedEntries.map((entry) {
                    final methodLabel =
                        entry.value.first.learnMethod.getTranslation(widget.language);
                    return _MethodSection(
                      methodLabel: methodLabel,
                      moves: entry.value,
                      language: widget.language,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _MethodSection extends StatelessWidget {
  final String methodLabel;
  final List<PokemonMove> moves;
  final String language;

  const _MethodSection({
    required this.methodLabel,
    required this.moves,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              color: accent,
            ),
            Text(
              methodLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text(
              '(${moves.length})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        children: moves.map((pm) => _MoveCard(move: pm, language: language)).toList(),
      ),
    );
  }
}

class _MoveCard extends StatelessWidget {
  final PokemonMove move;
  final String language;

  const _MoveCard({required this.move, required this.language});

  @override
  Widget build(BuildContext context) {
    final typeColor = move.move.type != null
        ? ColorBuilder.getTypeColor(move.move.type!)
        : Colors.grey;

    final damageIcon = switch (move.move.damageClass?.identifier) {
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
          MaterialPageRoute(builder: (_) => DetailMove(moveId: move.move.id)),
        ),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (move.level > 0)
              SizedBox(
                width: 36,
                child: Text(
                  '${move.level}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              )
            else
              SizedBox(
                width: 36,
                child: Icon(damageIcon, size: 16, color: typeColor),
              ),

            const SizedBox(width: 4),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    move.move.getTranslation(language),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (move.move.type != null)
                        TypeChip(type: move.move.type!, language: language, fontSize: 10),
                      const SizedBox(width: 6),
                      Icon(damageIcon, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        move.move.damageClass?.getTranslation(language) ?? '',
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
                StatBadge(
                  label: language == 'fr' ? 'Puiss.' : 'Power',
                  value: move.move.power > 0 ? '${move.move.power}' : '—',
                ),
                const SizedBox(width: 10),
                StatBadge(
                  label: 'PP',
                  value: move.move.pp > 0 ? '${move.move.pp}' : '—',
                ),
                const SizedBox(width: 10),
                StatBadge(
                  label: language == 'fr' ? 'Préc.' : 'Acc.',
                  value: move.move.accuracy > 0 ? '${move.move.accuracy}%' : '—',
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
