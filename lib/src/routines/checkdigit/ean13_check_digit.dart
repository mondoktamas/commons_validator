import 'modulus_check_digit.dart';

/// EAN-13 / UPC / ISBN-13 check digit (mod 10, alternating weights 3 and 1).
///
/// Ported from `EAN13CheckDigit`.
final class EAN13CheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const EAN13CheckDigit();

  /// The singleton instance.
  static const EAN13CheckDigit ean13CheckDigit = EAN13CheckDigit();

  static const List<int> _positionWeight = [3, 1];
  static const int _ean13Len = 13;

  @override
  bool isValid(String? code) =>
      isLength(code, _ean13Len) && super.isValid(code);

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) =>
      charValue * _positionWeight[rightPos % 2];
}
