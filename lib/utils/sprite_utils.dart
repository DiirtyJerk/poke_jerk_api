/// Base URL for all PokeAPI sprite assets.
const String _spriteBase =
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites';

/// Official artwork URL for a given pokemon ID.
String pokemonArtworkUrl(int id) =>
    '$_spriteBase/pokemon/other/official-artwork/$id.png';

/// Shiny official artwork URL for a given pokemon ID.
String pokemonShinyArtworkUrl(int id) =>
    '$_spriteBase/pokemon/other/official-artwork/shiny/$id.png';

/// Small sprite URL for a given pokemon ID.
String pokemonSpriteUrl(int id) => '$_spriteBase/pokemon/$id.png';

/// Item sprite URL for a given item identifier.
String itemSpriteUrl(String identifier) => '$_spriteBase/items/$identifier.png';
