import '../internal/java_compat.dart';
import 'checkdigit/check_digit_exception.dart';
import 'checkdigit/ean13_check_digit.dart';
import 'checkdigit/isbn10_check_digit.dart';
import 'code_validator.dart';

/// Validates ISBN-10 and ISBN-13 codes, optionally converting the former to the
/// latter.
///
/// Ported from `org.apache.commons.validator.routines.ISBNValidator`.
///
/// Both formats are accepted with or without hyphen or space separators; the
/// capture groups in the patterns strip them, so [validate] returns the code in
/// normalised, separator-free form.
class ISBNValidator {
  /// Creates a validator.
  ///
  /// When [convert] is true (the default), [validate] returns valid ISBN-10
  /// codes converted to their ISBN-13 equivalent.
  ISBNValidator({this.convert = true});

  static const int _isbn10Len = 10;

  static const String _sep = r'(?:\-|\s)';
  static const String _group = r'(\d{1,5})';
  static const String _publisher = r'(\d{1,7})';
  static const String _title = r'(\d{1,6})';

  /// The accepted ISBN-10 shape.
  static const String isbn10Regex = r'^(?:(\d{9}[0-9X])|(?:' +
      _group +
      _sep +
      _publisher +
      _sep +
      _title +
      _sep +
      r'([0-9X])))$';

  /// The accepted ISBN-13 shape.
  static const String isbn13Regex = r'^(978|979)(?:(\d{10})|(?:' +
      _sep +
      _group +
      _sep +
      _publisher +
      _sep +
      _title +
      _sep +
      r'([0-9])))$';

  static final ISBNValidator _instance = ISBNValidator();
  static final ISBNValidator _instanceNoConvert = ISBNValidator(convert: false);

  /// The shared instance, converting ISBN-10 to ISBN-13.
  static ISBNValidator getInstance({bool convert = true}) =>
      convert ? _instance : _instanceNoConvert;

  final CodeValidator _isbn10Validator = CodeValidator.withLength(
    isbn10Regex,
    10,
    checkDigit: ISBN10CheckDigit.isbn10CheckDigit,
  );

  final CodeValidator _isbn13Validator = CodeValidator.withLength(
    isbn13Regex,
    13,
    checkDigit: EAN13CheckDigit.ean13CheckDigit,
  );

  /// Whether valid ISBN-10 codes are converted to ISBN-13 by [validate].
  final bool convert;

  /// Whether [code] is a valid ISBN-10 or ISBN-13.
  bool isValid(String? code) => isValidISBN13(code) || isValidISBN10(code);

  /// Whether [code] is a valid ISBN-10.
  bool isValidISBN10(String? code) => _isbn10Validator.isValid(code);

  /// Whether [code] is a valid ISBN-13.
  bool isValidISBN13(String? code) => _isbn13Validator.isValid(code);

  /// The normalised code, or null if [code] is not a valid ISBN.
  ///
  /// A valid ISBN-10 is returned as an ISBN-13 when [convert] is set.
  String? validate(String? code) {
    final isbn13 = validateISBN13(code);
    if (isbn13 != null) return isbn13;
    final isbn10 = validateISBN10(code);
    if (isbn10 == null) return null;
    return convert ? convertToISBN13(isbn10) : isbn10;
  }

  /// The normalised ISBN-10, or null if [code] is not one.
  String? validateISBN10(String? code) => _isbn10Validator.validate(code);

  /// The normalised ISBN-13, or null if [code] is not one.
  String? validateISBN13(String? code) => _isbn13Validator.validate(code);

  /// Converts a valid ISBN-10 to its ISBN-13 equivalent.
  ///
  /// Returns null when [isbn10] is null or fails ISBN-10 validation, and throws
  /// [ArgumentError] when it is not ten characters long.
  String? convertToISBN13(String? isbn10) {
    if (isbn10 == null) return null;
    final input = javaTrim(isbn10);
    if (input.length != _isbn10Len) {
      throw ArgumentError("Invalid length ${input.length} for '$input'");
    }
    if (!_isbn10Validator.isValid(input)) return null;
    final stem = '978${input.substring(0, _isbn10Len - 1)}';
    try {
      return stem + EAN13CheckDigit.ean13CheckDigit.calculate(stem);
    } on CheckDigitException catch (e) {
      throw ArgumentError("Check digit error for '$input' - ${e.message}");
    }
  }
}
