import '../internal/java_compat.dart';
import 'checkdigit/check_digit_exception.dart';
import 'checkdigit/ean13_check_digit.dart';
import 'checkdigit/issn_check_digit.dart';
import 'code_validator.dart';

/// Validates ISSN codes, and converts between ISSN and EAN-13.
///
/// Ported from `org.apache.commons.validator.routines.ISSNValidator`.
class ISSNValidator {
  /// Creates a validator.
  ISSNValidator();

  static final RegExp _digitDigit = RegExp(r'^\d\d$');

  /// The accepted ISSN shape, optionally prefixed with `ISSN `.
  ///
  /// Note upstream's pattern has a trailing `$` but no leading `^`. Under Java's
  /// `Matcher.matches()` that makes no difference, and [CodeValidator] anchors
  /// at the start too, so the behaviour is preserved.
  static const String issnRegex = r'(?:ISSN )?(\d{4})-(\d{3}[0-9X])$';

  static const int _issnLen = 8;
  static const String _issnPrefix = '977';
  static const String _eanIssnRegex = r'^(977)(?:(\d{10}))$';
  static const int _eanIssnLen = 13;

  static final CodeValidator _validator = CodeValidator.withLength(
    issnRegex,
    _issnLen,
    checkDigit: ISSNCheckDigit.issnCheckDigit,
  );

  static final CodeValidator _eanValidator = CodeValidator.withLength(
    _eanIssnRegex,
    _eanIssnLen,
    checkDigit: EAN13CheckDigit.ean13CheckDigit,
  );

  static final ISSNValidator _instance = ISSNValidator();

  /// The shared instance.
  static ISSNValidator getInstance() => _instance;

  /// Whether [code] is a valid ISSN.
  bool isValid(String? code) => _validator.isValid(code);

  /// The ISSN without its separator, or null if [code] is not a valid ISSN.
  String? validate(String? code) => _validator.validate(code);

  /// The EAN-13 digits, or null if [code] is not a valid ISSN-bearing EAN-13.
  String? validateEan(String? code) => _eanValidator.validate(code);

  /// Converts an ISSN to an EAN-13, appending the two-digit [suffix].
  ///
  /// Returns null when [issn] is not a valid ISSN, and throws [ArgumentError]
  /// when [suffix] is not exactly two digits.
  String? convertToEAN13(String? issn, String? suffix) {
    if (suffix == null || !_digitDigit.hasMatch(suffix)) {
      throw ArgumentError("Suffix must be two digits: '$suffix'");
    }
    final result = validate(issn);
    if (result == null) return null;
    final stem = '$_issnPrefix${result.substring(0, result.length - 1)}$suffix';
    try {
      return stem + EAN13CheckDigit.ean13CheckDigit.calculate(stem);
    } on CheckDigitException catch (e) {
      throw ArgumentError("Check digit error for '$stem' - ${e.message}");
    }
  }

  /// Extracts the ISSN embedded in an EAN-13, recalculating its check digit.
  ///
  /// Returns null when [ean13] is not a valid EAN-13, and throws [ArgumentError]
  /// when it is the wrong length or does not start with `977`.
  String? extractFromEAN13(String ean13) {
    final input = javaTrim(ean13);
    if (input.length != _eanIssnLen) {
      throw ArgumentError("Invalid length ${input.length} for '$input'");
    }
    if (!input.startsWith(_issnPrefix)) {
      throw ArgumentError(
        "Prefix must be $_issnPrefix to contain an ISSN: '$ean13'",
      );
    }
    final result = validateEan(input);
    if (result == null) return null;
    final issnBase = result.substring(3, 10);
    try {
      return issnBase + ISSNCheckDigit.issnCheckDigit.calculate(issnBase);
    } on CheckDigitException catch (e) {
      throw ArgumentError("Check digit error for '$ean13' - ${e.message}");
    }
  }
}
