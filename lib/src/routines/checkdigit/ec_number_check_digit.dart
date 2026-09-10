import '../../generic_validator.dart';
import '../../internal/ascii.dart';
import '../code_validator.dart';
import 'check_digit_exception.dart';
import 'modulus_check_digit.dart';

/// EC Number check digit (mod 11, weighted by position from the left).
///
/// Like [CASNumberCheckDigit] this compares the modulus against the final digit
/// rather than using the inherited zero rule. Ported from `ECNumberCheckDigit`.
final class ECNumberCheckDigit extends ModulusCheckDigit {
  /// Creates the routine.
  const ECNumberCheckDigit._() : super(ModulusCheckDigit.modulus11);

  /// The singleton instance.
  static const ECNumberCheckDigit ecNumberCheckDigit = ECNumberCheckDigit._();

  static const String _group = r'(\d{3})';
  static const String _dash = r'(?:\-)';

  /// The accepted shape, e.g. `200-003-9`.
  static const String ecRegex = '^(?:$_group$_dash$_group$_dash' r'(\d))$';

  static const int _ecLen = 7;

  /// Validates the shape and strips the dashes.
  static final CodeValidator regexValidator =
      CodeValidator.withLength(ecRegex, _ecLen);

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
      leftPos >= _ecLen ? 0 : charValue * leftPos;
}
