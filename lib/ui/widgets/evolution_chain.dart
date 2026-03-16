import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/evolution.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/move.dart';
import 'package:poke_jerk_api/model/pokedex_filter_data.dart';
import 'package:poke_jerk_api/ui/detail_pokemon.dart';
import 'package:poke_jerk_api/ui/widgets/colored_badge.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:poke_jerk_api/ui/widgets/version_selector_button.dart';
import 'package:provider/provider.dart';

// ─── Tree data structure ─────────────────────────────────────────────────────

class _EvoNode {
  final SpeciesRef species;
  final EvolutionDetail? trigger;
  final List<_EvoNode> children;

  _EvoNode({required this.species, this.trigger, List<_EvoNode>? children})
      : children = children ?? [];

  int get depth {
    if (children.isEmpty) return 1;
    return 1 + children.map((c) => c.depth).reduce((a, b) => a > b ? a : b);
  }

  int get maxBranches {
    if (children.isEmpty) return 1;
    final childMax = children.map((c) => c.maxBranches).reduce((a, b) => a > b ? a : b);
    return children.length > childMax ? children.length : childMax;
  }
}

const _regionalFormNames = {'alola', 'galar', 'hisui', 'paldea'};

/// Filter evolution entries to keep only the forms matching the selected
/// version group's regional form. If [expectedForm] is set (e.g. "alola"),
/// keep only regional entries matching it and remove the default form branch.
/// If [expectedForm] is null, keep only default form branches and remove
/// regional variants.
List<EvolutionDetail> _filterByRegionalForm(List<EvolutionDetail> evolutions, String? expectedForm) {
  final byTarget = <int, List<EvolutionDetail>>{};
  for (final e in evolutions) {
    if (e.toSpecies != null) {
      byTarget.putIfAbsent(e.evolvedSpeciesId, () => []).add(e);
    }
  }

  final idsToRemove = <int>{};
  for (final entries in byTarget.values) {
    if (entries.length <= 1) continue;

    final assignments = _assignFormsToEntries(entries);
    if (assignments.isEmpty) continue;

    // Check if the target species actually has the expected regional form
    final targetSpecies = entries.first.toSpecies;
    final hasExpectedForm = expectedForm != null &&
        targetSpecies != null &&
        targetSpecies.forms.any((f) => f.formName == expectedForm);

    for (final entry in entries) {
      final assignedForm = assignments[entry.id]; // null = default form
      if (expectedForm != null && hasExpectedForm) {
        // We want a regional form AND it exists: keep only that form
        if (assignedForm != expectedForm) {
          idsToRemove.add(entry.id);
        }
      } else {
        // Default form wanted, OR expected regional form doesn't exist for this species:
        // keep default, remove other regional forms
        if (assignedForm != null) {
          idsToRemove.add(entry.id);
        }
      }
    }
  }

  if (idsToRemove.isEmpty) return evolutions;
  return evolutions.where((e) => !idsToRemove.contains(e.id)).toList();
}

/// Finds the form name of a pokemon by its ID in the evolution data.
String _findFormName(List<EvolutionDetail> evolutions, int pokemonId) {
  for (final e in evolutions) {
    for (final sp in [e.fromSpecies, e.toSpecies]) {
      if (sp == null) continue;
      for (final f in sp.forms) {
        if (f.pokemonId == pokemonId) return f.formName;
      }
    }
  }
  return '';
}

/// For a list of evolution entries targeting the same species, assign a
/// regional form name to each entry when the target species has regional
/// variants. Returns a map from EvolutionDetail.id to form name.
Map<int, String> _assignFormsToEntries(List<EvolutionDetail> entries) {
  if (entries.length <= 1) return {};
  final target = entries.first.toSpecies;
  if (target == null) return {};

  final regionalForms = target.forms
      .where((f) => !f.isDefault && _regionalFormNames.contains(f.formName))
      .toList();
  if (regionalForms.isEmpty) return {};

  // First entry = default form (no override), subsequent = regional forms
  final result = <int, String>{};
  for (int i = 1; i < entries.length && i - 1 < regionalForms.length; i++) {
    result[entries[i].id] = regionalForms[i - 1].formName;
  }
  return result;
}

