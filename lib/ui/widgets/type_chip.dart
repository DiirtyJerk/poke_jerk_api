import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';

class TypeChip extends StatelessWidget {
  final TypePokemon type;
  final String language;
  final double fontSize;

  const TypeChip({
    super.key,
    required this.type,
    required this.language,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorBuilder.getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.getTranslation(language),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
