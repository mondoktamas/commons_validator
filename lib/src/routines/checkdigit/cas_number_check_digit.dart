import '../../generic_validator.dart';
import '../../internal/ascii.dart';
import '../code_validator.dart';
import 'check_digit_exception.dart';
import 'modulus_check_digit.dart';

/// CAS Registry Number check digit (mod 10, weights 0-9 from the right).
///
/// Unlike most routines here, [isValid] does **not** use the inherited
/// "weighted total is 0" rule: it compares the modulus against the final digit,
/// after [regexValidator] has stripped the dashes. Ported from
/// `CASNumberCheckDigit`.
final class CASNumberCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const CASNumberCheckDigit._();

  /// The singleton instance.
  static const CASNumberCheckDigit casNumberCheckDigit =
      CASNumberCheckDigit._();

  static const String _group1 = r'(\d{2,7})';
  static const String _dash = r'(?:\-)';

  /// The accepted shape, e.g. `87-69-2`.
  static const String casRegex =
      '^(?:$_group1$_dash' r'(\d{2})' '$_dash' r'(\d))$';

  static const int _casMinLen = 4; // 9-99-9, length without separators
  static const int _casMaxLen = 10;

  /// Validates the shape and strips the dashes.
  static final CodeValidator regexValidator = CodeValidator(
    casRegex,
    minLength: _casMinLen,
    maxLength: _casMaxLen,
  );

  static const List<int> _positionWeight = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  String calculate(String? code) {
    if (GenericValidator.isBlankOrNull(code)) {
      throw const CheckDigitException.missingCode();
    }
    return toCheckDigit(calculateModulus(code!, false));
  }

  @override
  bool isValid(String? code) {
    if (GenericValidator.isBlankOrNull(code)) return false;
    final validated = regexValidator.validate(code);
    if (validated == null) return false;
    try {
      return calculateModulus(validated, true) ==
          asciiNumericValue(validated.codeUnitAt(validated.length - 1));
    } on CheckDigitException {
      return false;
    }
  }

  @override
  int weightedValue(int charValue, int leftPos, int rightPos) =>
      charValue * _positionWeight[(rightPos - 1) % ModulusCheckDigit.modulus10];
}
