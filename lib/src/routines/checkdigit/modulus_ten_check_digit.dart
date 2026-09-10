import '../../generic_validator.dart';
import '../../internal/ascii.dart';
import 'check_digit_exception.dart';
import 'modulus_check_digit.dart';

/// A configurable mod-10 check digit, generalising Luhn, ABA, CUSIP and SEDOL.
///
/// Ported from `ModulusTenCheckDigit`.
final class ModulusTenCheckDigit extends ModulusCheckDigit {
  /// Creates a routine with the given [positionWeight] cycle.
  ///
  /// Set [useRightPos] to index the weight cycle from the right of the code
  /// rather than the left, and [sumWeightedDigits] to replace each weighted
  /// value with the sum of its digits (the Luhn-style fold).
  ModulusTenCheckDigit(
    List<int> positionWeight, {
    this.useRightPos = false,
    this.sumWeightedDigits = false,
  }) : positionWeight = List<int>.unmodifiable(positionWeight);

  /// The repeating weight cycle.
  final List<int> positionWeight;

  /// Whether the weight cycle is indexed from the right.
  final bool useRightPos;

  /// Whether each weighted value is folded to the sum of its digits.
  final bool sumWeightedDigits;

  @override
  bool isValid(String? code) {
    if (GenericValidator.isBlankOrNull(code) ||
        !isAsciiDigit(code!.codeUnitAt(code.length - 1))) {
      return false;
    }
    return super.isValid(code);
  }

  @override
  int toInt(String code, int index, int leftPos, int rightPos) {
    final c = code.codeUnitAt(index);
    if (!isAsciiAlphaNum(c)) {
      throw CheckDigitException.invalidCharacter(
          leftPos, rightPos, code[index]);
    }
    return asciiNumericValue(c);
  }

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) {
    final pos = useRightPos ? rightPos : leftPos;
    final weighted =
        charValue * positionWeight[(pos - 1) % positionWeight.length];
    return sumWeightedDigits ? ModulusCheckDigit.sumDigits(weighted) : weighted;
  }

  @override
  String toString() => 'ModulusTenCheckDigit[positionWeight=$positionWeight, '
      'useRightPos=$useRightPos, sumWeightedDigits=$sumWeightedDigits]';
}
