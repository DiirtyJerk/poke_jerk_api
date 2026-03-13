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

final _numRe = RegExp(r'(\d+)');

/// Natural comparison: splits strings into text/number segments
/// so that "Route 2" < "Route 10".
int naturalCompare(String a, String b) {
  final partsA = a.split(_numRe);
  final numsA = _numRe.allMatches(a).map((m) => int.parse(m[0]!)).toList();
  final partsB = b.split(_numRe);
  final numsB = _numRe.allMatches(b).map((m) => int.parse(m[0]!)).toList();

  final len = partsA.length + numsA.length;
  final lenB = partsB.length + numsB.length;
  final max = len < lenB ? len : lenB;

  int ai = 0, ni = 0;
  int bi = 0, nbi = 0;
  for (var i = 0; i < max; i++) {
    if (i.isEven) {
      // text segment
      if (ai >= partsA.length || bi >= partsB.length) break;
      final c = partsA[ai].compareTo(partsB[bi]);
      if (c != 0) return c;
      ai++;
      bi++;
    } else {
      // number segment
      if (ni >= numsA.length || nbi >= numsB.length) break;
      final c = numsA[ni].compareTo(numsB[nbi]);
      if (c != 0) return c;
      ni++;
      nbi++;
    }
  }
  return a.length.compareTo(b.length);
}

/// Resolve a localized name from a PokeAPI `Map<int, String>` name map.
String localizedName(Map<int, String> names, String language, [String fallback = '?']) {
  final id = langId(language);
  return names[id] ?? names[9] ?? fallback;
}
