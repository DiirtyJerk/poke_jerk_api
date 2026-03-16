import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/version_filter.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/utils/sprite_utils.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';

void showRankingSheet(
  BuildContext context, {
  required List<Pokemon> pokemons,
  required String language,
  required GlobalFilterProvider filter,
}) {
  const statKeys = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
  // Multiple stat selection: empty = total
  final selectedStats = <String>{};
  // Up to 2 type filters
  final selectedTypeIds = <int>{};

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        // Filter by types (up to 2, AND logic)
        var filtered = List<Pokemon>.from(pokemons);
        if (selectedTypeIds.isNotEmpty) {
          filtered = filtered.where((p) =>
            selectedTypeIds.every((typeId) => p.types.any((t) => t.id == typeId)),
          ).toList();
        }

        // Sort by selected stats sum (or total if none)
        int statSum(Pokemon p) {
          if (selectedStats.isEmpty) return p.totalStats;
          return selectedStats.fold(0, (sum, key) =>
            sum + (p.stats.entries.where((e) => e.key.identifier == key).firstOrNull?.value ?? 0));
        }

        filtered.sort((a, b) => statSum(b).compareTo(statSum(a)));
        final top = filtered.take(20).toList();

        // Label for the stat column
        String statColumnLabel() {
          if (selectedStats.isEmpty) return 'Total';
          return selectedStats.map((k) => _statLabel(k, language)).join(' + ');
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
                  tr(language, 'Classement', 'Ranking'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              // Stat chips (multi-select, tap to toggle)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _RankingChip(
                      label: 'Total',
                      selected: selectedStats.isEmpty,
                      onTap: () => setSheetState(() => selectedStats.clear()),
                    ),
                    ...statKeys.map((key) => _RankingChip(
                      label: _statLabel(key, language),
                      selected: selectedStats.contains(key),
                      onTap: () => setSheetState(() {
                        if (selectedStats.contains(key)) {
                          selectedStats.remove(key);
                        } else {
                          selectedStats.add(key);
                        }
                      }),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Type filter chips (up to 2)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _TypeFilterChip(
                      label: tr(language, 'Tous', 'All'),
                      color: Colors.grey,
                      selected: selectedTypeIds.isEmpty,
                      onTap: () => setSheetState(() => selectedTypeIds.clear()),
                    ),
                    ...filter.types.map((type) {
                      final isSelected = selectedTypeIds.contains(type.id);
                      final isFull = selectedTypeIds.length >= 2 && !isSelected;
                      return _TypeFilterChip(
                        label: type.getTranslation(language),
                        color: ColorBuilder.getTypeColor(type),
                        selected: isSelected,
                        disabled: isFull,
                        onTap: isFull ? null : () => setSheetState(() {
                          if (isSelected) {
                            selectedTypeIds.remove(type.id);
                          } else {
                            selectedTypeIds.add(type.id);
                          }
                        }),
                      );
                    }),
                  ],
                ),
              ),
              // Show stat label
              if (selectedStats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    statColumnLabel(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(
                child: top.isEmpty
                    ? Center(
                        child: Text(
                          tr(language, 'Aucun Pokémon', 'No Pokémon'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: top.length,
                        itemBuilder: (ctx, index) => _RankingTile(
                          pokemon: top[index],
                          rank: index,
                          statValue: statSum(top[index]),
                          maxValue: top.isNotEmpty ? statSum(top.first) : 1,
                          language: language,
                          versionFilter: filter.versionFilter,
                          parentContext: context,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

String _statLabel(String key, String language) {
  final fr = language == 'fr';
  return switch (key) {
    'hp' => 'PV',
    'attack' => fr ? 'ATQ' : 'ATK',
    'defense' => fr ? 'DÉF' : 'DEF',
    'special-attack' => fr ? 'A.Spé' : 'SpA',
    'special-defense' => fr ? 'D.Spé' : 'SpD',
    'speed' => fr ? 'VIT' : 'SPE',
    _ => key,
  };
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
        label: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        )),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _TypeFilterChip({
    required this.label,
    required this.color,
    required this.selected,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: disabled ? 0.3 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? color : color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final Pokemon pokemon;
  final int rank;
  final int statValue;
  final int maxValue;
  final String language;
  final VersionFilter? versionFilter;
  final BuildContext parentContext;

  const _RankingTile({
    required this.pokemon,
    required this.rank,
    required this.statValue,
    required this.maxValue,
    required this.language,
    required this.versionFilter,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final name = pokemon.getTranslation(language);
    final imgUrl = pokemon.spriteUrl ?? pokemonArtworkUrl(pokemon.id);
    final rankColor = rank == 0
        ? const Color(0xFFFFD700)
        : rank == 1
            ? const Color(0xFFC0C0C0)
            : rank == 2
                ? const Color(0xFFCD7F32)
                : Colors.grey;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          parentContext,
          MaterialPageRoute(
            builder: (_) => DetailPokemon(pokemonId: pokemon.id, versionFilter: versionFilter),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${rank + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rank < 3 ? 18 : 14,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Image.network(
              imgUrl,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: pokemon.types
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
                      value: maxValue > 0 ? statValue / maxValue : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: pokemon.types.isNotEmpty
                          ? ColorBuilder.getTypeColor(pokemon.types.first)
                          : Theme.of(context).colorScheme.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('$statValue', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