_EvoNode? _buildTree(List<EvolutionDetail> evolutions, {String formName = ''}) {
  if (evolutions.isEmpty) return null;

  final toIds = <int>{};
  for (final e in evolutions) {
    final sp = e.toSpecies;
    if (sp != null) toIds.add(sp.withForm(formName).pokemonId);
  }

  SpeciesRef? rootSpecies;
  for (final e in evolutions) {
    if (e.fromSpecies != null) {
      final from = e.fromSpecies!.withForm(formName);
      if (!toIds.contains(from.pokemonId)) {
        rootSpecies = from;
        break;
      }
    }
  }
  if (rootSpecies == null) {
    rootSpecies = evolutions.first.fromSpecies?.withForm(formName);
    if (rootSpecies == null) return null;
  }

  // Pre-compute form assignments for duplicate evolution paths (same target)
  final sameTargetAssignments = <int, String>{};
  final byTargetSpecies = <int, List<EvolutionDetail>>{};
  for (final e in evolutions) {
    if (e.toSpecies != null) {
      byTargetSpecies.putIfAbsent(e.evolvedSpeciesId, () => []).add(e);
    }
  }
  for (final entries in byTargetSpecies.values) {
    sameTargetAssignments.addAll(_assignFormsToEntries(entries));
  }

  // Build full entry → form map including unique-target entries
  // Group entries by source species to match unassigned entries to remaining forms
  final fullFormMap = <int, String>{};
  final byFrom = <int, List<EvolutionDetail>>{};
  for (final e in evolutions) {
    final fromId = e.fromSpecies?.pokemonId ?? 0;
    byFrom.putIfAbsent(fromId, () => []).add(e);
  }

  for (final children in byFrom.values) {
    if (children.length <= 1) continue;

    final assignedForms = <String>{};

    // 1. Copy same-target assignments and mark default entries
    for (final child in children) {
      if (sameTargetAssignments.containsKey(child.id)) {
        fullFormMap[child.id] = sameTargetAssignments[child.id]!;
        assignedForms.add(sameTargetAssignments[child.id]!);
      } else {
        // Check if this is the default entry for a same-target group
        final sameTarget = children.where((c) => c.evolvedSpeciesId == child.evolvedSpeciesId).toList();
        if (sameTarget.length > 1 && sameTarget.any((c) => sameTargetAssignments.containsKey(c.id))) {
          fullFormMap[child.id] = ''; // default form
          assignedForms.add('');
        }
      }
    }

    // 2. Get source species' regional form names
    final sourceSpecies = children.first.fromSpecies;
    if (sourceSpecies == null) continue;
    final allSourceForms = sourceSpecies.forms
        .where((f) => _regionalFormNames.contains(f.formName))
        .map((f) => f.formName)
        .toList();

    // 3. Match unassigned entries to remaining regional forms
    final unassigned = children.where((c) => !fullFormMap.containsKey(c.id)).toList();
    final remainingForms = allSourceForms.where((f) => !assignedForms.contains(f)).toList();

    for (int i = 0; i < unassigned.length && i < remainingForms.length; i++) {
      fullFormMap[unassigned[i].id] = remainingForms[i];
    }
  }

  _EvoNode buildNode(SpeciesRef species, EvolutionDetail? trigger) {
    final node = _EvoNode(species: species, trigger: trigger);
    final defaultId = species.forms.where((f) => f.isDefault).map((f) => f.pokemonId).firstOrNull ?? species.pokemonId;
    final children = byFrom[defaultId] ?? [];
    final seen = <String>{};
    for (final child in children) {
      if (child.toSpecies == null || !seen.add(child.dedupeKey)) continue;

      // When a specific form is requested, only keep matching entries
      if (formName.isNotEmpty) {
        final entryForm = fullFormMap[child.id];
        if (entryForm != null && entryForm != formName) continue;
      }
      // When default form is requested, skip entries assigned to a regional form
      if (formName.isEmpty) {
        final entryForm = fullFormMap[child.id];
        if (entryForm != null && entryForm.isNotEmpty) continue;
      }

      final assignedForm = formName.isNotEmpty
          ? formName
          : (sameTargetAssignments[child.id] ?? '');
      node.children.add(buildNode(child.toSpecies!.withForm(assignedForm), child));
    }
    return node;
  }

  return buildNode(rootSpecies, null);
}

// ─── Constants ───────────────────────────────────────────────────────────────

const _lineColor = Color(0xFFBDBDBD);
const _lineWidth = 1.5;

// ─── Main widget ─────────────────────────────────────────────────────────────

