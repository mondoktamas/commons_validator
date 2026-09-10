import '../generic_validator.dart';
import 'checkdigit/check_digit.dart';
import 'checkdigit/luhn_check_digit.dart';
import 'code_validator.dart';
import 'regex_validator.dart';

/// A contiguous range of card prefixes, together with the lengths it allows.
///
/// Ported from `CreditCardValidator.CreditCardRange`.
class CreditCardRange {
  /// A range from [low] to [high] inclusive, accepting lengths [minLen]-[maxLen].
  ///
  /// Pass null for [high] to match the single prefix [low].
  const CreditCardRange(this.low, this.high, this.minLen, this.maxLen)
      : lengths = null;

  /// A range from [low] to [high] inclusive, accepting only the given [lengths].
  const CreditCardRange.withLengths(this.low, this.high, this.lengths)
      : minLen = -1,
        maxLen = -1;

  /// The low prefix, e.g. `34` or `644`.
  final String low;

  /// The high prefix, e.g. `34` or `65`, or null for a single-prefix range.
  final String? high;

  /// The minimum length, or -1 when [lengths] is used instead.
  final int minLen;

  /// The maximum length, or -1 when [lengths] is used instead.
  final int maxLen;

  /// The exact lengths accepted, or null when [minLen]/[maxLen] are used.
  final List<int>? lengths;
}

/// Matches a card number against a set of [CreditCardRange]s.
///
/// Replaces the anonymous `RegexValidator` subclass in
/// `CreditCardValidator.createRangeValidator`. The `(\d+)` pattern is only a
/// digits-only gate; the range decision is made by prefix comparison.
class _CreditCardRangeValidator extends RegexValidator {
  _CreditCardRangeValidator(List<CreditCardRange> ranges)
      : _ranges = List<CreditCardRange>.unmodifiable(ranges),
        super(r'(\d+)');

  final List<CreditCardRange> _ranges;

  @override
  bool isValid(String? value) => validate(value) != null;

  @override
  List<String?>? match(String? value) => [validate(value)];

  @override
  String? validate(String? value) {
    if (value == null || super.match(value) == null) return null;
    for (final range in _ranges) {
      if (!_validLength(value.length, range)) continue;
      final high = range.high;
      if (high == null) {
        // Single prefix only.
        if (value.startsWith(range.low)) return value;
      } else if (range.low.compareTo(value) <= 0 &&
          high.compareTo(value.substring(0, high.length)) >= 0) {
        // Lexicographic prefix comparison, as upstream. Dart's compareTo
        // matches Java's for ASCII digits.
        return value;
      }
    }
    return null;
  }
}

bool _validLength(int valueLength, CreditCardRange range) {
  final lengths = range.lengths;
  if (lengths != null) return lengths.contains(valueLength);
  return valueLength >= range.minLen && valueLength <= range.maxLen;
}

/// Validates credit card numbers by brand prefix, length and Luhn check digit.
///
/// Ported from `org.apache.commons.validator.routines.CreditCardValidator`.
class CreditCardValidator {
  /// Creates a validator accepting the brands selected by [options].
  ///
  /// Defaults to Amex, Visa, Mastercard and Discover, matching upstream.
  CreditCardValidator([int options = amex | visa | mastercard | discover]) {
    if (_isOn(options, visa)) cardTypes.add(visaValidator);
    if (_isOn(options, vpay)) cardTypes.add(vpayValidator);
    if (_isOn(options, amex)) cardTypes.add(amexValidator);
    if (_isOn(options, mastercard)) cardTypes.add(mastercardValidator);
    if (_isOn(options, mastercardPreOct2016)) {
      cardTypes.add(mastercardValidatorPreOct2016);
    }
    if (_isOn(options, discover)) cardTypes.add(discoverValidator);
    if (_isOn(options, diners)) cardTypes.add(dinersValidator);
  }

  /// Creates a validator from an explicit list of [validators].
  CreditCardValidator.fromValidators(List<CodeValidator> validators) {
    cardTypes.addAll(validators);
  }

  /// Creates a validator from [ranges], with Luhn checking.
  CreditCardValidator.fromRanges(List<CreditCardRange> ranges) {
    cardTypes.add(createRangeValidator(ranges, _luhnValidator));
  }

  /// Creates a validator from both explicit [validators] and [ranges].
  CreditCardValidator.fromValidatorsAndRanges(
    List<CodeValidator> validators,
    List<CreditCardRange> ranges,
  ) {
    cardTypes
      ..addAll(validators)
      ..add(createRangeValidator(ranges, _luhnValidator));
  }

  static const int _minCcLength = 12;
  static const int _maxCcLength = 19;

  /// No card types.
  static const int none = 0;

