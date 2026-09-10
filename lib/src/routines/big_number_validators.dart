import 'package:decimal/decimal.dart';

import '../generic_validator.dart';
import '../internal/decimal_parser.dart';
import '../internal/java_compat.dart';
import '../internal/number_spec.dart';
import 'abstract_number_validator.dart';

/// Validates that a string is a valid arbitrary-precision decimal.
///
/// Ported from `org.apache.commons.validator.routines.BigDecimalValidator`.
/// `java.math.BigDecimal` becomes `Decimal` from `package:decimal`.
///
/// A strict validator truncates the result to the pattern's scale using
/// truncation toward zero, matching Java's `setScale(scale, ROUND_DOWN)` - so
/// `1234.567` under a two-decimal-place format becomes `1234.56`, not `1234.57`.
class BigDecimalValidator extends AbstractNumberValidator<Decimal> {
  /// Creates a validator.
  ///
  /// [strict] requires the whole input to be consumed; [allowFractions]
  /// permits a fraction part.
  const BigDecimalValidator({
    super.strict = true,
    super.formatType = NumberFormatType.standard,
    super.allowFractions = true,
  });

  static const BigDecimalValidator _instance = BigDecimalValidator();

  /// The shared strict instance.
  static BigDecimalValidator getInstance() => _instance;

  @override
  Decimal? processParsedValue(NumberParseResult result, NumberSpec spec) {
    // Deliberate divergence: Java answers `1E+20000000` here, because
    // BigDecimal stores an unscaled value plus an int scale and never expands.
    // `Decimal` is rational-backed, so materialising that costs minutes and
    // hundreds of megabytes - a denial of service on any untrusted input. See
    // maxDecimalScale.
    if (result.magnitude != NumberMagnitude.normal) return null;
    final scale = determineScale(spec);
    return scale >= 0 ? truncateToScale(result.value, scale) : result.value;
  }

  /// Whether [value] is between [min] and [max] inclusive.
  bool isInRange(Decimal value, Decimal min, Decimal max) =>
      minValue(value, min) && maxValue(value, max);

  /// Whether [value] is at least [min], compared exactly.
  bool minValue(Decimal value, Decimal min) => value >= min;

  /// Whether [value] is at most [max], compared exactly.
  bool maxValue(Decimal value, Decimal max) => value <= max;
}

/// Validates that a string is a valid arbitrary-precision integer.
///
/// Ported from `org.apache.commons.validator.routines.BigIntegerValidator`.
///
/// The explicit fraction guard is upstream's and is needed because
/// `parseIntegerOnly` does not stop at an *exponent*: `15E-1` parses to 1.5 even
/// under an integer-only format, and only this check rejects it.
class BigIntegerValidator extends AbstractNumberValidator<BigInt> {
  /// Creates a validator. [strict] requires the whole input to be consumed.
  const BigIntegerValidator({super.strict = true})
      : super(
          formatType: NumberFormatType.standard,
          allowFractions: false,
        );

  static const BigIntegerValidator _instance = BigIntegerValidator();

  /// The shared strict instance.
  static BigIntegerValidator getInstance() => _instance;

  @override
  BigInt? processParsedValue(NumberParseResult result, NumberSpec spec) {
    // Rejected rather than expanded. Upstream is no better here: Java's
    // BigIntegerValidator materialises `1E1000000` into a 1,000,001-digit
    // BigInteger rather than declining.
    if (result.magnitude != NumberMagnitude.normal) return null;
    final value = result.value;
    // Upstream guards with `signum() != 0` because BigDecimal.ZERO historically
    // misreported its stripped scale; comparing against zero here is equivalent.
    if (value.sign != 0 && !value.isInteger) return null;
    return value.toBigInt();
  }

  /// Whether [value] is between [min] and [max] inclusive.
  bool isInRange(BigInt value, BigInt min, BigInt max) =>
      minValue(value, min) && maxValue(value, max);

