/// The formatting counterpart to [parseDecimal].
///
/// Java's validators inherit a `format` family from `AbstractFormatValidator`,
/// which delegates to the same `DecimalFormat` used for parsing. Formatting is
/// done here rather than through `intl` for the same reason parsing is: `intl`
/// only accepts `num`, so any `Decimal` past double precision would be rounded
/// before it was ever formatted.
library;

import 'package:decimal/decimal.dart';

import 'number_spec.dart';

/// Formats [value] according to [spec].
///
/// Digits are grouped, the fraction is padded to
/// [NumberSpec.minimumFractionDigits] and rounded half-even to
/// [NumberSpec.maximumFractionDigits], and the sign-appropriate affixes are
/// applied - matching `DecimalFormat`'s defaults.
String formatDecimal(Decimal value, NumberSpec spec) {
  var scaled = value;
  if (spec.multiplier != 1) {
    scaled = value * Decimal.fromInt(spec.multiplier);
  }

  final negative = scaled.sign < 0;
  final magnitude = negative ? -scaled : scaled;
  final rounded = _roundHalfEven(magnitude, spec.maximumFractionDigits);

  final digits = rounded.toString();
  final dot = digits.indexOf('.');
  var integerPart = dot < 0 ? digits : digits.substring(0, dot);
  var fractionPart = dot < 0 ? '' : digits.substring(dot + 1);

  // Pad or trim the fraction to the pattern's bounds.
  if (fractionPart.length < spec.minimumFractionDigits) {
    fractionPart = fractionPart.padRight(spec.minimumFractionDigits, '0');
  }
  if (fractionPart.length > spec.maximumFractionDigits) {
    fractionPart = fractionPart.substring(0, spec.maximumFractionDigits);
  }

  integerPart = _group(integerPart, spec.groupingSeparator);

  final buffer = StringBuffer()
    ..write(negative ? spec.negativePrefix : spec.positivePrefix)
    ..write(integerPart);
  if (fractionPart.isNotEmpty) {
    buffer
      ..write(spec.decimalSeparator)
      ..write(fractionPart);
  }
  buffer.write(negative ? spec.negativeSuffix : spec.positiveSuffix);
  return buffer.toString();
}

/// Inserts [separator] every three digits from the right.
String _group(String integerDigits, String separator) {
  if (separator.isEmpty || integerDigits.length <= 3) return integerDigits;
  final out = StringBuffer();
  final lead = integerDigits.length % 3;
  if (lead > 0) out.write(integerDigits.substring(0, lead));
  for (var i = lead; i < integerDigits.length; i += 3) {
    if (out.isNotEmpty) out.write(separator);
    out.write(integerDigits.substring(i, i + 3));
  }
  return out.toString();
}

/// Rounds a non-negative [value] to [scale] places, half away from even.
///
/// `DecimalFormat` rounds HALF_EVEN by default, so 2.5 formats as 2 and 3.5 as 4
/// under a zero-decimal pattern.
Decimal _roundHalfEven(Decimal value, int scale) {
  final factor = Decimal.fromBigInt(BigInt.from(10).pow(scale));
  final shifted = value * factor;
  final floor = shifted.floor();
  final remainder = shifted - floor;
  final half = Decimal.parse('0.5');
  BigInt result;
  if (remainder > half) {
    result = floor.toBigInt() + BigInt.one;
  } else if (remainder < half) {
    result = floor.toBigInt();
  } else {
    // Exactly a half: round to the even neighbour.
    final f = floor.toBigInt();
    result = f.isEven ? f : f + BigInt.one;
  }
  return (Decimal.fromBigInt(result) / factor)
      .toDecimal(scaleOnInfinitePrecision: scale);
}
