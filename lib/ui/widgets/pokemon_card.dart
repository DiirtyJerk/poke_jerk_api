import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PokemonCard({super.key, required this.pokemon, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final language = UserSettings().language;
    final primaryType = pokemon.types.isNotEmpty ? pokemon.types.first : null;
    final bgColor = primaryType != null
        ? ColorBuilder.getTypeColor(primaryType).withValues(alpha: 0.15)
        : Colors.grey.shade100;

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
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  pokemon.pokedexNumber != null
                      ? '#${pokemon.pokedexNumber.toString().padLeft(3, '0')}'
                      : pokemon.displayId,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
