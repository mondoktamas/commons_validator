/// ASCII-only replacements for the Unicode-aware `java.lang.Character` helpers
/// that Apache Commons Validator relies on.
///
/// Java's `Character.isDigit`, `Character.getNumericValue` and
/// `Character.isUpperCase` are Unicode-aware: they accept Arabic-Indic and
/// fullwidth digits, Roman numerals, and accented capitals. Upstream guards
/// almost every call with an explicit ASCII test first (see
/// `AbstractCheckDigit.isAsciiAlphaNum`), so restricting to ASCII here is
/// faithful — and it is what `CheckDigitNonAsciiDigitTest` asserts.
library;

const int _zero = 0x30; // '0'
const int _nine = 0x39; // '9'
const int _upperA = 0x41; // 'A'
const int _upperZ = 0x5A; // 'Z'
const int _lowerA = 0x61; // 'a'
const int _lowerZ = 0x7A; // 'z'

/// The largest value [asciiNumericValue] can return, for 'Z'.
const int maxAlphanumericValue = 35;

/// Whether [c] is an ASCII digit `0`-`9`.
bool isAsciiDigit(int c) => c >= _zero && c <= _nine;

/// Whether [c] is an ASCII letter `A`-`Z` or `a`-`z`.
bool isAsciiAlpha(int c) =>
    (c >= _upperA && c <= _upperZ) || (c >= _lowerA && c <= _lowerZ);

/// Whether [c] is an ASCII letter or digit.
bool isAsciiAlphaNum(int c) => isAsciiDigit(c) || isAsciiAlpha(c);

/// Whether [c] is an ASCII upper-case letter `A`-`Z`.
///
/// Unlike Java's `Character.isUpperCase`, accented capitals such as `À` are
/// rejected. `IBANValidator` depends on this narrower reading.
bool isAsciiUpper(int c) => c >= _upperA && c <= _upperZ;

/// The numeric value of an ASCII alphanumeric: `0`-`9` map to 0-9 and letters
/// map to 10-35, case-insensitively. Returns -1 for anything else.
///
/// This is the ASCII-only equivalent of `Character.getNumericValue`.
int asciiNumericValue(int c) {
  if (isAsciiDigit(c)) return c - _zero;
  if (c >= _upperA && c <= _upperZ) return c - _upperA + 10;
  if (c >= _lowerA && c <= _lowerZ) return c - _lowerA + 10;
  return -1;
}

/// Lower-cases only ASCII `A`-`Z`, leaving every other code point untouched.
///
/// Upstream uses `toLowerCase(Locale.ENGLISH)` for TLD and scheme folding.
/// Dart's `String.toLowerCase` applies Unicode folding, which would introduce
/// the Turkish-dotless-I class of bug, so fold explicitly instead.
String asciiToLowerCase(String s) {
  final units = s.codeUnits;
  List<int>? out;
  for (var i = 0; i < units.length; i++) {
    final c = units[i];
    if (c >= _upperA && c <= _upperZ) {
      out ??= List<int>.of(units);
      out[i] = c + 0x20;
    }
  }
  return out == null ? s : String.fromCharCodes(out);
}

/// Upper-cases only ASCII `a`-`z`, leaving every other code point untouched.
String asciiToUpperCase(String s) {
  final units = s.codeUnits;
  List<int>? out;
  for (var i = 0; i < units.length; i++) {
    final c = units[i];
    if (c >= _lowerA && c <= _lowerZ) {
      out ??= List<int>.of(units);
      out[i] = c - 0x20;
    }
  }
  return out == null ? s : String.fromCharCodes(out);
}

/// Whether every code unit of [s] is ASCII (`<= 0x7F`). A null-ish empty string
/// counts as ASCII, matching `DomainValidator.isOnlyASCII`.
bool isOnlyAscii(String s) {
  for (final c in s.codeUnits) {
    if (c > 0x7F) return false;
  }
  return true;
}
