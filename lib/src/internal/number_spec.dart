/// The pieces of `java.text.DecimalFormat` that parsing actually needs.
///
/// Dart's `intl` cannot stand in for `NumberFormat` here: its `parse` returns
/// only `double`, so `9223372036854775807` comes back having already lost
/// precision, and it exposes neither a parse position nor a pattern to mutate.
/// So `intl` is used for locale *symbol and pattern data* only, and the parsing
/// is done by [parseDecimal] against this specification.
library;

import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

/// Which flavour of number format to build, mirroring
/// `AbstractNumberValidator`'s format-type constants.
enum NumberFormatType {
  /// A plain decimal format.
  standard,

  /// A currency format, which requires the currency symbol to be present.
  currency,

  /// A percent format, whose value is divided by 100.
  percent,
}

/// A resolved, immutable description of a number format.
class NumberSpec {
  /// Creates a specification. Prefer [NumberSpec.forLocale] or
  /// [NumberSpec.forPattern].
  const NumberSpec({
    required this.decimalSeparator,
    required this.groupingSeparator,
    required this.minusSign,
    required this.exponentSeparator,
    required this.positivePrefix,
    required this.positiveSuffix,
    required this.negativePrefix,
    required this.negativeSuffix,
    required this.multiplier,
    required this.minimumFractionDigits,
    required this.maximumFractionDigits,
    required this.formatType,
    required this.locale,
    this.parseIntegerOnly = false,
  });

  /// The format for [locale], of the given [formatType].
  ///
  /// A null [locale] resolves to `Intl.defaultLocale` and then to the system
  /// locale, which is the nearest Dart has to Java's `Locale.getDefault()`.
  factory NumberSpec.forLocale(
    String? locale, {
    NumberFormatType formatType = NumberFormatType.standard,
    bool parseIntegerOnly = false,
  }) {
    final resolved = resolveNumberLocale(locale);
    final symbols = _symbolsFor(resolved);
    final pattern = switch (formatType) {
      NumberFormatType.currency => symbols.CURRENCY_PATTERN,
      NumberFormatType.percent => symbols.PERCENT_PATTERN,
      NumberFormatType.standard => symbols.DECIMAL_PATTERN,
    };
    final spec = _fromPattern(
      pattern,
      symbols,
      resolved,
      formatType,
      parseIntegerOnly: parseIntegerOnly,
      currencySymbol: formatType == NumberFormatType.currency
          ? _currencySymbolFor(resolved)
          : null,
    );
    if (formatType != NumberFormatType.currency) return spec;
    // A currency's fraction-digit count comes from the currency itself, not the
    // locale's generic pattern: Java's ja_JP currency pattern is `¤#,##0` because
    // the yen has no minor unit. `intl` keeps that in `decimalDigits`, and it
    // matters because `determineScale` truncates the result to it.
    final digits =
        NumberFormat.simpleCurrency(locale: resolved).decimalDigits ??
            spec.minimumFractionDigits;
    return spec.withFractionDigits(digits);
  }

  /// The format described by an explicit `DecimalFormat` [pattern].
  factory NumberSpec.forPattern(
    String pattern,
    String? locale, {
    bool parseIntegerOnly = false,
  }) {
    final resolved = resolveNumberLocale(locale);
    return _fromPattern(
      pattern,
      _symbolsFor(resolved),
      resolved,
      NumberFormatType.standard,
      parseIntegerOnly: parseIntegerOnly,
      currencySymbol: _currencySymbolFor(resolved),
    );
  }

  /// The character separating the integer and fraction parts.
  final String decimalSeparator;

  /// The grouping separator, which parsing accepts anywhere between digits.
  ///
  /// Often a non-breaking space: U+202F for `fr`, U+00A0 for `ru`. This is why
  /// the port trims with `javaTrim` rather than [String.trim].
  final String groupingSeparator;

  /// The minus sign, which is U+2212 rather than a hyphen in some locales.
  final String minusSign;

  /// The exponent marker, normally `E`.
  final String exponentSeparator;

  /// Text required before a positive number, usually empty.
  final String positivePrefix;

  /// Text required after a positive number, usually empty.
  final String positiveSuffix;

  /// Text required before a negative number.
  final String negativePrefix;

  /// Text required after a negative number.
  final String negativeSuffix;

  /// The value the parsed number is divided by: 100 for percent, 1000 for
  /// per-mille, otherwise 1.
  final int multiplier;

  /// The minimum fraction digits the pattern asks for, used by `determineScale`.
  final int minimumFractionDigits;

  /// The maximum fraction digits the pattern asks for.
  ///
  /// Note this does *not* limit what parsing accepts: Java parses `12.5%` under
  /// a zero-fraction-digit percent format.
  final int maximumFractionDigits;

