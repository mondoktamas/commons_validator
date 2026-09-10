import '../../internal/ascii.dart';
import 'check_digit_exception.dart';
import 'modulus_check_digit.dart';

/// ISIN check digit (Luhn-style mod 10 over a digit-expanded code).
///
/// Each letter is expanded to the *decimal string* of its value first, so `A`
/// becomes two characters, `10`. Position weights are then computed over the
/// expanded string, not the original. Ported from `ISINCheckDigit`.
final class ISINCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const ISINCheckDigit();

  /// The singleton instance.
  static const ISINCheckDigit isinCheckDigit = ISINCheckDigit();

  static const List<int> _positionWeight = [2, 1];

  @override
  int calculateModulus(String code, bool includesCheckDigit) {
    if (includesCheckDigit) {
      final checkDigit = code.codeUnitAt(code.length - 1);
      if (!isAsciiDigit(checkDigit)) {
        throw CheckDigitException(
          'Invalid checkdigit[${code[code.length - 1]}] in $code',
        );
      }
    }
    final transformed = StringBuffer();
    for (var i = 0; i < code.length; i++) {
      final c = code.codeUnitAt(i);
      if (!isAsciiAlphaNum(c)) {
        throw CheckDigitException("Invalid Character[${i + 1}] = '${code[i]}'");
      }
      transformed.write(asciiNumericValue(c));
    }
    return super.calculateModulus(transformed.toString(), includesCheckDigit);
  }

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) =>
      ModulusCheckDigit.sumDigits(charValue * _positionWeight[rightPos % 2]);
}
