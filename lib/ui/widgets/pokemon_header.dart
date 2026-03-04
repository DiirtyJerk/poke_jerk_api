import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/pokemon.dart';
import 'package:poke_jerk_api/ui/widgets/detail_loading_skeleton.dart';
import 'package:poke_jerk_api/ui/widgets/type_chip.dart';

class PokemonHeader extends StatelessWidget {
  final Pokemon pokemon;
  final String language;
  final Color bgColor;
  final Color bgColorDark;

  const PokemonHeader({
    super.key,
    required this.pokemon,
    required this.language,
    required this.bgColor,
    required this.bgColorDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColorDark, bgColor],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: 20,
            child: Opacity(
              opacity: 0.12,
              child: SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(painter: PokeBallPainter()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    CachedNetworkImage(
                      imageUrl: pokemon.officialArtworkUrl,
                      height: 140,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const SizedBox(
                        height: 140,
                        child: Center(
                          child: Icon(Icons.catching_pokemon,
                              color: Colors.white38, size: 64),
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                          Icons.catching_pokemon, size: 80, color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            pokemon.displayId,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                          if (pokemon.generationId != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Gen. ${pokemon.generationId}',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        pokemon.getTranslation(language),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                      if (pokemon.species?.getGenus(language).isNotEmpty ?? false)
                        Text(
                          pokemon.species!.getGenus(language),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: pokemon.types
                            .map((t) => TypeChip(type: t, language: language))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _InfoBadge(
                            icon: Icons.straighten,
                            label: language == 'fr' ? 'Taille' : 'Height',
                            value: '${pokemon.height} m',
                          ),
                          const SizedBox(width: 16),
                          _InfoBadge(
                            icon: Icons.monitor_weight_outlined,
                            label: language == 'fr' ? 'Poids' : 'Weight',
                            value: '${pokemon.weight} kg',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBadge({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: Colors.white60),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}
