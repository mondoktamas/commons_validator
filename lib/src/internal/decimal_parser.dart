/// A locale-aware numeric parser with an explicit parse position.
///
/// Replaces the `java.text.NumberFormat.parseObject(value, ParsePosition)` call
/// that the whole `AbstractFormatValidator` hierarchy is built on. Two things
/// forced writing this rather than delegating to `intl`:
///
/// * `intl`'s `NumberFormat.parse` returns only `double`, so it has already lost
///   precision for anything past 2^53 - `9223372036854775807` comes back as
///   `9.223372036854776e18`. `BigIntegerValidator` and `BigDecimalValidator`
///   cannot be built on that.
/// * It exposes no parse position, and the validators' `strict` flag is defined
///   entirely in terms of one: a parse error always fails, but *leftover input*
///   fails only when strict.
library;

import 'package:decimal/decimal.dart';

import 'number_spec.dart';
import 'unicode_digits.dart';

/// The largest decimal scale [parseDecimal] will materialise.
///
/// `Decimal` is backed by a rational, so a scale of n means building a BigInt
/// with n digits: `1E20000000` would take minutes and hundreds of megabytes.
/// Java never pays that, because `BigDecimal` keeps an `int` scale alongside its
/// unscaled value and only expands on demand.
///
/// The cost is roughly quadratic - measured at 3 ms for a scale of 1024, 22 ms
/// for 4096 and 87 ms for 8192 - so the bound is deliberately tight. No real
/// decimal input has a scale over a thousand: a `double` tops out around
/// 1e-324, and monetary and scientific data never come close.
const int maxDecimalScale = 1024;

/// Whether a parsed value fitted inside [maxDecimalScale].
enum NumberMagnitude {
  /// The value was materialised exactly.
  normal,

  /// The exponent was too large to materialise; the value is beyond any finite
  /// double.
  overflow,

  /// The exponent was too small to materialise; the value rounds to zero.
  underflow,
}

/// The outcome of a successful parse.
class NumberParseResult {
  /// Creates a result.
  const NumberParseResult({
    required this.value,
    required this.doubleValue,
    required this.consumed,
    required this.sawFractionDigits,
    required this.sawExponent,
    required this.negative,
    this.magnitude = NumberMagnitude.normal,
  });

  /// The parsed value, exact to arbitrary precision.
  ///
  /// Zero when [magnitude] is not [NumberMagnitude.normal], in which case the
  /// real value was too extreme to build and the caller must decide what to do.
  final Decimal value;

  /// The value as a `double`, always exact to double precision.
  ///
  /// Computed straight from the digit string with [double.parse] rather than
  /// through [value], for two reasons: `Decimal.toDouble` silently flushes
  /// subnormals to zero (`1E-320` becomes `0.0` where Java gives `1.0E-320`),
  /// and this stays correct for the extreme exponents [value] declines to
  /// materialise - `double.parse` answers infinity or zero for those in
  /// microseconds, exactly as Java does.
  final double doubleValue;

  /// Whether [value] is exact, or stood in for something unrepresentable.
  final NumberMagnitude magnitude;

  /// How many characters were consumed, which is `ParsePosition.getIndex()`.
  final int consumed;

  /// Whether any digits followed the decimal separator.
  final bool sawFractionDigits;

  /// Whether an exponent was consumed.
  final bool sawExponent;

  /// Whether a negative sign or negative affix was matched.
  ///
  /// Needed to tell `-0` from `0`: Java yields `Double -0.0` for the former when
  /// fractions are allowed.
  final bool negative;
}

