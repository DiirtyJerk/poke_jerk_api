import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/users_datas.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';
import 'package:provider/provider.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PokemonCard({super.key, required this.pokemon, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<UserSettings>();
    final userDatas = context.watch<UserDatas>();
    final language = settings.language;
    final primaryType = pokemon.types.isNotEmpty ? pokemon.types.first : null;
    final bgColor = primaryType != null
        ? ColorBuilder.getTypeColor(primaryType).withValues(alpha: 0.15)
        : Colors.grey.shade100;
    final vgId = context.read<GlobalFilterProvider>().selectedVersionGroup?.id;
    final userData = userDatas.getUserPokemon(pokemon.identifier);
    final isCaptured = settings.capturedFeature &&
        (userData?.isCapturedIn(vgId) ?? false);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        color: bgColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pokemon.pokedexNumber != null
                        ? '#${pokemon.pokedexNumber.toString().padLeft(3, '0')}'
                        : pokemon.displayId,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (settings.capturedFeature)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => userDatas.capturedPokemon(
                        pokemon.identifier,
                        !isCaptured,
                        versionGroupId: vgId,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isCaptured ? Icons.catching_pokemon : Icons.catching_pokemon_outlined,
                          size: 22,
                          color: isCaptured ? const Color(0xFFE53935) : Colors.grey.shade400,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: pokemon.spriteUrl ?? pokemon.officialArtworkUrl,
                  placeholder: (_, _) => Center(
                    child: Icon(Icons.catching_pokemon,
                        color: Colors.grey.shade300, size: 40),
                  ),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.catching_pokemon, size: 48, color: Colors.grey),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pokemon.getTranslation(language),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: pokemon.types
                    .map((t) => TypeChip(type: t, language: language, fontSize: 10))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