class EvolutionChainWidget extends StatelessWidget {
  final List<EvolutionDetail> evolutions;
  final List<PokemonMove> moves;
  final String language;
  final int currentPokemonId;
  final int? externalMaxGeneration;
  final int? externalPokedexId;
  final int? externalVersionGroupId;
  final String? externalFormName;

  const EvolutionChainWidget({
    super.key,
    required this.evolutions,
    required this.moves,
    required this.language,
    required this.currentPokemonId,
    this.externalMaxGeneration,
    this.externalPokedexId,
    this.externalVersionGroupId,
    this.externalFormName,
  });

  @override
  Widget build(BuildContext context) {
    final hasExternalFilter = externalMaxGeneration != null || externalPokedexId != null;

    final vgMap = <int, PokemonMove>{};
    for (final m in moves) {
      vgMap.putIfAbsent(m.versionGroupId, () => m);
    }
    final versionGroups = vgMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final globalFilter = context.watch<GlobalFilterProvider>();
    final selectedVersionGroupId = !hasExternalFilter
        ? globalFilter.activeVersionGroupId
        : null;

    int? maxGeneration = externalMaxGeneration;
    int? pokedexId = externalPokedexId;
    if (!hasExternalFilter && selectedVersionGroupId != null) {
      maxGeneration = globalFilter.activeGenerationId;
    }

    final filteredEvolutions = (maxGeneration == null && pokedexId == null)
        ? evolutions
        : evolutions
            .where((e) {
              bool speciesOk(SpeciesRef? sp) {
                if (sp == null) return true;
                if (pokedexId != null && sp.pokedexIds.isNotEmpty) {
                  return sp.pokedexIds.contains(pokedexId);
                }
                if (maxGeneration != null) {
                  return sp.generationId <= maxGeneration;
                }
                return true;
              }
              return speciesOk(e.fromSpecies) && speciesOk(e.toSpecies);
            })
            .toList();

    // Filter regional forms based on the active version group's regional form
    String? expectedRegionalForm;
    if (!hasExternalFilter && selectedVersionGroupId != null) {
      final activeVg = globalFilter.versionGroupById(selectedVersionGroupId);
      expectedRegionalForm = activeVg?.regionalForm;
      // Also check transient VG via the static map
      expectedRegionalForm ??= VersionGroup.regionalFormMap[selectedVersionGroupId];
    }
    // Also filter when using external filter (detail page with versionFilter)
    if (hasExternalFilter && externalVersionGroupId != null) {
      expectedRegionalForm = globalFilter.versionGroupById(externalVersionGroupId!)?.regionalForm
          ?? VersionGroup.regionalFormMap[externalVersionGroupId!];
    }
    // Or use formName passed from pokédex (regional form without version selected)
    if (expectedRegionalForm == null && externalFormName != null && externalFormName!.isNotEmpty) {
      expectedRegionalForm = externalFormName;
    }
    final shouldFilterForms = selectedVersionGroupId != null
        || externalVersionGroupId != null
        || (externalFormName != null && externalFormName!.isNotEmpty);
    final regionFilteredEvolutions = shouldFilterForms
        ? _filterByRegionalForm(filteredEvolutions, expectedRegionalForm)
        : filteredEvolutions;

    final currentFormName = _findFormName(evolutions, currentPokemonId);
    // When a regional form is active, pass unfiltered evolutions to _buildTree
    // so buildNode can properly filter using all formAssignments.
    // _filterByRegionalForm is only used for default forms (removing regional branches).
    final treeEvolutions = currentFormName.isNotEmpty ? filteredEvolutions : regionFilteredEvolutions;
    final tree = _buildTree(treeEvolutions, formName: currentFormName);

    return Column(
      children: [
        if (!hasExternalFilter && versionGroups.isNotEmpty)
          VersionSelectorButton(
            versionGroups: versionGroups,
            selectedId: selectedVersionGroupId,
            language: language,
            onSelected: (id) {
              final filter = context.read<GlobalFilterProvider>();
              if (id == -1) {
                filter.clearVersionGroup();
              } else {
                final vg = filter.versionGroupById(id);
                if (vg != null) {
                  filter.setVersionGroup(vg, pokedexId: vg.pokedexes.firstOrNull?.id);
                } else {
                  filter.setTransientVersionGroup(id, vgMap[id]?.generationId ?? 0);
                }
              }
            },
          ),
        Expanded(
          child: tree == null
              ? Center(
                  child: Text(
                    language == 'fr'
                        ? 'Pas d\'évolution'
                        : 'No evolution',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Adapt card size to available space
                    final cardSize = _computeCardSize(
                      constraints,
                      tree,
                    );
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        child: _NodeWidget(
                                node: tree,
                                language: language,
                                cardSize: cardSize,
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

/// Compute card size based on available space and tree complexity.
double _computeCardSize(BoxConstraints constraints, _EvoNode tree) {
  final availW = constraints.maxWidth - 32; // padding
  final availH = constraints.maxHeight - 32;

  final branches = tree.maxBranches;
  final depth = tree.depth;
  // Vertical: each branch needs card + gap
  final maxByHeight = (availH - (branches - 1) * 6) / branches * 0.85;
  // Horizontal: each depth level needs card + trigger + lines
  final maxByWidth = (availW - (depth - 1) * 80) / depth;
  return maxByWidth.clamp(70.0, maxByHeight.clamp(70.0, 120.0));
}


// ─── Branched tree (widget-based lines) ──────────────────────────────────────

class _NodeWidget extends StatelessWidget {
  final _EvoNode node;
  final String language;
  final double cardSize;

  const _NodeWidget({
    required this.node,
    required this.language,
    required this.cardSize,
  });

  @override
  Widget build(BuildContext context) {
    if (node.children.isEmpty) {
      return _SpeciesCard(
          species: node.species, language: language, size: cardSize);
    }

    // Single child: parent and child aligned at top,
    // trigger + lines aligned at sprite center height.
    if (node.children.length == 1) {
      final child = node.children.first;
      // Exact sprite center: Card margin (~4) + padding (size*0.06) + half sprite (size*0.35)
      final spriteCenterY = 4 + cardSize * 0.41;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpeciesCard(
              species: node.species, language: language, size: cardSize),
          // Use a SizedBox + Stack to place the line exactly at spriteCenterY
          // and center the trigger around it
          _TriggerConnector(
            evo: child.trigger,
            language: language,
            topOffset: spriteCenterY,
          ),
          _NodeWidget(
              node: child, language: language, cardSize: cardSize),
        ],
      );
    }

    // Multiple children: parent aligned with first child card.
    // All connections (HLines, VLine junction, trigger) aligned at sprite center.
    final branches = node.children;
    final junctionY = 4 + cardSize * 0.41; // sprite center from top of card
    final triggerTopY = (junctionY - 10).clamp(0.0, double.infinity);

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < branches.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // First row: parent card, others: spacer
                  if (i == 0) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _SpeciesCard(
                            species: node.species,
                            language: language,
                            size: cardSize),
                      ],
                    ),
                  ] else
                    SizedBox(width: cardSize),
                  // HLine at junction Y
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: junctionY),
                      const _HLine(width: 8),
                    ],
                  ),
                  // VLine with junction at junctionY
                  _VLineSegmentOffset(
                    isFirst: i == 0,
                    isLast: i == branches.length - 1,
                    junctionY: junctionY,
                  ),
                  // HLine at junction Y
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: junctionY),
                      const _HLine(width: 6),
                    ],
                  ),
                  // Trigger centered at junction Y
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: triggerTopY),
                        _TriggerBadges(
                            evo: branches[i].trigger, language: language),
                      ],
                    ),
                  ),
                  // HLine at junction Y
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: junctionY),
                      const _HLine(width: 6),
                    ],
                  ),
                  // Child card at top
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _NodeWidget(
                            node: branches[i],
                            language: language,
                            cardSize: cardSize),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Vertical line segment with junction at a fixed Y offset.
