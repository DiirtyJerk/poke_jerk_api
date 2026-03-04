import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/type_pokemon.dart';

// Remplace les switch imbriqués de poke_jerk par des Maps constantes
class ColorBuilder {
  ColorBuilder._();

  static const Map<String, Color> _typeColors = {
    'normal': Color(0xFFA8A878),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'electric': Color(0xFFF8D030),
    'grass': Color(0xFF78C850),
    'ice': Color(0xFF98D8D8),
    'fighting': Color(0xFFC03028),
    'poison': Color(0xFFA040A0),
    'ground': Color(0xFFE0C068),
    'flying': Color(0xFF89CFF0),
    'psychic': Color(0xFFF85888),
    'bug': Color(0xFFA8B820),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'dragon': Color(0xFF7038F8),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB8B8D0),
    'fairy': Color(0xFFEE99AC),
    'shadow': Color(0xFF4B0082),
  };

  static const Map<String, Color> _versionColors = {
    'red': Colors.red,
    'blue': Colors.blue,
    'yellow': Color(0xFFF8D030),
    'gold': Color(0xFFFFD700),
    'silver': Color(0xFFC0C0C0),
    'crystal': Color(0xFF7FFFD4),
    'ruby': Color(0xFF9B111E),
    'sapphire': Color(0xFF0F52BA),
    'emerald': Color(0xFF50C878),
    'firered': Color(0xFFFF4500),
    'leafgreen': Color(0xFF228B22),
    'diamond': Color(0xFFB9F2FF),
    'pearl': Color(0xFFE0B0FF),
    'platinum': Color(0xFFE5E4E2),
    'heartgold': Color(0xFFFFD700),
    'soulsilver': Color(0xFFC0C0C0),
    'black': Color(0xFF333333),
    'white': Color(0xFFF5F5F5),
    'black-2': Color(0xFF333333),
    'white-2': Color(0xFFF5F5F5),
    'x': Color(0xFF003A8C),
    'y': Color(0xFF8B0000),
    'omega-ruby': Color(0xFF9B111E),
    'alpha-sapphire': Color(0xFF0F52BA),
    'sun': Color(0xFFFF8C00),
    'moon': Color(0xFF191970),
    'ultra-sun': Color(0xFFFF6600),
    'ultra-moon': Color(0xFF000080),
    'lets-go-pikachu': Color(0xFFF8D030),
    'lets-go-eevee': Color(0xFFB8860B),
    'sword': Color(0xFF4169E1),
    'shield': Color(0xFFDC143C),
    'brilliant-diamond': Color(0xFFB9F2FF),
    'shining-pearl': Color(0xFFE0B0FF),
    'legends-arceus': Color(0xFF8B4513),
    'scarlet': Color(0xFFFF2400),
    'violet': Color(0xFF7F00FF),
  };

  static Color getTypeColor(TypePokemon type) {
    return _typeColors[type.identifier] ?? Colors.red;
  }

  static Color getTypeColorByIdentifier(String identifier) {
    return _typeColors[identifier] ?? Colors.red;
  }

  static Color getVersionColor(String versionIdentifier) {
    return _versionColors[versionIdentifier] ?? Colors.blueGrey;
  }

  static const Map<String, Color> _versionGroupColors = {
    'red-blue': Color(0xFFCC0000),
    'yellow': Color(0xFFF8D030),
    'gold-silver': Color(0xFFFFD700),
    'crystal': Color(0xFF7FFFD4),
    'ruby-sapphire': Color(0xFF9B111E),
    'emerald': Color(0xFF50C878),
    'firered-leafgreen': Color(0xFFFF4500),
    'diamond-pearl': Color(0xFFB9F2FF),
    'platinum': Color(0xFFE5E4E2),
    'heartgold-soulsilver': Color(0xFFFFD700),
    'black-white': Color(0xFF333333),
    'black-2-white-2': Color(0xFF555555),
    'x-y': Color(0xFF003A8C),
    'omega-ruby-alpha-sapphire': Color(0xFF9B111E),
    'sun-moon': Color(0xFFFF8C00),
    'ultra-sun-ultra-moon': Color(0xFFFF6600),
    'lets-go-pikachu-lets-go-eevee': Color(0xFFF8D030),
    'sword-shield': Color(0xFF4169E1),
    'brilliant-diamond-and-shining-pearl': Color(0xFFB9F2FF),
    'legends-arceus': Color(0xFF8B4513),
    'scarlet-violet': Color(0xFFFF2400),
  };

  static Color getVersionGroupColor(String identifier) {
    return _versionGroupColors[identifier] ?? Colors.blueGrey;
  }

  static Color getVersionGroupTextColor(String identifier) {
    final bg = getVersionGroupColor(identifier);
    return bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
  }

  /// Couleur du texte sur fond de version (blanc ou noir selon la luminosité)
  static Color getVersionTextColor(String versionIdentifier) {
    final bg = getVersionColor(versionIdentifier);
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }

  /// Couleur des stats
  static const Map<String, Color> _statColors = {
    'hp': Color(0xFFA9F09D),
    'attack': Color(0xFFE99068),
    'defense': Color(0xFFEFF09C),
    'special-attack': Color(0xFFF4C89D),
    'special-defense': Color(0xFFE4C761),
    'speed': Color(0xFFAAF0F1),
  };

  static Color getStatColor(String statIdentifier) {
    return _statColors[statIdentifier] ?? Colors.grey;
  }
}
