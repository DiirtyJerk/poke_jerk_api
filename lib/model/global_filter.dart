import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/pokedex_filter_data.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/version_filter.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';

class GlobalFilterProvider extends ChangeNotifier {
  // Données de filtre (chargées une fois)
  List<TypePokemon> types = [];
  List<Generation> generations = [];
  List<VersionGroup> versionGroups = []; // top-level only (no DLCs)
  List<VersionGroup> _allVersionGroups = []; // includes DLCs
  bool filtersLoaded = false;

  // Recherche
  String searchQuery = '';

  // Sélection active
  List<int> selectedTypeIds = [];
  int? selectedGenerationId;
  VersionGroup? selectedVersionGroup;
  int? selectedPokedexId;

  VersionFilter? get versionFilter {
    if (selectedVersionGroup == null) return null;
    return VersionFilter(
      versionGroupId: selectedVersionGroup!.id,
      generationId: selectedVersionGroup!.generationId,
      versionIdentifiers: selectedVersionGroup!.versionIdentifiers,
      pokedexId: selectedPokedexId,
    );
  }

  Future<void> loadFilters(GraphQLClient client) async {
    if (filtersLoaded) return;

    final results = await Future.wait([
      client.query(QueryOptions(document: gql(getTypesQuery))),
      client.query(QueryOptions(document: gql(getGenerationsQuery))),
      client.query(QueryOptions(document: gql(getVersionGroupsQuery))),
    ]);

    final language = UserSettings().language;

    types = (results[0].data?['pokemon_v2_type'] as List? ?? [])
        .map((t) => TypePokemon.fromJson(t as Map<String, dynamic>))
        .toList();

    generations = (results[1].data?['pokemon_v2_generation'] as List? ?? [])
        .map((g) => Generation(
              id: g['id'] as int,
              name: _localizedName(g['pokemon_v2_generationnames'] as List, language),
            ))
        .toList();

    final pokedexData = results[2].data?['pokemon_v2_pokedex'] as List? ?? [];
    final vgMeta = <int, Map<String, dynamic>>{};
    final vgPokedexes = <int, List<PokedexEntry>>{};

    for (final p in pokedexData) {
      final dexName = _localizedName(p['pokemon_v2_pokedexnames'] as List, language);
      if (dexName.isEmpty) continue;
      final dex = PokedexEntry(id: p['id'] as int, name: dexName);

      for (final pvg in (p['pokemon_v2_pokedexversiongroups'] as List? ?? [])) {
        final vg = pvg['pokemon_v2_versiongroup'] as Map<String, dynamic>?;
        if (vg == null) continue;
        final vgId = vg['id'] as int;
        vgMeta.putIfAbsent(vgId, () => vg);
        vgPokedexes.putIfAbsent(vgId, () => []).add(dex);
      }
    }

    // Build all version groups (including DLCs)
    final allVgs = vgMeta.entries
        .map((entry) {
          final vgId = entry.key;
          final vg = entry.value;
          final namesFr = <String>[];
          final namesEn = <String>[];
          final versionIdentifiers = <String>[];
          final versionIds = <int>[];
          for (final v in (vg['pokemon_v2_versions'] as List? ?? [])) {
            final vId = v['name'] as String?;
            if (vId != null && vId.isNotEmpty) versionIdentifiers.add(vId);
            if (v['id'] != null) versionIds.add(v['id'] as int);
            for (final n in (v['pokemon_v2_versionnames'] as List? ?? [])) {
              if (n['language_id'] == 5) namesFr.add(n['name'] as String);
              if (n['language_id'] == 9) namesEn.add(n['name'] as String);
            }
          }
          if (namesEn.isEmpty) return null;
          return VersionGroup(
            id: vgId,
            generationId: vg['generation_id'] as int? ?? 0,
            identifier: vg['name'] as String? ?? '',
            versionIdentifiers: versionIdentifiers,
            versionIds: versionIds,
            nameFr: namesFr.join(' / '),
            nameEn: namesEn.join(' / '),
            pokedexes: vgPokedexes[vgId] ?? [],
            parentId: VersionGroup.dlcParentMap[vgId],
          );
        })
        .whereType<VersionGroup>()
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // Attach DLCs to their parent version groups
    final vgById = <int, VersionGroup>{for (final vg in allVgs) vg.id: vg};
    for (final vg in allVgs) {
      if (vg.parentId != null && vgById.containsKey(vg.parentId)) {
        vgById[vg.parentId]!.dlcChildren.add(vg);
      }
    }

    // Keep a flat list for lookup, but top-level list excludes DLCs
    _allVersionGroups = allVgs;
    versionGroups = allVgs.where((vg) => !vg.isDlc).toList();

    filtersLoaded = true;
    restoreFilters();
    notifyListeners();
  }

