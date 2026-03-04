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
  List<VersionGroup> versionGroups = [];
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

    versionGroups = vgMeta.entries
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
          );
        })
        .whereType<VersionGroup>()
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

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
      vg = versionGroups.cast<VersionGroup?>().firstWhere(
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
    if (group.pokedexes.length == 1) {
      setVersionGroup(group, pokedexId: group.pokedexes.first.id);
      return;
    }

    final color = ColorBuilder.getVersionGroupColor(group.identifier);
    final dex = await showDialog<PokedexEntry>(
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
        children: group.pokedexes
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

    if (dex != null) {
      setVersionGroup(group, pokedexId: dex.id);
    }
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
