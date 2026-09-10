import '../../internal/ascii.dart';
import 'check_digit_exception.dart';
import 'modulus_check_digit.dart';

/// SEDOL check digit (mod 10, fixed weights 1-3-1-7-3-9-1).
///
/// Vowels are rejected outright, which is what stops a SEDOL being confused
/// with other alphanumeric codes. Ported from `SedolCheckDigit`.
final class SedolCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const SedolCheckDigit();

  /// The singleton instance.
  static const SedolCheckDigit sedolCheckDigit = SedolCheckDigit();

  static const List<int> _positionWeight = [1, 3, 1, 7, 3, 9, 1];

  @override
  int calculateModulus(String code, bool includesCheckDigit) {
    final length = code.length;
    if (length > _positionWeight.length ||
        (includesCheckDigit && length != _positionWeight.length)) {
      throw CheckDigitException('Invalid Code Length = $length');
    }
    return super.calculateModulus(code, includesCheckDigit);
  }

  static bool _isVowel(int c) => 'AEIOU'.contains(
        String.fromCharCode(c).toUpperCase(),
      );

  @override
  int toInt(String code, int index, int leftPos, int rightPos) {
    final c = code.codeUnitAt(index);
    final charValue = asciiNumericValue(c);
    final charValueMax = rightPos == 1 ? 9 : maxAlphanumericValue;
    // Order matters: the vowel test only runs for ASCII alphanumerics, matching
    // Java's short-circuit, and the value is computed first for the message.
    if (charValue > charValueMax || !isAsciiAlphaNum(c) || _isVowel(c)) {
      throw CheckDigitException(
        "Invalid Character[$leftPos,$rightPos] = '$charValue' "
        'out of range 0 to $charValueMax, excluding vowels.',
      );
    }
    return charValue;
  }

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) =>
      charValue * _positionWeight[leftPos - 1];
}
