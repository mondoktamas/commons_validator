/// Replacements for `java.lang.String` and `java.lang.Character` behaviours that
/// differ from their nearest Dart equivalents.
///
/// These differences are silent: the Dart built-ins compile and run, they just
/// give different answers on the inputs the validators care about. Ported code
/// should call these helpers instead of `String.trim` and `String.split`.
library;

/// `java.lang.String.trim` semantics: strips only code units `<= U+0020`.
///
/// This differs from Dart's [String.trim], which strips Unicode whitespace and
/// therefore also removes NBSP (U+00A0) and NNBSP (U+202F). Those two are
/// exactly the characters `fr`/`ru`-style locales use as grouping and currency
/// separators, so using the wrong trim silently changes number parsing. It also
/// changes what counts as blank: an NBSP-only string is *not* blank in Java.
String javaTrim(String s) {
  var start = 0;
  var end = s.length;
  while (start < end && s.codeUnitAt(start) <= 0x20) {
    start++;
  }
  while (end > start && s.codeUnitAt(end - 1) <= 0x20) {
    end--;
  }
  return start == 0 && end == s.length ? s : s.substring(start, end);
}

/// `java.lang.String.split` semantics.
///
/// Java drops trailing empty strings when no limit is given, and keeps them for
/// a negative limit. Dart's [String.split] always keeps them, which breaks
/// `InetAddressValidator`'s IPv6 group counting: Java's `"1::".split(":")` is
/// `[1]`, Dart's is `[1, , ]`.
///
/// Pass [limit] `0` (the default) for Java's no-limit behaviour, or `-1` to keep
/// trailing empties, mirroring `split(regex, -1)`.
List<String> javaSplit(String s, Pattern separator, {int limit = 0}) {
  final parts = s.split(separator);
  if (limit != 0) return parts;
  var end = parts.length;
  while (end > 0 && parts[end - 1].isEmpty) {
    end--;
  }
  return end == parts.length ? parts : parts.sublist(0, end);
}

/// `java.lang.Character.isSpaceChar`: true for Unicode categories Zs, Zl and Zp.
///
/// Note this is *not* the same as "whitespace": `\t`, `\n` and `\r` are all
/// false here. `BigDecimalValidator` uses it to strip a separator sitting next
/// to a currency symbol, which in suffix locales is an NBSP.
bool isSpaceChar(int codePoint) {
  switch (codePoint) {
    case 0x20: // SPACE (Zs)
    case 0xA0: // NO-BREAK SPACE (Zs)
    case 0x1680: // OGHAM SPACE MARK (Zs)
    case 0x2028: // LINE SEPARATOR (Zl)
    case 0x2029: // PARAGRAPH SEPARATOR (Zp)
    case 0x202F: // NARROW NO-BREAK SPACE (Zs)
    case 0x205F: // MEDIUM MATHEMATICAL SPACE (Zs)
    case 0x3000: // IDEOGRAPHIC SPACE (Zs)
      return true;
    default:
      // U+2000..U+200A EN QUAD .. HAIR SPACE (Zs)
      return codePoint >= 0x2000 && codePoint <= 0x200A;
  }
}

/// Matches a single code point in Unicode general category `Cf` (Format).
///
/// Stands in for `Character.getType(cp) == Character.FORMAT`. Verified to match
/// SOFT HYPHEN, ZWJ and BOM while *not* matching COMBINING GRAPHEME JOINER
/// (U+034F) or the variation selectors — which is precisely why
/// `DomainValidator` carries [isNameprepMappedToNothing] as a separate check.
final RegExp _formatChar = RegExp(r'\p{Cf}', unicode: true);

/// Whether [codePoint] is in Unicode general category `Cf` (Format).
bool isFormatChar(int codePoint) =>
    _formatChar.hasMatch(String.fromCharCode(codePoint));

/// Code points that RFC 3454 (nameprep) Table B.1 maps to nothing but which are
/// *not* in category `Cf`, so [isFormatChar] does not catch them.
///
/// Ported verbatim from `DomainValidator.isNameprepMappedToNothing`.
bool isNameprepMappedToNothing(int codePoint) =>
    codePoint == 0x034F || // COMBINING GRAPHEME JOINER
    codePoint == 0x1806 || // MONGOLIAN TODO SOFT HYPHEN
    (codePoint >= 0x180B && codePoint <= 0x180D) || // MONGOLIAN FVS ONE..THREE
    (codePoint >= 0xFE00 && codePoint <= 0xFE0F); // VARIATION SELECTOR-1..16
