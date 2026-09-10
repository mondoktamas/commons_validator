import '../../generic_validator.dart';
import '../../internal/ascii.dart';
import 'check_digit.dart';
import 'check_digit_exception.dart';

/// Base class for check-digit routines built on a weighted modulus sum.
///
/// Ported from
/// `org.apache.commons.validator.routines.checkdigit.ModulusCheckDigit`.
abstract class ModulusCheckDigit implements CheckDigit {
  /// Creates a routine using the given [modulus], defaulting to 10.
  const ModulusCheckDigit([this.modulus = modulus10]);

  /// Modulus 10, the most common case.
  static const int modulus10 = 10;

  /// Modulus 11, used by ISBN-10 and ISSN.
  static const int modulus11 = 11;

  /// The modulus applied to the weighted total.
  final int modulus;

  /// The sum of the decimal digits of [number].
  static int sumDigits(int number) {
    var total = 0;
    var todo = number;
    while (todo > 0) {
      total += todo % 10;
      todo ~/= 10;
    }
    return total;
  }

  @override
  String calculate(String? code) {
    if (GenericValidator.isBlankOrNull(code)) {
      throw const CheckDigitException.missingCode();
    }
    final modulusResult = calculateModulus(code!, false);
    return toCheckDigit((modulus - modulusResult) % modulus);
  }

  @override
  bool isValid(String? code) {
    if (GenericValidator.isBlankOrNull(code)) return false;
    try {
      return calculateModulus(code!, true) == 0;
    } on CheckDigitException {
      return false;
    }
  }

  /// The weighted total of [code] reduced by [modulus].
  ///
  /// Throws [CheckDigitException] when a character is not valid, and also when
  /// the weighted total is zero — upstream rejects all-zero codes outright, so
  /// the port keeps that.
  int calculateModulus(String code, bool includesCheckDigit) {
    var total = 0;
    final lth = code.length + (includesCheckDigit ? 0 : 1);
    for (var i = 0; i < code.length; i++) {
      final leftPos = i + 1;
      final rightPos = lth - i;
      total +=
          weightedValue(toInt(code, i, leftPos, rightPos), leftPos, rightPos);
    }
    if (total == 0) {
      throw const CheckDigitException('Invalid code, sum is zero');
    }
    return total % modulus;
  }

  /// Whether [code] is non-null and exactly [length] characters long.
  bool isLength(String? code, int length) =>
      code != null && code.length == length;

  /// The contribution of [charValue] at the given position to the total.
  int weightedValue(int charValue, int leftPos, int rightPos);

  /// Renders [charValue] as a check digit, rejecting values outside 0-9.
  String toCheckDigit(int charValue) {
    if (charValue >= 0 && charValue <= 9) return charValue.toString();
    throw CheckDigitException.invalidCheckDigitValue(charValue);
  }

  /// The numeric value of the character of [code] at [index].
  ///
  /// Only ASCII digits are accepted, which is what rejects the fullwidth and
  /// Arabic-Indic digits that Java's `Character.isDigit` would let through.
  int toInt(String code, int index, int leftPos, int rightPos) {
    final c = code.codeUnitAt(index);
    if (isAsciiDigit(c)) return c - 0x30;
    throw CheckDigitException.invalidCharacter(leftPos, rightPos, code[index]);
  }
}
