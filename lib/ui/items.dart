import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:poke_jerk_api/graphql/queries.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/item.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/detail_item.dart';
import 'package:poke_jerk_api/ui/widgets/query_result.dart' as qr;
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:provider/provider.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ScrollController _scrollController = ScrollController();

  List<Item> _allItems = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allItems.isEmpty && !_isLoading) _loadAll();
  }

  Future<void> _loadAll() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(getItemsQuery),
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    ));

    if (!mounted) return;

    final data = result.data?['pokemon_v2_item'] as List? ?? [];
    setState(() {
      _allItems = data.map((i) => Item.fromJson(i as Map<String, dynamic>)).toList();
      _isLoading = false;
    });
  }

  List<Item> _filteredItems(GlobalFilterProvider filter, String language) {
    var list = _allItems;

    if (filter.searchQuery.length >= 2) {
      final query = normalize(filter.searchQuery);
      list = list
          .where((i) => normalize(i.getTranslation(language)).contains(query))
          .toList();
    }

    if (filter.selectedVersionGroup != null) {
      final maxGen = filter.selectedVersionGroup!.generationId;
      list = list
          .where((i) =>
              i.generationIds.isEmpty ||
              i.generationIds.any((g) => g <= maxGen))
          .toList();
    }

    if (filter.selectedGenerationId != null) {
      list = list
          .where((i) =>
              i.generationIds.isEmpty ||
              i.generationIds.any((g) => g <= filter.selectedGenerationId!))
          .toList();
    }

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

    return _buildBody(language, filter);
  }

  Widget _buildBody(String language, GlobalFilterProvider filter) {
    final filtered = _filteredItems(filter, language);

    if (_allItems.isEmpty && _isLoading) return const qr.LoadingWidget();
    if (filtered.isEmpty && !_isLoading) {
      return qr.EmptyWidget(
          message: language == 'fr' ? 'Aucun objet trouvé' : 'No items found');
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _ItemTile(item: filtered[index], language: language);
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Item item;
  final String language;

  const _ItemTile({required this.item, required this.language});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: item.spriteUrl,
        width: 36,
        height: 36,
        errorWidget: (_, _, _) => const Icon(Icons.inventory_2_outlined),
      ),
      title: Text(item.getTranslation(language)),
      subtitle: Text(item.getCategoryTranslation(language),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: item.cost > 0
          ? Text('${item.cost} ₽', style: const TextStyle(fontWeight: FontWeight.w500))
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailItem(itemId: item.id)),
      ),
    );
  }
}
