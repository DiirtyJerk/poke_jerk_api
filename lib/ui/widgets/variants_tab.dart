import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';

class VariantsTab extends StatelessWidget {
  final Pokemon pokemon;
  final String language;
  final Color accentColor;

  const VariantsTab({
    super.key,
    required this.pokemon,
    required this.language,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final variants = pokemon.variants;
    if (variants.isEmpty) {
      return Center(
        child: Text(
          language == 'fr' ? 'Aucune variante' : 'No variants',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final variant in variants) ...[
                  _VariantCard(
                    variant: variant,
                    speciesName: pokemon.getTranslation(language),
                    language: language,
                    isCurrentPokemon: variant.id == pokemon.id,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VariantCard extends StatelessWidget {
  final PokemonVariant variant;
  final String speciesName;
  final String language;
  final bool isCurrentPokemon;

  const _VariantCard({
    required this.variant,
    required this.speciesName,
    required this.language,
    required this.isCurrentPokemon,
  });

  @override
  Widget build(BuildContext context) {
    final name = variant.names.isNotEmpty
        ? variant.getTranslation(language)
        : speciesName;
    final primaryType = variant.types.isNotEmpty ? variant.types.first : null;
    final bgColor = primaryType != null
        ? ColorBuilder.getTypeColor(primaryType).withValues(alpha: 0.1)
        : Colors.grey.shade100;
    final borderColor = primaryType != null
        ? ColorBuilder.getTypeColor(primaryType).withValues(alpha: 0.3)
        : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPokemon ? borderColor : borderColor.withValues(alpha: 0.5),
          width: isCurrentPokemon ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with name and types
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (variant.formName.isNotEmpty)
                        Text(
                          _regionLabel(variant.formName),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrentPokemon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      language == 'fr' ? 'Actuel' : 'Current',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Type chips
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Wrap(
              spacing: 6,
              children: variant.types.map((t) {
                final color = ColorBuilder.getTypeColor(t);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.getTranslation(language),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Sprites: normal + shiny
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SpriteColumn(
                  url: variant.spriteUrl,
                  label: language == 'fr' ? 'Normal' : 'Normal',
                ),
                _SpriteColumn(
                  url: variant.shinySpriteUrl,
                  label: 'Shiny',
                  isShiny: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _regionLabel(String formName) {
    const labels = {
      'alola': 'Alola',
      'galar': 'Galar',
      'hisui': 'Hisui',
      'paldea': 'Paldea',
      'mega': 'Méga',
      'mega-x': 'Méga X',
      'mega-y': 'Méga Y',
      'gmax': 'Gigamax',
    };
    return labels[formName] ?? formName;
  }
}

class _SpriteColumn extends StatelessWidget {
  final String url;
  final String label;
  final bool isShiny;

  const _SpriteColumn({
    required this.url,
    required this.label,
    this.isShiny = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              placeholder: (_, _) => SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: Icon(Icons.catching_pokemon,
                      color: Colors.grey.shade300, size: 40),
                ),
              ),
              errorWidget: (_, _, _) => SizedBox(
                width: 120,
                height: 120,
                child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
              ),
            ),
            if (isShiny)
              const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
