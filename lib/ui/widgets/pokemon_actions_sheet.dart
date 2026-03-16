import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/comparator_provider.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/team_provider.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';
import 'package:provider/provider.dart';

/// Shows the long-press action menu for a Pokemon (compare, add to team).
void showPokemonActionsSheet(BuildContext context, Pokemon pokemon) {
  final language = context.read<UserSettings>().language;
  final name = pokemon.getTranslation(language);

  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: Text(tr(language, 'Ajouter au comparateur', 'Add to comparator')),
            onTap: () {
              Navigator.pop(ctx);
              _addToComparator(context, pokemon, name, language);
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups),
            title: Text(tr(language, 'Ajouter à une équipe', 'Add to a team')),
            onTap: () {
              Navigator.pop(ctx);
              showTeamPickerSheet(context, pokemon);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _addToComparator(BuildContext context, Pokemon pokemon, String name, String language) {
  final comp = context.read<ComparatorProvider>();
  final String message;

  if (comp.contains(pokemon.id)) {
    message = tr(language,
      '$name est déjà dans le comparateur',
      '$name is already in the comparator');
  } else if (comp.isFull) {
    message = tr(language,
      'Le comparateur est plein (${ComparatorProvider.maxCompare} max)',
      'Comparator is full (${ComparatorProvider.maxCompare} max)');
  } else {
    comp.addPokemon(pokemon.id);
    message = tr(language,
      '$name ajouté au comparateur (${comp.count}/${ComparatorProvider.maxCompare})',
      '$name added to comparator (${comp.count}/${ComparatorProvider.maxCompare})');
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

/// Shows a bottom sheet to pick a team (or create a new one) to add the pokemon to.
void showTeamPickerSheet(BuildContext context, Pokemon pokemon) {
  final teamProvider = context.read<TeamProvider>();
  final language = context.read<UserSettings>().language;
  final pokemonName = pokemon.getTranslation(language);

  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final teams = teamProvider.teams;
      final availableTeams = teams.where((t) => t.pokemonIds.length < 6).toList();

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                tr(language, 'Ajouter $pokemonName à…', 'Add $pokemonName to…'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(tr(language, 'Nouvelle équipe', 'New team')),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateTeamDialog(context, pokemon);
              },
            ),
            if (availableTeams.isNotEmpty) const Divider(height: 1),
            ...availableTeams.map((team) => ListTile(
              leading: const Icon(Icons.groups),
              title: Text(team.name),
              subtitle: Text('${team.pokemonIds.length}/6'),
              onTap: () {
                teamProvider.addPokemon(team, pokemon.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr(language,
                      '$pokemonName ajouté à ${team.name}',
                      '$pokemonName added to ${team.name}')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

void _showCreateTeamDialog(BuildContext context, Pokemon pokemon) {
  final language = context.read<UserSettings>().language;
  final pokemonName = pokemon.getTranslation(language);
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr(language, 'Nouvelle équipe', 'New team')),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: tr(language, 'Nom de l\'équipe', 'Team name'),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(ctx, value.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr(language, 'Annuler', 'Cancel')),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          child: Text(tr(language, 'Créer', 'Create')),
        ),
      ],
    ),
  ).then((name) {
    if (name == null || !context.mounted) return;
    final teamProvider = context.read<TeamProvider>();
    teamProvider.addTeam(name);
    final newTeam = teamProvider.teams.last;
    teamProvider.addPokemon(newTeam, pokemon.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(language, '$pokemonName ajouté à $name', '$pokemonName added to $name')),
        duration: const Duration(seconds: 2),
      ),
    );
  });
}
