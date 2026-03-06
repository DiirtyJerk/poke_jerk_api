import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokedex_filter_data.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/data_page.dart';
import 'package:poke_jerk_api/ui/locations.dart';
import 'package:poke_jerk_api/ui/pokedex.dart';
import 'package:poke_jerk_api/ui/settings.dart';
import 'package:poke_jerk_api/ui/team_builder.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/filter_bottom_sheet.dart';
import 'package:poke_jerk_api/ui/widgets/pokedex_filter_chips.dart';
import 'package:poke_jerk_api/ui/widgets/search_text_field.dart';
import 'package:poke_jerk_api/ui/widgets/version_group_chip.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const int _tabCount = 5;

  static const List<_NavItem> _allNavItems = [
    _NavItem(id: 0, labelFr: 'Pokédex', labelEn: 'Pokédex', icon: Icons.catching_pokemon),
    _NavItem(id: 1, labelFr: 'Données', labelEn: 'Data', icon: Icons.menu_book_outlined),
    _NavItem(id: 2, labelFr: 'Équipes', labelEn: 'Teams', icon: Icons.groups_outlined),
    _NavItem(id: 3, labelFr: 'Lieux', labelEn: 'Locations', icon: Icons.map_outlined),
    _NavItem(id: 4, labelFr: 'Réglages', labelEn: 'Settings', icon: Icons.settings_outlined),
  ];

  static const Set<int> _filterableIds = {0, 1, 3};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<GlobalFilterProvider>();
    if (!provider.filtersLoaded) {
      final client = GraphQLProvider.of(context).value;
      provider.loadFilters(client);
    }
  }

  List<int> _tabOrder(UserSettings settings) {
    final order = settings.tabOrder;
    if (order.length == _tabCount && order.toSet().length == _tabCount) return order;
    return List.generate(_tabCount, (i) => i);
  }

  Widget _buildPageById(int id) {
    switch (id) {
      case 0:
        return const Pokedex();
      case 1:
        return const DataPage();
      case 2:
        return const TeamBuilderPage();
      case 3:
        return const LocationsPage();
      case 4:
        return const SettingsPage();
      default:
        return const Pokedex();
    }
  }

  void _onTabChanged(int i) {
    if (i != _selectedIndex) {
      _searchController.clear();
      context.read<GlobalFilterProvider>().setSearch('');
      _searchOpen = false;
    }
    setState(() => _selectedIndex = i);
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        context.read<GlobalFilterProvider>().setSearch('');
        _searchFocusNode.unfocus();
      }
    });
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettings>();
    final language = settings.language;
    final filter = context.watch<GlobalFilterProvider>();
    final tabOrder = _tabOrder(settings);
    final currentId = tabOrder[_selectedIndex];
    final showFilters = _filterableIds.contains(currentId);

    final currentItem = _allNavItems[currentId];
    final title = currentId == 0
        ? 'PokéJerk'
        : (language == 'fr' ? currentItem.labelFr : currentItem.labelEn);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentItem.icon, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 17)),
          ],
        ),
        actions: [
          if (showFilters)
            IconButton(
              icon: Icon(_searchOpen ? Icons.search_off : Icons.search),
              onPressed: _toggleSearch,
              tooltip: language == 'fr' ? 'Rechercher' : 'Search',
            ),
        ],
        bottom: showFilters
            ? _FilterBar(
                filter: filter,
                language: language,
                onVersionTap: () => _showVersionSheet(context, language, filter),
                onTypeTap: () => _showTypeSheet(context, language, filter),
                onGenTap: () => _showGenerationSheet(context, language, filter),
                versionChipLabel: _versionLabel(language, filter),
                versionChipGroup: _versionChipGroup(filter),
                dlcSelected: filter.selectedVersionGroup?.isDlc == true
                    ? filter.selectedVersionGroup
                    : null,
                typeChip: filter.selectedTypeIds.isEmpty
                    ? const FilterChip2(
                        label: 'Type',
                        isActive: false,
                        icon: Icons.style_outlined,
                      )
                    : _typeFilterChip(language, filter),
                genChip: FilterChip2(
                  label: _genLabel(language, filter),
                  isActive: filter.selectedGenerationId != null,
                  icon: Icons.auto_awesome_mosaic_outlined,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          if (showFilters)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _searchOpen
                  ? Material(
                      color: Colors.white,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                        child: SearchTextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          search: filter.searchQuery,
                          language: language,
                          onChanged: (value) => filter.setSearch(value.trim()),
                          onCleared: () {
                            _searchController.clear();
                            filter.setSearch('');
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(_tabCount, (i) => _buildPageById(tabOrder[i])),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GestureDetector(
        onLongPress: () => _showTabOrderSheet(context, settings, language),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabChanged,
          destinations: tabOrder.map((id) {
            final item = _allNavItems[id];
            return NavigationDestination(
              icon: Icon(item.icon),
              label: language == 'fr' ? item.labelFr : item.labelEn,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTabOrderSheet(BuildContext context, UserSettings settings, String language) {
    showTabOrderSheet(context, settings, language);
  }

  String _versionLabel(String language, GlobalFilterProvider filter) {
    if (filter.selectedVersionGroup == null) return 'Version';
    final vg = filter.selectedVersionGroup!;
    final groupName = vg.getName(language);

    // If a DLC is selected, show "Parent + DLC name"
    if (vg.isDlc) {
      final parent = filter.versionGroups
          .cast<VersionGroup?>()
          .firstWhere((g) => g?.id == vg.parentId, orElse: () => null);
      if (parent != null) {
        return '${parent.getName(language)} · $groupName';
      }
    }

    if (vg.pokedexes.length <= 1 || filter.selectedPokedexId == null) {
      return groupName;
    }
    final dex = vg.pokedexes
        .cast<PokedexEntry?>()
        .firstWhere((p) => p?.id == filter.selectedPokedexId, orElse: () => null);
    return dex != null ? '$groupName · ${dex.name}' : groupName;
  }

  /// For chip display: use parent version group colors when a DLC is selected.
  VersionGroup? _versionChipGroup(GlobalFilterProvider filter) {
    final vg = filter.selectedVersionGroup;
    if (vg == null) return null;
    if (vg.isDlc) {
      return filter.versionGroups
          .cast<VersionGroup?>()
          .firstWhere((g) => g?.id == vg.parentId, orElse: () => vg);
    }
    return vg;
  }

  String _genLabel(String language, GlobalFilterProvider filter) {
    if (filter.selectedGenerationId == null) {
      return language == 'fr' ? 'Génération' : 'Generation';
    }
    return filter.generations
            .cast<Generation?>()
            .firstWhere((g) => g?.id == filter.selectedGenerationId, orElse: () => null)
            ?.name ??
        'Gen ${filter.selectedGenerationId}';
  }

  Widget _typeFilterChip(String language, GlobalFilterProvider filter) {
    final selected = filter.selectedTypeIds
        .map((id) => filter.types.cast<TypePokemon?>().firstWhere(
              (t) => t?.id == id,
              orElse: () => null,
            ))
        .whereType<TypePokemon>()
        .toList();

    final colors = selected
        .map((t) => ColorBuilder.getTypeColorByIdentifier(t.identifier))
        .toList();
    if (colors.isEmpty) colors.add(Colors.grey);

    final labels = selected.map((t) => t.getTranslation(language)).toList();
    if (labels.isEmpty) labels.add('');

    return SplitChip(icon: Icons.style_outlined, labels: labels, colors: colors);
  }

  void _showVersionSheet(
      BuildContext context, String language, GlobalFilterProvider filter) {
    showFilterBottomSheet(
      context: context,
      title: language == 'fr' ? 'Filtrer par version' : 'Filter by version',
      language: language,
      showClear: filter.selectedVersionGroup != null,
      onClear: () => filter.clearVersionGroup(),
      builder: (scrollController) {
        return ListView.separated(
          controller: scrollController,
          itemCount: filter.versionGroups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final g = filter.versionGroups[index];
            final isSelected = filter.selectedVersionGroup?.id == g.id;
            return AnimatedOpacity(
              opacity: filter.selectedVersionGroup != null && !isSelected ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  filter.selectVersionGroupWithDialog(context, g);
                },
                child: VersionGroupChip(
                  label: g.getName(language),
                  versionIdentifiers: g.versionIdentifiers,
                  fillWidth: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTypeSheet(
      BuildContext context, String language, GlobalFilterProvider filter) {
    showFilterBottomSheet(
      context: context,
      title: language == 'fr' ? 'Filtrer par type (max 2)' : 'Filter by type (max 2)',
      language: language,
      useDraggable: false,
      showClear: filter.selectedTypeIds.isNotEmpty,
      onClear: () => filter.clearTypes(),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filter.types.map((t) {
                final color = ColorBuilder.getTypeColorByIdentifier(t.identifier);
                final selected = filter.selectedTypeIds.contains(t.id);
                final disabled = !selected && filter.selectedTypeIds.length >= 2;
                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () {
                          filter.toggleTypeId(t.id);
                          setSheetState(() {});
                        },
                  child: AnimatedOpacity(
                    opacity: disabled ? 0.3 : (selected ? 1.0 : 0.5),
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t.getTranslation(language),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  void _showGenerationSheet(
      BuildContext context, String language, GlobalFilterProvider filter) {
    showFilterBottomSheet(
      context: context,
      title: language == 'fr' ? 'Filtrer par génération' : 'Filter by generation',
      language: language,
      showClear: filter.selectedGenerationId != null,
      onClear: () => filter.setGenerationId(null),
      builder: (scrollController) {
        return GridView.builder(
          controller: scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: filter.generations.length,
          itemBuilder: (_, index) {
            final g = filter.generations[index];
            final isSelected = filter.selectedGenerationId == g.id;
            const activeColor = Color(0xFFCC0000);
            final parts = g.name.split(' ');
            final numeral = parts.last;
            final prefix =
                parts.length > 1 ? parts.sublist(0, parts.length - 1).join(' ') : '';
            return AnimatedOpacity(
              opacity:
                  filter.selectedGenerationId != null && !isSelected ? 0.45 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: () {
                  filter.setGenerationId(g.id);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? activeColor : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        numeral,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? activeColor : Colors.black87,
                        ),
                      ),
                      if (prefix.isNotEmpty)
                        Text(
                          prefix,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected
                                ? activeColor.withValues(alpha: 0.8)
                                : Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void showTabOrderSheet(BuildContext context, UserSettings settings, String language) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _TabOrderSheet(settings: settings, language: language),
  );
}

class _TabOrderSheet extends StatefulWidget {
  final UserSettings settings;
  final String language;
  const _TabOrderSheet({required this.settings, required this.language});

  @override
  State<_TabOrderSheet> createState() => _TabOrderSheetState();
}

class _TabOrderSheetState extends State<_TabOrderSheet> {
  late List<int> _order;

  @override
  void initState() {
    super.initState();
    final stored = widget.settings.tabOrder;
    const count = _HomeState._tabCount;
    _order = (stored.length == count && stored.toSet().length == count)
        ? List<int>.from(stored)
        : List.generate(count, (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.language == 'fr' ? 'Réorganiser les onglets' : 'Reorder tabs',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.language == 'fr'
                ? 'Maintenez et glissez pour réorganiser'
                : 'Hold and drag to reorder',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _order.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _order.removeAt(oldIndex);
                _order.insert(newIndex, item);
              });
              widget.settings.setTabOrder(List<int>.from(_order));
            },
            itemBuilder: (context, index) {
              final tabId = _order[index];
              final item = _HomeState._allNavItems[tabId];
              final label = widget.language == 'fr' ? item.labelFr : item.labelEn;

              return ListTile(
                key: ValueKey(tabId),
                leading: Icon(item.icon, size: 22, color: Colors.grey.shade600),
                title: Text(label, style: const TextStyle(fontSize: 14)),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle, color: Colors.grey.shade400),
                ),
                dense: true,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final int id;
  final String labelFr;
  final String labelEn;
  final IconData icon;

  const _NavItem({required this.id, required this.labelFr, required this.labelEn, required this.icon});
}

class _FilterBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalFilterProvider filter;
  final String language;
  final VoidCallback onVersionTap;
  final VoidCallback onTypeTap;
  final VoidCallback onGenTap;
  final String versionChipLabel;
  final VersionGroup? versionChipGroup;
  final VersionGroup? dlcSelected;
  final Widget typeChip;
  final Widget genChip;

  const _FilterBar({
    required this.filter,
    required this.language,
    required this.onVersionTap,
    required this.onTypeTap,
    required this.onGenTap,
    required this.versionChipLabel,
    this.versionChipGroup,
    this.dlcSelected,
    required this.typeChip,
    required this.genChip,
  });

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        elevation: 0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: onVersionTap,
                child: VersionChip(
                  label: versionChipLabel,
                  selected: versionChipGroup,
                  dlcSelected: dlcSelected,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onTypeTap,
                child: typeChip,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onGenTap,
                child: genChip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