/// Parses [input] according to [spec], or returns null if it does not parse.
///
/// Returning null corresponds to `ParsePosition.getErrorIndex()` being set;
/// a shorter [NumberParseResult.consumed] than `input.length` corresponds to
/// leftover input, which only a strict validator rejects.
NumberParseResult? parseDecimal(String input, NumberSpec spec) {
  if (input.isEmpty) return null;

  var index = 0;
  var negative = false;

  // Java tries the negative affix first, so that a negative prefix which
  // extends the positive one (`-$` against `$`) wins.
  if (spec.negativePrefix.isNotEmpty &&
      input.startsWith(spec.negativePrefix, index)) {
    negative = true;
    index += spec.negativePrefix.length;
  } else if (spec.positivePrefix.isNotEmpty &&
      input.startsWith(spec.positivePrefix, index)) {
    index += spec.positivePrefix.length;
  } else if (spec.positivePrefix.isNotEmpty) {
    // The positive prefix is required when the pattern has one. This is why
    // `1,234.56` fails a currency format, and why CurrencyValidator retries
    // without the symbol. A non-matching *negative* prefix is not an error - it
    // just means the number is not negative.
    return null;
  }

  // A bare minus sign is accepted even when the negative prefix did not match,
  // which covers patterns whose negative subpattern is only the sign.
  if (!negative && input.startsWith(spec.minusSign, index)) {
    negative = true;
    index += spec.minusSign.length;
  }

  final digits = StringBuffer();
  var integerDigits = 0;
  var fractionDigits = 0;
  var sawFraction = false;
  var sawExponent = false;
  var exponent = 0;

  // Integer part, with grouping separators allowed between digits.
  while (index < input.length) {
    final digit = unicodeDigitValue(input.codeUnitAt(index));
    if (digit >= 0) {
      digits.write(digit);
      integerDigits++;
      index++;
    } else if (spec.groupingUsed &&
        spec.groupingSeparator.isNotEmpty &&
        integerDigits > 0 &&
        input.startsWith(spec.groupingSeparator, index)) {
      // Java does not check grouping placement, so `1,2,3,4` parses as 1234.
      index += spec.groupingSeparator.length;
    } else {
      break;
    }
  }

  // Fraction part. Under parseIntegerOnly the separator itself is not consumed,
  // which is what makes `1234.5` parse as 1234 with two characters left over.
  if (!spec.parseIntegerOnly &&
      input.startsWith(spec.decimalSeparator, index)) {
    final afterSeparator = index + spec.decimalSeparator.length;
    var cursor = afterSeparator;
    final fraction = StringBuffer();
    while (cursor < input.length) {
      final digit = unicodeDigitValue(input.codeUnitAt(cursor));
      if (digit < 0) break;
      fraction.write(digit);
      cursor++;
    }
    // A trailing separator with no digits is still consumed, as Java does:
    // `1234.` parses to 1234 having consumed five characters.
    if (integerDigits > 0 || fraction.isNotEmpty) {
      index = cursor;
      sawFraction = fraction.isNotEmpty;
      fractionDigits = fraction.length;
      digits.write(fraction);
    }
  }

  // No digits at all.
  if (integerDigits == 0 && fractionDigits == 0) {
    return null;
  }

  // Exponent. Java parses this even under parseIntegerOnly, which is why
  // `15E-1` yields a fractional 1.5 there and BigIntegerValidator needs its own
  // guard against exactly that.
  if (spec.exponentSeparator.isNotEmpty &&
      input.startsWith(spec.exponentSeparator, index)) {
    var cursor = index + spec.exponentSeparator.length;
    var expNegative = false;
    // Java accepts only a minus sign here - a leading `+` is *not* consumed, so
    // `1E+3` parses as 1 with `E+3` left over rather than as 1000.
    if (cursor < input.length && input.startsWith(spec.minusSign, cursor)) {
      expNegative = true;
      cursor += spec.minusSign.length;
    }
    final expDigits = StringBuffer();
    while (cursor < input.length) {
      final digit = unicodeDigitValue(input.codeUnitAt(cursor));
      if (digit < 0) break;
      expDigits.write(digit);
      cursor++;
    }
    if (expDigits.isNotEmpty) {
      exponent = int.parse(expDigits.toString()) * (expNegative ? -1 : 1);
      sawExponent = true;
      index = cursor;
    }
  }

  // Suffix, chosen to match the sign already established.
  final suffix = negative ? spec.negativeSuffix : spec.positiveSuffix;
  if (suffix.isNotEmpty) {
    if (!input.startsWith(suffix, index)) return null;
    index += suffix.length;
  }

  // The double is read straight from the digits, so it is right even where the
  // Decimal below is not built.
  var doubleValue = double.parse(
      '${negative ? '-' : ''}${digits}e${exponent - fractionDigits}');
  if (spec.multiplier != 1) doubleValue /= spec.multiplier;

  // Refuse to materialise an absurd scale. Everything else about the parse is
  // already known, so report the magnitude and let the leaf validator decide -
  // the double-returning ones can still answer infinity or zero, as Java does.
  final scale = fractionDigits - exponent;
  if (scale.abs() > maxDecimalScale) {
    return NumberParseResult(
      value: Decimal.zero,
      doubleValue: doubleValue,
      consumed: index,
      sawFractionDigits: sawFraction || (sawExponent && exponent < 0),
      sawExponent: sawExponent,
      negative: negative,
      magnitude:
          scale < 0 ? NumberMagnitude.overflow : NumberMagnitude.underflow,
    );
  }

  var value = _buildDecimal(
    digits.toString(),
    fractionDigits: fractionDigits,
    exponent: exponent,
  );
  if (negative) value = -value;
  if (spec.multiplier != 1) {
    value = (value / Decimal.fromInt(spec.multiplier)).toDecimal();
  }

  return NumberParseResult(
    value: value,
    doubleValue: doubleValue,
    consumed: index,
    sawFractionDigits: sawFraction || (sawExponent && exponent < 0),
    sawExponent: sawExponent,
    negative: negative,
  );
}

/// Assembles the digit string into an exact [Decimal].
Decimal _buildDecimal(
  String digits, {
  required int fractionDigits,
  required int exponent,
}) {
  final mantissa = digits.isEmpty ? BigInt.zero : BigInt.parse(digits);
  final scale = fractionDigits - exponent;
  if (scale == 0) return Decimal.fromBigInt(mantissa);
  if (scale > 0) {
    return (Decimal.fromBigInt(mantissa) /
            Decimal.fromBigInt(BigInt.from(10).pow(scale)))
        .toDecimal();
  }
  return Decimal.fromBigInt(mantissa * BigInt.from(10).pow(-scale));
}