  /// Which flavour this specification describes.
  final NumberFormatType formatType;

  /// The resolved locale this specification came from.
  final String locale;

  /// Whether parsing stops at the decimal separator.
  ///
  /// This mirrors `NumberFormat.setParseIntegerOnly`, including its quirk that
  /// an *exponent* is still parsed - so `15E-1` yields 1.5 even here.
  final bool parseIntegerOnly;

  /// A copy with both fraction-digit counts replaced.
  NumberSpec withFractionDigits(int digits) => NumberSpec(
        decimalSeparator: decimalSeparator,
        groupingSeparator: groupingSeparator,
        minusSign: minusSign,
        exponentSeparator: exponentSeparator,
        positivePrefix: positivePrefix,
        positiveSuffix: positiveSuffix,
        negativePrefix: negativePrefix,
        negativeSuffix: negativeSuffix,
        multiplier: multiplier,
        minimumFractionDigits: digits,
        maximumFractionDigits: digits,
        formatType: formatType,
        locale: locale,
        parseIntegerOnly: parseIntegerOnly,
      );

  /// A copy of this specification with [parseIntegerOnly] set.
  NumberSpec withParseIntegerOnly(bool value) => NumberSpec(
        decimalSeparator: decimalSeparator,
        groupingSeparator: groupingSeparator,
        minusSign: minusSign,
        exponentSeparator: exponentSeparator,
        positivePrefix: positivePrefix,
        positiveSuffix: positiveSuffix,
        negativePrefix: negativePrefix,
        negativeSuffix: negativeSuffix,
        multiplier: multiplier,
        minimumFractionDigits: minimumFractionDigits,
        maximumFractionDigits: maximumFractionDigits,
        formatType: formatType,
        locale: locale,
        parseIntegerOnly: value,
      );

  /// A copy with the currency or percent symbol removed from its affixes.
  ///
  /// `CurrencyValidator` and `PercentValidator` retry a failed parse this way,
  /// which upstream does by rewriting the `DecimalFormat` pattern - an API
  /// `intl` does not offer.
  NumberSpec withoutSymbol(String symbol) {
    String strip(String affix) {
      if (!affix.contains(symbol)) return affix;
      var result = affix.replaceAll(symbol, '');
      // Suffix locales separate the symbol from the number with a space, often a
      // non-breaking one; drop it along with the symbol.
      while (result.isNotEmpty && _isSpace(result.codeUnitAt(0))) {
        result = result.substring(1);
      }
      while (
          result.isNotEmpty && _isSpace(result.codeUnitAt(result.length - 1))) {
        result = result.substring(0, result.length - 1);
      }
      return result;
    }

    return NumberSpec(
      decimalSeparator: decimalSeparator,
      groupingSeparator: groupingSeparator,
      minusSign: minusSign,
      exponentSeparator: exponentSeparator,
      positivePrefix: strip(positivePrefix),
      positiveSuffix: strip(positiveSuffix),
      negativePrefix: strip(negativePrefix),
      negativeSuffix: strip(negativeSuffix),
      // Stripping the percent sign also drops its multiplier, as it does
      // upstream when the pattern is rewritten.
      multiplier: symbol == '%' || symbol == '‰' ? 1 : multiplier,
      minimumFractionDigits: minimumFractionDigits,
      maximumFractionDigits: maximumFractionDigits,
      formatType: formatType,
      locale: locale,
      parseIntegerOnly: parseIntegerOnly,
    );
  }

  static bool _isSpace(int c) =>
      c == 0x20 || c == 0xA0 || c == 0x202F || c == 0x2007;

  static NumberSymbols _symbolsFor(String locale) =>
      numberFormatSymbols[locale] as NumberSymbols;

  static String _currencySymbolFor(String locale) =>
      NumberFormat.simpleCurrency(locale: locale).currencySymbol;

  static NumberSpec _fromPattern(
    String pattern,
    NumberSymbols symbols,
    String locale,
    NumberFormatType formatType, {
    required bool parseIntegerOnly,
    String? currencySymbol,
  }) {
    final parsed = _PatternParts.parse(pattern);
    String expand(String affix) => affix
        .replaceAll('¤', currencySymbol ?? '')
        .replaceAll('%', symbols.PERCENT)
        .replaceAll('‰', symbols.PERMILL);

    final positivePrefix = expand(parsed.prefix);
    final positiveSuffix = expand(parsed.suffix);
    return NumberSpec(
      decimalSeparator: symbols.DECIMAL_SEP,
      groupingSeparator: symbols.GROUP_SEP,
      minusSign: symbols.MINUS_SIGN,
      exponentSeparator: symbols.EXP_SYMBOL,
      positivePrefix: positivePrefix,
      positiveSuffix: positiveSuffix,
      // Java derives the negative affixes from the pattern's second subpattern,
      // defaulting to the minus sign in front of the positive prefix.
      negativePrefix: parsed.negativePrefix == null
          ? '${symbols.MINUS_SIGN}$positivePrefix'
          : expand(parsed.negativePrefix!),
      negativeSuffix: parsed.negativeSuffix == null
          ? positiveSuffix
          : expand(parsed.negativeSuffix!),
      multiplier: parsed.multiplier,
      minimumFractionDigits: parsed.minFractionDigits,
      maximumFractionDigits: parsed.maxFractionDigits,
      formatType: formatType,
      locale: locale,
      parseIntegerOnly: parseIntegerOnly,
    );
  }
}

