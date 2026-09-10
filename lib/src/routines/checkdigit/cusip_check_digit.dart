import '../../internal/ascii.dart';
import 'check_digit_exception.dart';
import 'modulus_check_digit.dart';

/// CUSIP check digit (mod 10 over alphanumerics, weights 2 and 1).
///
/// Ported from `CUSIPCheckDigit`.
final class CUSIPCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const CUSIPCheckDigit();

  /// The singleton instance.
  static const CUSIPCheckDigit cusipCheckDigit = CUSIPCheckDigit();

  static const List<int> _positionWeight = [2, 1];
  static const int _cusipLen = 9;

  @override
  bool isValid(String? code) =>
      isLength(code, _cusipLen) && super.isValid(code);

  @override
  int toInt(String code, int index, int leftPos, int rightPos) {
    final c = code.codeUnitAt(index);
    final charValue = asciiNumericValue(c);
    final charValueMax = rightPos == 1 ? 9 : maxAlphanumericValue;
    if (charValue > charValueMax || !isAsciiAlphaNum(c)) {
      throw CheckDigitException(
        "Invalid Character[$leftPos,$rightPos] = '$charValue' "
        'out of range 0 to $charValueMax',
      );
    }
    return charValue;
  }

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) =>
      ModulusCheckDigit.sumDigits(charValue * _positionWeight[rightPos % 2]);
}
