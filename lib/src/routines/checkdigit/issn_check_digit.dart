import 'modulus_check_digit.dart';

/// ISSN check digit (mod 11, weighted 8 down to 2 from the left).
///
/// As with ISBN-10 the check digit may be `X`, standing for 10.
/// Ported from `ISSNCheckDigit`.
final class ISSNCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const ISSNCheckDigit() : super(ModulusCheckDigit.modulus11);

  /// The singleton instance.
  static const ISSNCheckDigit issnCheckDigit = ISSNCheckDigit();

  static const int _issnLen = 8;

  @override
  bool isValid(String? code) => isLength(code, _issnLen) && super.isValid(code);

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
      charValue * (9 - leftPos);
}
