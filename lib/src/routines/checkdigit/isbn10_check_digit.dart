import 'modulus_check_digit.dart';

/// ISBN-10 check digit (mod 11, weighted by position from the right).
///
/// The check digit may be `X`, standing for 10, but only in the final position.
/// Ported from `ISBN10CheckDigit`.
final class ISBN10CheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const ISBN10CheckDigit() : super(ModulusCheckDigit.modulus11);

  /// The singleton instance.
  static const ISBN10CheckDigit isbn10CheckDigit = ISBN10CheckDigit();

  static const int _isbn10Len = 10;

  @override
  bool isValid(String? code) =>
      isLength(code, _isbn10Len) && super.isValid(code);

  @override
  String toCheckDigit(int charValue) =>
      charValue == 10 ? 'X' : super.toCheckDigit(charValue);

  @override
  int toInt(String code, int index, int leftPos, int rightPos) {
    if (rightPos == 1 && code[index] == 'X') return 10;
    return super.toInt(code, index, leftPos, rightPos);
  }

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) =>
      charValue * rightPos;
}