class _VLineSegmentOffset extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final double junctionY;

  const _VLineSegmentOffset({
    required this.isFirst,
    required this.isLast,
    required this.junctionY,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _lineWidth,
      child: Column(
        children: [
          // Top section: from 0 to junctionY
          SizedBox(
            height: junctionY,
            child: isFirst
                ? const SizedBox.shrink()
                : Container(width: _lineWidth, color: _lineColor),
          ),
          // Junction dot
          Container(
            width: _lineWidth,
            height: _lineWidth,
            color: _lineColor,
          ),
          // Bottom section: fills remaining space
          Expanded(
            child: isLast
                ? const SizedBox.shrink()
                : Container(width: _lineWidth, color: _lineColor),
          ),
        ],
      ),
    );
  }
}

/// Simple horizontal line.
class _HLine extends StatelessWidget {
  final double width;

  const _HLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: _lineWidth, color: _lineColor);
  }
}

// ─── Trigger connector (for single-child layout) ────────────────────────────

/// Places HLines at the exact sprite center Y and centers the trigger around it.
class _TriggerConnector extends StatelessWidget {
  final EvolutionDetail? evo;
  final String language;
  final double topOffset; // Y of the sprite center

  const _TriggerConnector({
    required this.evo,
    required this.language,
    required this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Spacer to push content down to sprite center, minus half of content
        // Content ≈ trigger badges + line ≈ 20px, so offset - 10
        SizedBox(height: (topOffset - 10).clamp(0.0, double.infinity)),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _HLine(width: 8),
            _TriggerBadges(evo: evo, language: language),
            const _HLine(width: 6),
          ],
        ),
      ],
    );
  }
}

