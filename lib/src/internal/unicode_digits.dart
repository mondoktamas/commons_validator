// GENERATED FILE - do not edit by hand.
//
// Regenerate with tool/generate_unicode_digits.dart.

/// The starting code point of each contiguous run of ten Unicode decimal digits.
///
/// `java.text.DecimalFormat` falls back to `Character.digit(ch, 10)` when a
/// character is not the locale's own zero digit, so it happily parses
/// Arabic-Indic and fullwidth digits. Without this table the port would be
/// stricter than Java.
///
/// Note this is the opposite of the check-digit routines, which reject non-ASCII
/// digits - there the guard is explicit in the Java source.
///
/// Extracted from OpenJDK 17.0.18, 65 runs.
const List<int> unicodeDigitZeros = [
  0x0030,
  0x0660,
  0x06F0,
  0x07C0,
  0x0966,
  0x09E6,
  0x0A66,
  0x0AE6,
  0x0B66,
  0x0BE6,
  0x0C66,
  0x0CE6,
  0x0D66,
  0x0DE6,
  0x0E50,
  0x0ED0,
  0x0F20,
  0x1040,
  0x1090,
  0x17E0,
  0x1810,
  0x1946,
  0x19D0,
  0x1A80,
  0x1A90,
  0x1B50,
  0x1BB0,
  0x1C40,
  0x1C50,
  0xA620,
  0xA8D0,
  0xA900,
  0xA9D0,
  0xA9F0,
  0xAA50,
  0xABF0,
  0xFF10,
  0x104A0,
  0x10D30,
  0x11066,
  0x110F0,
  0x11136,
  0x111D0,
  0x112F0,
  0x11450,
  0x114D0,
  0x11650,
  0x116C0,
  0x11730,
  0x118E0,
  0x11950,
  0x11C50,
  0x11D50,
  0x11DA0,
  0x16A60,
  0x16B50,
  0x1D7CE,
  0x1D7D8,
  0x1D7E2,
  0x1D7EC,
  0x1D7F6,
  0x1E140,
  0x1E2F0,
  0x1E950,
  0x1FBF0,
];

/// The decimal value of [codePoint], or -1 if it is not a decimal digit.
int unicodeDigitValue(int codePoint) {
  if (codePoint >= 0x30 && codePoint <= 0x39) return codePoint - 0x30;
  for (final zero in unicodeDigitZeros) {
    if (codePoint >= zero && codePoint <= zero + 9) return codePoint - zero;
  }
  return -1;
}
