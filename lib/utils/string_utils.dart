const _diacritics =
    'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
const _noDiacritics =
    'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

String normalize(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final c in lower.runes) {
    final ch = String.fromCharCode(c);
    final i = _diacritics.indexOf(ch);
    buf.write(i >= 0 ? _noDiacritics[i] : ch);
  }
  return buf.toString();
}

/// PokeAPI language id for the given app language code.
int langId(String language) => language == 'fr' ? 5 : 9;

/// Pick translated string based on current language.
String tr(String language, String fr, String en) => language == 'fr' ? fr : en;

/// Resolve a localized name from a PokeAPI `Map<int, String>` name map.
String localizedName(Map<int, String> names, String language, [String fallback = '?']) {
  final id = langId(language);
  return names[id] ?? names[9] ?? fallback;
}
