import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/items.dart';
import 'package:poke_jerk_api/ui/moves.dart';
import 'package:poke_jerk_api/ui/type_chart_page.dart';
import 'package:provider/provider.dart';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                text: language == 'fr' ? 'Objets' : 'Items',
              ),
              Tab(
                icon: const Icon(Icons.flash_on_outlined, size: 18),
                text: language == 'fr' ? 'Capacités' : 'Moves',
              ),
              Tab(
                icon: const Icon(Icons.grid_view_outlined, size: 18),
                text: 'Types',
              ),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ItemsPage(),
                MovesPage(),
                TypeChartPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