  void saveFilters() {
    final box = Hive.box<dynamic>('pokedex_filters');
    box.put('typeIds', selectedTypeIds);
    box.put('genId', selectedGenerationId);
    box.put('vgId', selectedVersionGroup?.id);
    box.put('dexId', selectedPokedexId);
  }

  void restoreFilters() {
    final box = Hive.box<dynamic>('pokedex_filters');
    final savedTypeIds = (box.get('typeIds') as List?)?.cast<int>() ?? [];
    final savedGenId = box.get('genId') as int?;
    final savedVgId = box.get('vgId') as int?;
    final savedDexId = box.get('dexId') as int?;

    VersionGroup? vg;
    if (savedVgId != null) {
      vg = _allVersionGroups.cast<VersionGroup?>().firstWhere(
        (v) => v?.id == savedVgId,
        orElse: () => null,
      );
    }

    selectedTypeIds = savedTypeIds;
    selectedGenerationId = savedGenId;
    selectedVersionGroup = vg;
    selectedPokedexId = savedDexId;
  }

  void setVersionGroup(VersionGroup? group, {int? pokedexId}) {
    selectedVersionGroup = group;
    selectedPokedexId = pokedexId;
    saveFilters();
    notifyListeners();
  }

  void setSearch(String query) {
    if (searchQuery == query) return;
    searchQuery = query;
    notifyListeners();
  }

  void clearVersionGroup() {
    selectedVersionGroup = null;
    selectedPokedexId = null;
    saveFilters();
    notifyListeners();
  }

  void setGenerationId(int? id) {
    selectedGenerationId = id;
    saveFilters();
    notifyListeners();
  }

  void toggleTypeId(int typeId) {
    if (selectedTypeIds.contains(typeId)) {
      selectedTypeIds.remove(typeId);
    } else if (selectedTypeIds.length < 2) {
      selectedTypeIds.add(typeId);
    }
    saveFilters();
    notifyListeners();
  }

  void clearTypes() {
    selectedTypeIds = [];
    saveFilters();
    notifyListeners();
  }

  Future<void> selectVersionGroupWithDialog(
    BuildContext context,
    VersionGroup group,
  ) async {
    // If no DLCs and single pokédex, select directly
    if (!group.hasDlc && group.pokedexes.length == 1) {
      setVersionGroup(group, pokedexId: group.pokedexes.first.id);
      return;
    }

    // If no DLCs but multiple pokédexes, show simple pokédex picker
    if (!group.hasDlc && group.pokedexes.length > 1) {
      final dex = await _showPokedexPicker(context, group, group.pokedexes);
      if (dex != null) {
        setVersionGroup(group, pokedexId: dex.id);
      }
      return;
    }

    // Has DLCs: show dialog with base game + DLC sections
    final language = UserSettings().language;
    final result = await showDialog<_DlcPickerResult>(
      context: context,
      builder: (ctx) => _DlcPickerDialog(
        parentGroup: group,
        language: language,
      ),
    );

    if (result != null) {
      setVersionGroup(result.versionGroup, pokedexId: result.pokedexId);
    }
  }

  Future<PokedexEntry?> _showPokedexPicker(
    BuildContext context,
    VersionGroup group,
    List<PokedexEntry> pokedexes,
  ) async {
    final color = ColorBuilder.getVersionGroupColor(group.identifier);
    return showDialog<PokedexEntry>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(group.getName(UserSettings().language)),
          ],
        ),
        children: pokedexes
            .map(
              (d) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, d),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(d.name),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _localizedName(List raw, String language) {
    final langId = language == 'fr' ? 5 : 9;
    for (final n in raw) {
      if (n['language_id'] == langId) return n['name'] as String;
    }
    for (final n in raw) {
      if (n['language_id'] == 9) return n['name'] as String;
    }
    return '';
  }
}