  /// American Express.
  static const int amex = 1 << 0;

  /// Visa.
  static const int visa = 1 << 1;

  /// Mastercard, including the ranges added in October 2016.
  static const int mastercard = 1 << 2;

  /// Discover.
  static const int discover = 1 << 3;

  /// Diners Club.
  static const int diners = 1 << 4;

  /// VPay.
  static const int vpay = 1 << 5;

  /// Mastercard as it was before October 2016.
  @Deprecated('Use mastercard, which includes the 2016 ranges')
  static const int mastercardPreOct2016 = 1 << 6;

  static const CheckDigit _luhnValidator = LuhnCheckDigit.luhnCheckDigit;

  /// American Express card numbers.
  static final CodeValidator amexValidator = CodeValidator(
    r'^(3[47]\d{13})$',
    checkDigit: _luhnValidator,
  );

  /// Diners Club card numbers.
  static final CodeValidator dinersValidator = CodeValidator(
    r'^(30[0-5]\d{11}|3095\d{10}|36\d{12}|3[8-9]\d{12})$',
    checkDigit: _luhnValidator,
  );

  static final RegexValidator _discoverRegex = RegexValidator.fromList([
    r'^(6011\d{12,13})$',
    r'^(64[4-9]\d{13})$',
    r'^(65\d{14})$',
    r'^(62[2-8]\d{13})$',
  ]);

  /// Discover card numbers.
  static final CodeValidator discoverValidator =
      CodeValidator.fromRegexValidator(_discoverRegex,
          checkDigit: _luhnValidator);

  static final RegexValidator _mastercardRegex = RegexValidator.fromList([
    r'^(5[1-5]\d{14})$', // 51 - 55 (pre Oct 2016)
    r'^(2221\d{12})$', // 222100 - 222199
    r'^(222[2-9]\d{12})$', // 222200 - 222999
    r'^(22[3-9]\d{13})$', // 223000 - 229999
    r'^(2[3-6]\d{14})$', // 230000 - 269999
    r'^(27[01]\d{13})$', // 270000 - 271999
    r'^(2720\d{12})$', // 272000 - 272099
  ]);

  /// Mastercard card numbers, including the ranges added in October 2016.
  static final CodeValidator mastercardValidator =
      CodeValidator.fromRegexValidator(_mastercardRegex,
          checkDigit: _luhnValidator);

  /// Mastercard card numbers as they were before October 2016.
  @Deprecated('Use mastercardValidator, which includes the 2016 ranges')
  static final CodeValidator mastercardValidatorPreOct2016 = CodeValidator(
    r'^(5[1-5]\d{14})$',
    checkDigit: _luhnValidator,
  );

  /// Visa card numbers.
  static final CodeValidator visaValidator = CodeValidator(
    r'^(4)(\d{12}|\d{15})$',
    checkDigit: _luhnValidator,
  );

  /// VPay card numbers.
  static final CodeValidator vpayValidator = CodeValidator(
    r'^(4)(\d{12,18})$',
    checkDigit: _luhnValidator,
  );

  /// A validator built from [ranges], checked with [digitCheck].
  static CodeValidator createRangeValidator(
    List<CreditCardRange> ranges,
    CheckDigit digitCheck,
  ) =>
      CodeValidator.fromRegexValidator(
        _CreditCardRangeValidator(ranges),
        checkDigit: digitCheck,
      );

  /// A validator accepting any Luhn-valid number of length [minLen]-[maxLen].
  ///
  /// Both bounds default to the 12-19 range upstream uses.
  static CreditCardValidator generic({
    int minLen = _minCcLength,
    int maxLen = _maxCcLength,
  }) =>
      CreditCardValidator.fromValidators([
        CodeValidator(
          r'(\d+)',
          minLength: minLen,
          maxLength: maxLen,
          checkDigit: _luhnValidator,
        ),
      ]);

  /// Whether [valueLength] is acceptable for [range]. Exposed for testing.
  static bool validLength(int valueLength, CreditCardRange range) =>
      _validLength(valueLength, range);

  /// The card validators tried in order.
  final List<CodeValidator> cardTypes = [];

  static bool _isOn(int options, int flag) => (options & flag) > 0;

  /// Whether [card] is a valid number for any configured brand.
  bool isValid(String? card) {
    if (GenericValidator.isBlankOrNull(card)) return false;
    return cardTypes.any((t) => t.isValid(card));
  }

  /// The card number in normalised form, or null if it is not valid.
  String? validate(String? card) {
    if (GenericValidator.isBlankOrNull(card)) return null;
    for (final cardType in cardTypes) {
      final result = cardType.validate(card);
      if (result != null) return result;
    }
    return null;
  }
}
