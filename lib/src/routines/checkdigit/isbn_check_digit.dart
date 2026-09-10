import '../../generic_validator.dart';
import 'check_digit.dart';
import 'check_digit_exception.dart';
import 'ean13_check_digit.dart';
import 'isbn10_check_digit.dart';

/// Dispatches to [ISBN10CheckDigit] or [EAN13CheckDigit] based on code length.
///
/// Ported from `ISBNCheckDigit`.
final class ISBNCheckDigit implements CheckDigit {
  /// Creates the routine.
  const ISBNCheckDigit();

  /// The ISBN-10 routine.
  static const CheckDigit isbn10CheckDigit = ISBN10CheckDigit.isbn10CheckDigit;

  /// The ISBN-13 routine, which is EAN-13.
  static const CheckDigit isbn13CheckDigit = EAN13CheckDigit.ean13CheckDigit;

  /// The singleton instance.
  static const ISBNCheckDigit isbnCheckDigit = ISBNCheckDigit();

  @override
  String calculate(String? code) {
    if (GenericValidator.isBlankOrNull(code)) {
      throw const CheckDigitException('ISBN Code is missing');
    }
    return switch (code!.length) {
      9 => isbn10CheckDigit.calculate(code),
      12 => isbn13CheckDigit.calculate(code),
      final n => throw CheckDigitException('Invalid ISBN Length = $n'),
    };
  }

  @override
  bool isValid(String? code) => switch (code?.length) {
        10 => isbn10CheckDigit.isValid(code),
        13 => isbn13CheckDigit.isValid(code),
        _ => false,
      };
}
