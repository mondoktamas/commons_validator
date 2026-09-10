import 'modulus_check_digit.dart';

/// ABA routing transit number check digit (mod 10, weights 3-7-1).
///
/// Ported from `ABANumberCheckDigit`.
final class ABANumberCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const ABANumberCheckDigit();

  /// The singleton instance.
  static const ABANumberCheckDigit abanCheckDigit = ABANumberCheckDigit();

  static const List<int> _positionWeight = [3, 1, 7];
  static const int _abanLen = 9;

  @override
  bool isValid(String? code) => isLength(code, _abanLen) && super.isValid(code);

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) =>
      charValue * _positionWeight[rightPos % 3];
}
