import '../../internal/ascii.dart';
import 'check_digit.dart';
import 'check_digit_exception.dart';

/// IBAN check digit (mod 97), per ISO 7064 / ISO 13616.
///
/// Ported from `IBANCheckDigit`.
final class IBANCheckDigit implements CheckDigit {
  /// Creates the routine.
  const IBANCheckDigit();

  /// The singleton instance.
  static const IBANCheckDigit ibanCheckDigit = IBANCheckDigit();

  static const int _minCodeLen = 5;

  /// The point at which the running total is reduced to stay inside 64 bits.
  ///
  /// Ported literally from upstream. It keeps the intermediate total below
  /// 1e11, which is also inside the 2^53 exactly-representable range, so the
  /// arithmetic stays correct when compiled to JavaScript.
  static const int _max = 999999999;
  static const int _modulus = 97;

  @override
  String calculate(String? code) {
    if (code == null || code.length < _minCodeLen) {
      throw CheckDigitException.invalidLength(code?.length ?? 0);
    }
    final zeroed = '${code.substring(0, 2)}00${code.substring(4)}';
    final charValue = 98 - _calculateModulus(zeroed);
    return charValue.toString().padLeft(2, '0');
  }

  @override
  bool isValid(String? code) {
    if (code == null || code.length < _minCodeLen) return false;
    final check = code.substring(2, 4);
    // 00, 01 and 99 can never be valid check digits.
    if (check == '00' || check == '01' || check == '99') return false;
    try {
      return _calculateModulus(code) == 1;
    } on CheckDigitException {
      return false;
    }
  }

  int _calculateModulus(String code) {
    final reformatted = code.substring(4) + code.substring(0, 4);
    var total = 0;
    for (var i = 0; i < reformatted.length; i++) {
      final c = reformatted.codeUnitAt(i);
      final charValue = asciiNumericValue(c);
      if (!isAsciiAlphaNum(c)) {
        throw CheckDigitException("Invalid Character[$i] = '$charValue'");
      }
      total = (charValue > 9 ? total * 100 : total * 10) + charValue;
      if (total > _max) total %= _modulus;
    }
    return total % _modulus;
  }
}
