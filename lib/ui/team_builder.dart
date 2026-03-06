import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/team_provider.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/user_team.dart';
import 'package:poke_jerk_api/ui/team_editor.dart';
import 'package:provider/provider.dart';

class TeamBuilderPage extends StatelessWidget {
  const TeamBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final teamProvider = context.watch<TeamProvider>();
    final teams = teamProvider.teams;

    return Scaffold(
      body: teams.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    language == 'fr' ? 'Aucune équipe' : 'No teams yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: teams.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TeamCard(
                team: teams[i],
                language: language,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TeamEditorPage(team: teams[i])),
                ),
                onDelete: () => _confirmDelete(context, teamProvider, teams[i], language),
                onRename: () => _renameDialog(context, teamProvider, teams[i], language),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createDialog(context, teamProvider, language),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createDialog(BuildContext context, TeamProvider provider, String language) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(language == 'fr' ? 'Nouvelle équipe' : 'New team'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: language == 'fr' ? 'Nom de l\'équipe' : 'Team name',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.addTeam(value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(language == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addTeam(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(language == 'fr' ? 'Créer' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _renameDialog(
      BuildContext context, TeamProvider provider, UserTeam team, String language) {
    final controller = TextEditingController(text: team.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(language == 'fr' ? 'Renommer' : 'Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.renameTeam(team, value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(language == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameTeam(team, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, TeamProvider provider, UserTeam team, String language) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(language == 'fr' ? 'Supprimer ?' : 'Delete?'),
        content: Text(
          language == 'fr'
              ? 'Supprimer l\'équipe "${team.name}" ?'
              : 'Delete team "${team.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(language == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeTeam(team);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(language == 'fr' ? 'Supprimer' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final UserTeam team;
  final String language;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _TeamCard({
    required this.team,
    required this.language,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onRename,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      team.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${team.pokemonIds.length}/6',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(6, (i) {
                  final hasSlot = i < team.pokemonIds.length;
                  final id = hasSlot ? team.pokemonIds[i] : 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: hasSlot
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
                                    fit: BoxFit.contain,
                                    placeholder: (_, _) => const Center(
                                      child: Icon(Icons.catching_pokemon,
                                          color: Colors.grey, size: 20),
                                    ),
                                    errorWidget: (_, _, _) => const Center(
                                      child: Icon(Icons.catching_pokemon,
                                          color: Colors.grey, size: 20),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.add,
                                      color: Colors.grey.shade300, size: 20),
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
