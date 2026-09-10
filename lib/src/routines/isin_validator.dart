import 'checkdigit/isin_check_digit.dart';
import 'code_validator.dart';
import 'isin_data.dart';

/// Validates ISIN (International Securities Identifying Number) codes.
///
/// Ported from `org.apache.commons.validator.routines.ISINValidator`.
///
/// The country-code check uses a pinned ISO 3166-1 list rather than live JDK
/// data; see [isinCountryCodes].
class ISINValidator {
  const ISINValidator._({required this.checkCountryCode});

  static const String _isinRegex = '([A-Z]{2}[A-Z0-9]{9}[0-9])';

  static final CodeValidator _validator = CodeValidator.withLength(
    _isinRegex,
    12,
    checkDigit: ISINCheckDigit.isinCheckDigit,
  );

  static const ISINValidator _withCountryCheck =
      ISINValidator._(checkCountryCode: true);
  static const ISINValidator _withoutCountryCheck =
      ISINValidator._(checkCountryCode: false);

  /// The shared instance.
  ///
  /// When [checkCountryCode] is true the first two characters must be a known
  /// country code or one of the accepted non-ISO prefixes.
  static ISINValidator getInstance({required bool checkCountryCode}) =>
      checkCountryCode ? _withCountryCheck : _withoutCountryCheck;

  /// Whether the country-code prefix is checked.
  final bool checkCountryCode;

  /// Whether [code] is a valid ISIN.
  bool isValid(String? code) => validate(code) != null;

  /// The ISIN, or null if [code] is not a valid one.
  String? validate(String? code) {
    final validated = _validator.validate(code);
    if (validated == null || !checkCountryCode) return validated;
    return _checkCode(validated.substring(0, 2)) ? validated : null;
  }

  /// Whether [code] is a known country code or accepted special prefix.
  ///
  /// Both lists are sorted, so binary search applies as it does upstream.
  static bool _checkCode(String code) =>
      _binarySearch(isinCountryCodes, code) ||
      _binarySearch(isinSpecialCodes, code);

  static bool _binarySearch(List<String> sorted, String key) {
    var low = 0;
    var high = sorted.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final cmp = sorted[mid].compareTo(key);
      if (cmp < 0) {
        low = mid + 1;
      } else if (cmp > 0) {
        high = mid - 1;
      } else {
        return true;
      }
    }
    return false;
  }
}