/// Resolves [locale] to a key that `intl`'s symbol tables actually hold.
///
/// Tries the canonical form, then the bare language, then `en_US`, which is what
/// `intl` does internally.
String resolveNumberLocale(String? locale) {
  final candidate = locale ?? Intl.defaultLocale ?? Intl.systemLocale;
  final canonical = Intl.canonicalizedLocale(candidate);
  if (numberFormatSymbols.containsKey(canonical)) return canonical;
  final underscore = canonical.indexOf('_');
  if (underscore > 0) {
    final language = canonical.substring(0, underscore);
    if (numberFormatSymbols.containsKey(language)) return language;
  }
  return 'en_US';
}

/// The affixes, multiplier and fraction-digit counts of a `DecimalFormat`
/// pattern.
class _PatternParts {
  const _PatternParts({
    required this.prefix,
    required this.suffix,
    required this.negativePrefix,
    required this.negativeSuffix,
    required this.multiplier,
    required this.minFractionDigits,
    required this.maxFractionDigits,
  });

  final String prefix;
  final String suffix;
  final String? negativePrefix;
  final String? negativeSuffix;
  final int multiplier;
  final int minFractionDigits;
  final int maxFractionDigits;

  /// Splits a pattern into its positive and optional negative subpatterns and
  /// reads the affixes and digit counts out of each.
  static _PatternParts parse(String pattern) {
    final subpatterns = _splitSubpatterns(pattern);
    final positive = _parseOne(subpatterns.first);
    final negative = subpatterns.length > 1 ? _parseOne(subpatterns[1]) : null;
    return _PatternParts(
      prefix: positive.prefix,
      suffix: positive.suffix,
      negativePrefix: negative?.prefix,
      negativeSuffix: negative?.suffix,
      multiplier: positive.multiplier,
      minFractionDigits: positive.minFraction,
      maxFractionDigits: positive.maxFraction,
    );
  }

  /// Splits on an unquoted `;`.
  static List<String> _splitSubpatterns(String pattern) {
    var quoted = false;
    for (var i = 0; i < pattern.length; i++) {
      final c = pattern[i];
      if (c == "'") {
        quoted = !quoted;
      } else if (c == ';' && !quoted) {
        return [pattern.substring(0, i), pattern.substring(i + 1)];
      }
    }
    return [pattern];
  }

  static _OneSubpattern _parseOne(String subpattern) {
    final prefix = StringBuffer();
    final suffix = StringBuffer();
    var multiplier = 1;
    var minFraction = 0;
    var maxFraction = 0;
    var seenNumber = false;
    var afterNumber = false;
    var inFraction = false;
    var quoted = false;

    for (var i = 0; i < subpattern.length; i++) {
      final c = subpattern[i];
      if (c == "'") {
        quoted = !quoted;
        continue;
      }
      final isNumeric =
          !quoted && (c == '#' || c == '0' || c == '.' || c == ',' || c == 'E');
      if (isNumeric) {
        seenNumber = true;
        if (c == '.') {
          inFraction = true;
        } else if (inFraction && c == '0') {
          minFraction++;
          maxFraction++;
        } else if (inFraction && c == '#') {
          maxFraction++;
        }
        continue;
      }
      if (!quoted && (c == '%' || c == '‰')) {
        multiplier = c == '%' ? 100 : 1000;
      }
      if (seenNumber) {
        afterNumber = true;
      }
      (afterNumber ? suffix : prefix).write(c);
    }

    return _OneSubpattern(
      prefix: prefix.toString(),
      suffix: suffix.toString(),
      multiplier: multiplier,
      minFraction: minFraction,
      maxFraction: maxFraction,
    );
  }
}

class _OneSubpattern {
  const _OneSubpattern({
    required this.prefix,
    required this.suffix,
    required this.multiplier,
    required this.minFraction,
    required this.maxFraction,
  });

  final String prefix;
  final String suffix;
  final int multiplier;
  final int minFraction;
  final int maxFraction;
}