class _DlcPickerResult {
  final VersionGroup versionGroup;
  final int pokedexId;
  const _DlcPickerResult({required this.versionGroup, required this.pokedexId});
}

class _DlcPickerDialog extends StatelessWidget {
  final VersionGroup parentGroup;
  final String language;

  const _DlcPickerDialog({
    required this.parentGroup,
    required this.language,
  });

  Color _textColorOn(Color bg) => ColorBuilder.textColorOn(bg);

  @override
  Widget build(BuildContext context) {
    // Remove pokédexes that belong to DLC children from the parent list
    final dlcPokedexIds = <int>{};
    for (final dlc in parentGroup.dlcChildren) {
      for (final dex in dlc.pokedexes) {
        dlcPokedexIds.add(dex.id);
      }
    }
    final basePokedexes = parentGroup.pokedexes
        .where((dex) => !dlcPokedexIds.contains(dex.id))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              language == 'fr' ? 'Choisir une version' : 'Choose a version',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Base game card (with only base pokédexes)
            _buildVersionCard(
              context,
              versionGroup: parentGroup,
              label: parentGroup.getName(language),
              versionIdentifiers: parentGroup.versionIdentifiers,
              pokedexOverride: basePokedexes,
            ),

            // DLC cards
            for (final dlc in parentGroup.dlcChildren) ...[
              const SizedBox(height: 8),
              _buildDlcCard(context, dlc),
            ],

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required VersionGroup versionGroup,
    required String label,
    required List<String> versionIdentifiers,
    List<PokedexEntry>? pokedexOverride,
  }) {
    final pokedexes = pokedexOverride ?? versionGroup.pokedexes;
    final colors = versionIdentifiers
        .map((id) => ColorBuilder.getVersionColor(id))
        .toList();
    if (colors.isEmpty) colors.add(Colors.blueGrey);
    final mainColor = colors.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (pokedexes.length == 1) {
            Navigator.pop(
              context,
              _DlcPickerResult(
                versionGroup: versionGroup,
                pokedexId: pokedexes.first.id,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mainColor.withValues(alpha: 0.3)),
            color: mainColor.withValues(alpha: 0.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored header with version name
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: _buildColoredHeader(label, versionIdentifiers, colors),
              ),
              // Pokédex entries
              if (pokedexes.length > 1)
                for (final dex in pokedexes)
                  InkWell(
                    onTap: () => Navigator.pop(
                      context,
                      _DlcPickerResult(versionGroup: versionGroup, pokedexId: dex.id),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.map_outlined, size: 14, color: mainColor),
                          const SizedBox(width: 8),
                          Text(
                            dex.name,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDlcCard(BuildContext context, VersionGroup dlc) {
    final dlcColor = ColorBuilder.getVersionGroupColor(dlc.identifier);
    final textColor = _textColorOn(dlcColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (dlc.pokedexes.isNotEmpty) {
            Navigator.pop(
              context,
              _DlcPickerResult(versionGroup: dlc, pokedexId: dlc.pokedexes.first.id),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dlcColor.withValues(alpha: 0.3)),
            color: dlcColor.withValues(alpha: 0.06),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // DLC colored banner
                Container(
                  color: dlcColor,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.extension_outlined, size: 14, color: textColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dlc.getName(language),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (dlc.pokedexes.isNotEmpty)
                        Text(
                          dlc.pokedexes.first.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColoredHeader(
    String label,
    List<String> versionIdentifiers,
    List<Color> colors,
  ) {
    final parts = label.split('/').map((s) => s.trim()).toList();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            if (i > 0) Container(width: 1, color: Colors.white24),
            Expanded(
              child: Container(
                color: colors[i < colors.length ? i : colors.length - 1],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                alignment: Alignment.center,
                child: Text(
                  parts[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textColorOn(
                      colors[i < colors.length ? i : colors.length - 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
