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
