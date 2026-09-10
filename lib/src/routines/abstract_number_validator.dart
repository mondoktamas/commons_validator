import 'package:decimal/decimal.dart';

import '../generic_validator.dart';
import '../internal/decimal_formatter.dart';
import '../internal/decimal_parser.dart';
import '../internal/java_compat.dart';
import '../internal/number_spec.dart';

export '../internal/number_spec.dart' show NumberFormatType;

/// Base class for the number validators.
///
/// Ported from `AbstractFormatValidator` and `AbstractNumberValidator`, which are
/// merged here because the format half has no other subclasses in the ported
/// scope.
///
/// The Java originals work in terms of `Object`, casting in each leaf. This port
/// is generic in [T] instead, so `IntegerValidator.parse` returns `int?` and
/// `BigDecimalValidator.parse` returns `Decimal?` without any casting.
///
/// **Locale handling differs deliberately.** Java reads
/// `Locale.getDefault()` whenever a null locale is passed, and upstream's tests
/// mutate that global. Dart has no mutable default locale of comparable weight,
/// so a null [locale] here resolves through `Intl.defaultLocale` and then the
/// system locale. Pass the locale explicitly for deterministic results.
abstract class AbstractNumberValidator<T> {
  /// Creates a validator.
  ///
  /// [strict] makes the whole input have to be consumed; [allowFractions]
  /// permits a fraction part; [formatType] selects plain, currency or percent
  /// formatting.
  const AbstractNumberValidator({
    required this.strict,
    required this.formatType,
    required this.allowFractions,
  });

  /// Whether the entire input must be consumed for the value to be valid.
  ///
  /// This is exactly the `ParsePosition` distinction upstream relies on: a parse
  /// *error* always fails, but leftover trailing input fails only when strict.
  /// So a lenient validator accepts `1234abc` as 1234.
  final bool strict;

  /// Whether a fraction part is permitted.
  final bool allowFractions;

  /// Whether this validator formats plain numbers, currency or percentages.
  final NumberFormatType formatType;

  /// Whether [value] is valid.
  bool isValid(String? value, {String? pattern, String? locale}) =>
      parse(value, pattern: pattern, locale: locale) != null;

  /// The parsed value, or null if [value] is not valid.
  T? parse(String? value, {String? pattern, String? locale}) {
    final trimmed = value == null ? null : javaTrim(value);
    if (GenericValidator.isBlankOrNull(trimmed)) return null;
    final spec = specFor(pattern: pattern, locale: locale);
    final result = parseDecimal(trimmed!, spec);
    if (result == null) return null;
    // The strict check: anything left over is a failure.
    if (strict && result.consumed < trimmed.length) return null;
    return processParsedValue(result, spec);
  }

  /// Formats [value] with the same specification the validator parses with.
  ///
  /// Ported from `AbstractFormatValidator`'s `format` family. Note the
  /// deliberate asymmetry with the date validators, which is upstream's: the
  /// number side throws on a null value where `AbstractCalendarValidator`
  /// returns null.
  ///
  /// [value] may be a [num], a [BigInt] or a [Decimal]; a [Decimal] is formatted
  /// exactly, without being rounded through a `double` first.
  String format(Object value, {String? pattern, String? locale}) {
    final spec = specFor(pattern: pattern, locale: locale);
    return formatDecimal(_toDecimal(value), spec);
  }

  static Decimal _toDecimal(Object value) => switch (value) {
        Decimal() => value,
        BigInt() => Decimal.fromBigInt(value),
        int() => Decimal.fromInt(value),
        double() => Decimal.parse(value.toString()),
        _ => throw ArgumentError.value(
            value,
            'value',
            'Expected a num, BigInt or Decimal',
          ),
      };

  /// The format specification for the given [pattern] and [locale].
  NumberSpec specFor({String? pattern, String? locale}) {
    final spec = (pattern == null || javaTrim(pattern).isEmpty)
        ? NumberSpec.forLocale(locale, formatType: formatType)
        : NumberSpec.forPattern(pattern, locale);
    return spec.withParseIntegerOnly(!allowFractions);
  }

  /// Converts a successful parse into the validator's own type, or null if the
  /// value is not acceptable after all.
  T? processParsedValue(NumberParseResult result, NumberSpec spec);

  /// The scale a strict validator should truncate its result to, or -1 for none.
  ///
  /// Ported from `AbstractNumberValidator.determineScale`.
  int determineScale(NumberSpec spec) {
    if (!strict) return -1;
    if (!allowFractions || spec.parseIntegerOnly) return 0;
    if (spec.minimumFractionDigits != spec.maximumFractionDigits) return -1;
    var scale = spec.minimumFractionDigits;
    if (spec.multiplier == 100) {
      scale += 2;
    } else if (spec.multiplier == 1000) {
      scale += 3;
    }
    return scale;
  }
}

/// Whether the exact [value] is an integer that fits in a signed 64-bit range.
///
/// This reproduces the type discrimination the Java validators depend on:
/// `NumberFormat.parse` hands back a `Long` when the value is integral and fits,
/// and a `Double` otherwise, and Byte/Short/Integer/Long reject by *type* rather
/// than by range. So `9223372036854775808` is rejected for arriving as a
/// `Double`, not for being out of bounds.
///
/// **On the web** Dart's `int` is a JavaScript double, so values above 2^53
/// cannot be represented exactly and this boundary behaves differently there.
bool fitsInJavaLong(Decimal value) {
  if (!value.isInteger) return false;
  final big = value.toBigInt();
  return big >= _minLong && big <= _maxLong;
}

final BigInt _minLong = BigInt.parse('-9223372036854775808');
final BigInt _maxLong = BigInt.parse('9223372036854775807');

/// Truncates [value] to [scale] decimal places, discarding the remainder.
///
/// Java uses `BigDecimal.setScale(scale, ROUND_DOWN)`, which truncates toward
/// zero rather than rounding.
Decimal truncateToScale(Decimal value, int scale) {
  if (scale < 0) return value;
  final factor = Decimal.fromBigInt(BigInt.from(10).pow(scale));
  final scaled = (value * factor).truncate();
  return (scaled / factor).toDecimal(scaleOnInfinitePrecision: scale);
}
