import 'modulus_check_digit.dart';

/// The Luhn (mod 10) check digit used by most credit card numbers.
///
/// Ported from `LuhnCheckDigit`.
final class LuhnCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const LuhnCheckDigit();

  /// The singleton instance.
  static const LuhnCheckDigit luhnCheckDigit = LuhnCheckDigit();

  static const List<int> _positionWeight = [2, 1];

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) {
    final weighted = charValue * _positionWeight[rightPos % 2];
    return weighted > 9 ? weighted - 9 : weighted;
  }
}
