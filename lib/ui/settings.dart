import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/home.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettings>();
    final language = settings.language;

    return ListView(
      children: [
          // Language
          ListTile(
            title: const Text('Langue / Language'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fr', label: Text('FR')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {settings.language},
              onSelectionChanged: (selection) => settings.changeLanguage(selection.first),
            ),
          ),
          const Divider(),

          // Show Mega
          SwitchListTile(
            title: const Text('Afficher les Méga-évolutions'),
            subtitle: const Text('Inclure Méga et formes alternatives'),
            value: settings.showMega,
            onChanged: settings.setShowMega,
          ),

          // Show Battle-only
          SwitchListTile(
            title: const Text('Afficher les formes de combat'),
            subtitle: const Text('Inclure les formes apparaissant uniquement en combat'),
            value: settings.showBattle,
            onChanged: settings.setShowBattle,
          ),

          // Captured feature
          SwitchListTile(
            title: const Text('Suivi de capture'),
            subtitle: const Text('Afficher le bouton de capture sur chaque Pokémon'),
            value: settings.capturedFeature,
            onChanged: settings.setCapturedFeature,
          ),

          const Divider(),

          // Tab order
          ListTile(
            leading: const Icon(Icons.reorder),
            title: Text(language == 'fr' ? 'Réorganiser les onglets' : 'Reorder tabs'),
            subtitle: Text(
              language == 'fr'
                  ? 'Changer l\'ordre des onglets de navigation'
                  : 'Change the navigation tab order',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showTabOrderSheet(context, settings, language),
          ),
        ],
      );
  }
}
