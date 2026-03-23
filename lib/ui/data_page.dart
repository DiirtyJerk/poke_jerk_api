import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/items.dart';
import 'package:poke_jerk_api/ui/moves.dart';
import 'package:poke_jerk_api/ui/natures_page.dart';
import 'package:poke_jerk_api/ui/type_chart_page.dart';
import 'package:provider/provider.dart';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              Tab(text: language == 'fr' ? 'Objets' : 'Items'),
              Tab(text: language == 'fr' ? 'Capacités' : 'Moves'),
              const Tab(text: 'Types'),
              const Tab(text: 'Natures'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ItemsPage(),
                MovesPage(),
                TypeChartPage(),
                NaturesPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