  /// Whether [value] is at least [min].
  bool minValue(BigInt value, BigInt min) => value >= min;

  /// Whether [value] is at most [max].
  bool maxValue(BigInt value, BigInt max) => value <= max;
}

/// Validates that a string is a valid currency amount.
///
/// Ported from `org.apache.commons.validator.routines.CurrencyValidator`.
///
/// A locale currency format *requires* its symbol, so `1,234.56` fails an
/// `en_US` currency format outright. Upstream therefore retries with the symbol
/// removed from the pattern; since `intl` offers no pattern mutation, the retry
/// here rebuilds the specification without the symbol instead.
class CurrencyValidator extends BigDecimalValidator {
  /// Creates a validator.
  const CurrencyValidator({super.strict = true, super.allowFractions = true})
      : super(formatType: NumberFormatType.currency);

  /// The placeholder Java patterns use for the currency symbol.
  static const String currencyPlaceholder = '¤';

  static const CurrencyValidator _instance = CurrencyValidator();

  /// The shared strict instance.
  static CurrencyValidator getInstance() => _instance;

  @override
  Decimal? parse(String? value, {String? pattern, String? locale}) {
    final direct = super.parse(value, pattern: pattern, locale: locale);
    if (direct != null) return direct;
    // Retry without the currency symbol.
    final trimmed = value == null ? null : javaTrim(value);
    if (GenericValidator.isBlankOrNull(trimmed)) return null;
    final spec = specFor(pattern: pattern, locale: locale);
    final symbol = _symbolOf(spec);
    if (symbol.isEmpty) return null;
    final relaxed = spec.withoutSymbol(symbol);
    final result = parseDecimal(trimmed!, relaxed);
    if (result == null) return null;
    if (strict && result.consumed < trimmed.length) return null;
    return processParsedValue(result, relaxed);
  }

  /// The currency symbol appearing in this specification's affixes.
  static String _symbolOf(NumberSpec spec) {
    for (final affix in [spec.positivePrefix, spec.positiveSuffix]) {
      final symbol = affix.replaceAll(RegExp(r'[\s  ]'), '');
      if (symbol.isNotEmpty) return symbol;
    }
    return '';
  }
}

/// Validates that a string is a valid percentage.
///
/// Ported from `org.apache.commons.validator.routines.PercentValidator`.
///
/// As with [CurrencyValidator], a locale percent format requires its `%`, so a
/// bare `12` fails and is retried without it. Note the retry also loses the
/// pattern's multiplier, so upstream multiplies the result by 0.01 by hand; the
/// same correction is applied here.
class PercentValidator extends BigDecimalValidator {
  /// Creates a validator.
  const PercentValidator({super.strict = true})
      : super(formatType: NumberFormatType.percent);

  /// The percent sign as it appears in Java patterns.
  static const String percentSymbol = '%';

  static final Decimal _pointZeroOne = Decimal.parse('0.01');

  static const PercentValidator _instance = PercentValidator();

  /// The shared strict instance.
  static PercentValidator getInstance() => _instance;

  @override
  Decimal? parse(String? value, {String? pattern, String? locale}) {
    final direct = super.parse(value, pattern: pattern, locale: locale);
    if (direct != null) return direct;
    final trimmed = value == null ? null : javaTrim(value);
    if (GenericValidator.isBlankOrNull(trimmed)) return null;
    final spec = specFor(pattern: pattern, locale: locale);
    if (!spec.positivePrefix.contains(percentSymbol) &&
        !spec.positiveSuffix.contains(percentSymbol)) {
      return null;
    }
    final relaxed = spec.withoutSymbol(percentSymbol);
    final result = parseDecimal(trimmed!, relaxed);
    if (result == null) return null;
    if (strict && result.consumed < trimmed.length) return null;
    final parsed = processParsedValue(result, relaxed);
    // Dropping the '%' also dropped the x100 multiplier, so scale by hand.
    return parsed == null ? null : parsed * _pointZeroOne;
  }
}