// ─── Trigger badges ──────────────────────────────────────────────────────────

class _TriggerBadges extends StatelessWidget {
  final EvolutionDetail? evo;
  final String language;

  const _TriggerBadges({required this.evo, required this.language});

  @override
  Widget build(BuildContext context) {
    if (evo == null) return const SizedBox.shrink();

    final badges = _buildBadges();
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: badges,
    );
  }

  List<Widget> _buildBadges() {
    final badges = <Widget>[];
    if (evo == null) return badges;
    final e = evo!;
    final trigger = e.trigger?.identifier ?? '';

    switch (trigger) {
      case 'level-up':
        if (e.minLevel > 0) {
          badges.add(ColoredBadge(
            label:
                language == 'fr' ? 'Niv. ${e.minLevel}' : 'Lv. ${e.minLevel}',
            color: Colors.blue,
          ));
        } else {
          badges.add(ColoredBadge(
            label: language == 'fr' ? 'Montée niv.' : 'Level up',
            color: Colors.blue,
          ));
        }
      case 'trade':
        badges.add(ColoredBadge(
          label: language == 'fr' ? 'Échange' : 'Trade',
          color: Colors.indigo,
        ));
      case 'use-item':
        break;
      default:
        if (trigger.isNotEmpty && e.trigger != null) {
          badges.add(ColoredBadge(
            label: e.trigger!.getTranslation(language),
            color: Colors.grey,
          ));
        }
    }

    if (e.item != null) {
      badges.add(ColoredBadge(
        label: e.item!.getTranslation(language),
        color: Colors.orange,
        icon: Icons.auto_awesome,
      ));
    }
    if (e.minHappiness > 0) {
      badges.add(ColoredBadge(
        label: language == 'fr' ? 'Bonheur' : 'Happiness',
        color: Colors.pink,
        icon: Icons.favorite,
      ));
    }
    if (e.minBeauty > 0) {
      badges.add(ColoredBadge(
        label: language == 'fr' ? 'Beauté' : 'Beauty',
        color: Colors.purple,
      ));
    }
    if (e.minAffection > 0) {
      badges.add(ColoredBadge(
        label: language == 'fr' ? 'Affection' : 'Affection',
        color: Colors.pinkAccent,
      ));
    }
    if (e.genderId == 1) {
      badges.add(ColoredBadge(
        label: language == 'fr' ? 'Femelle' : 'Female',
        color: Colors.pink,
        icon: Icons.female,
      ));
    } else if (e.genderId == 2) {
      badges.add(ColoredBadge(
        label: language == 'fr' ? 'Mâle' : 'Male',
        color: Colors.blue,
        icon: Icons.male,
      ));
    }
    switch (e.timeOfDay) {
      case 'day':
        badges.add(ColoredBadge(
          label: language == 'fr' ? 'Jour' : 'Day',
          color: Colors.amber,
          icon: Icons.wb_sunny,
        ));
      case 'night':
        badges.add(ColoredBadge(
          label: language == 'fr' ? 'Nuit' : 'Night',
          color: Colors.indigo,
          icon: Icons.nightlight_round,
        ));
      case 'dusk':
        badges.add(ColoredBadge(
          label: language == 'fr' ? 'Crépuscule' : 'Dusk',
          color: Colors.deepOrange,
          icon: Icons.wb_twilight,
        ));
    }
    if (e.heldItem != null) {
      badges.add(ColoredBadge(
        label: e.heldItem!.getTranslation(language),
        color: Colors.brown,
        icon: Icons.inventory_2,
      ));
    }
    if (e.location != null) {
      badges.add(ColoredBadge(
        label: e.location!.getTranslation(language),
        color: Colors.green,
        icon: Icons.place,
      ));
    }
    if (e.knownMove != null) {
      badges.add(ColoredBadge(
        label: e.knownMove!.getTranslation(language),
        color: Colors.deepPurple,
        icon: Icons.flash_on,
      ));
    }
    if (e.knownMoveType != null) {
      final label = language == 'fr'
          ? 'Cap. ${e.knownMoveType!.getTranslation(language)}'
          : '${e.knownMoveType!.getTranslation(language)} move';
      badges.add(ColoredBadge(
        label: label,
        color: Colors.deepPurple,
        icon: Icons.flash_on,
      ));
    }
    if (e.partySpecies != null) {
      final label = language == 'fr'
          ? 'Avec ${e.partySpecies!.getTranslation(language)}'
          : 'With ${e.partySpecies!.getTranslation(language)}';
      badges.add(ColoredBadge(
        label: label,
        color: Colors.cyan,
        icon: Icons.group,
      ));
    }
    if (e.tradeSpecies != null) {
      final label = language == 'fr'
          ? 'Contre ${e.tradeSpecies!.getTranslation(language)}'
          : 'For ${e.tradeSpecies!.getTranslation(language)}';
      badges.add(ColoredBadge(
        label: label,
        color: Colors.indigo,
        icon: Icons.swap_horiz,
      ));
    }
    if (e.partyType != null) {
      final label = language == 'fr'
          ? 'Type ${e.partyType!.getTranslation(language)} en équipe'
          : '${e.partyType!.getTranslation(language)} type in party';
      badges.add(ColoredBadge(
        label: label,
        color: Colors.teal,
        icon: Icons.group,
      ));
    }
    if (e.relativePhysicalStats != null) {
      final label = switch (e.relativePhysicalStats!) {
        1 => language == 'fr' ? 'Atq > Déf' : 'Atk > Def',
        -1 => language == 'fr' ? 'Atq < Déf' : 'Atk < Def',
        0 => language == 'fr' ? 'Atq = Déf' : 'Atk = Def',
        _ => '',
      };
      if (label.isNotEmpty) {
        badges.add(ColoredBadge(label: label, color: Colors.red));
      }
    }
    if (e.needsOverworldRain) {
      badges.add(ColoredBadge(
        label: language == 'fr' ? 'Pluie' : 'Rain',
        color: Colors.lightBlue,
        icon: Icons.water_drop,
      ));
    }
    if (e.turnUpsideDown) {
      badges.add(ColoredBadge(
        label: language == 'fr' ? 'Retourner' : 'Upside down',
        color: Colors.teal,
        icon: Icons.screen_rotation,
      ));
    }

    return badges;
  }
}

// ─── Species Card ────────────────────────────────────────────────────────────

class _SpeciesCard extends StatelessWidget {
  final SpeciesRef species;
  final String language;
  final double size;

  const _SpeciesCard({
    required this.species,
    required this.language,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final spriteSize = (size * 0.7).roundToDouble();
    final fontSize = (size * 0.13).clamp(9.0, 13.0);
    final subFontSize = (size * 0.11).clamp(8.0, 11.0);

    return GestureDetector(
      onTap: species.pokemonId > 0
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetailPokemon(pokemonId: species.pokemonId),
                ),
              )
          : null,
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size * 0.18)),
              child: Padding(
                padding: EdgeInsets.all(size * 0.06),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${species.pokemonId}.png',
                  height: spriteSize,
                  width: spriteSize,
                  placeholder: (_, _) => SizedBox(
                    height: spriteSize,
                    width: spriteSize,
                    child: Center(
                      child: Icon(Icons.catching_pokemon,
                          color: Colors.grey.shade300, size: spriteSize * 0.5),
                    ),
                  ),
                  errorWidget: (_, _, _) => Icon(Icons.catching_pokemon,
                      size: spriteSize * 0.6),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              species.getTranslation(language),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.w600),
            ),
            Text(
              '#${species.pokemonId.toString().padLeft(3, '0')}',
              style: TextStyle(
                  fontSize: subFontSize, color: Colors.grey.shade500),
            ),
            if (species.types.isNotEmpty) ...[
              const SizedBox(height: 3),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 3,
                runSpacing: 2,
                children: species.types
                    .map((t) => TypeChip(type: t, language: language, fontSize: subFontSize))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
