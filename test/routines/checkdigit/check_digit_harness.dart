import 'package:commons_validator/src/routines/checkdigit/check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/check_digit_exception.dart';
import 'package:test/test.dart';

/// The Dart equivalent of upstream's `AbstractCheckDigitTest`.
///
/// Java gets this reuse through an abstract test class that 18 subclasses
/// extend; Dart gets it by calling this function from each routine's test file.
/// Every upstream test method is reproduced except `testSerialization`, which
/// has no Dart analogue.
///
/// [valid] must be codes that *include* their check digit. [invalid] defaults to
/// upstream's single bad code. [zeroSum] is the all-zero code that must be
/// rejected because the weighted total is zero — pass null for routines where
/// zero-sum rejection does not apply. Set [checkDigitLength] to 2 for IBAN.
void runCheckDigitTests(
  String name,
  CheckDigit routine, {
  required List<String> valid,
  List<String> invalid = const ['12345678A'],
  String? zeroSum = '0000000000',
  int checkDigitLength = 1,
  String missingMessage = 'Code is missing',
  bool testCalculate = true,
  String Function(String code)? checkDigitOfOverride,
  String? Function(String code)? removeCheckDigitOverride,
  List<String> Function(List<String> codes)? createInvalidCodesOverride,
}) {
  /// Mirrors upstream's POSSIBLE_CHECK_DIGITS, including the deliberate spaces,
  /// tab, missing 'G' and punctuation.
  const possibleCheckDigits =
      '0123456789 ABCDEFHIJKLMNOPQRSTUVWXYZ\tabcdefghijklmnopqrstuvwxyz!@£\$%^&*()_+';

  String checkDigitOf(String code) =>
      checkDigitOfOverride?.call(code) ??
      (code.length <= checkDigitLength
          ? ''
          : code.substring(code.length - checkDigitLength));

  String? removeCheckDigit(String code) => removeCheckDigitOverride != null
      ? removeCheckDigitOverride(code)
      : (code.length <= checkDigitLength
          ? null
          : code.substring(0, code.length - checkDigitLength));

  /// Every single-character substitution of the check digit that is not the
  /// correct one. Routines whose check digit is not the final character (IBAN)
  /// supply their own generator.
  List<String> createInvalidCodes(List<String> codes) =>
      createInvalidCodesOverride?.call(codes) ??
      [
        for (final fullCode in codes)
          if (removeCheckDigit(fullCode) case final String stem)
            for (final c in possibleCheckDigits.split(''))
              if (c != checkDigitOf(fullCode)) '$stem$c',
      ];

  group('$name (shared check digit suite)', () {
    test('isValid is true for every valid code', () {
      for (final code in valid) {
        expect(routine.isValid(code), isTrue, reason: 'valid: $code');
      }
    });

    test('isValid is false for invalid codes and wrong check digits', () {
      for (final code in invalid) {
        expect(routine.isValid(code), isFalse, reason: 'invalid: $code');
      }
      for (final code in createInvalidCodes(valid)) {
        expect(routine.isValid(code), isFalse,
            reason: 'bad check digit: $code');
      }
    });

    if (testCalculate) {
      test('calculate reproduces the check digit of every valid code', () {
        for (final code in valid) {
          final stem = removeCheckDigit(code);
          expect(stem, isNotNull, reason: 'valid code too short: $code');
          expect(routine.calculate(stem), checkDigitOf(code),
              reason: 'valid: $code');
        }
      });

      test('calculate on an invalid code either differs or throws', () {
        for (final code in invalid) {
          final stem = removeCheckDigit(code);
          if (stem == null) continue;
          try {
            expect(
              routine.calculate(stem),
              isNot(checkDigitOf(code)),
              reason: 'expected mismatch for $code',
            );
          } on CheckDigitException catch (e) {
            expect(e.message, startsWith('Invalid '), reason: 'for $code');
          }
        }
      });
    }

    test('missing code', () {
      expect(routine.isValid(null), isFalse, reason: 'null');
      expect(routine.isValid(''), isFalse, reason: 'empty');
      expect(routine.isValid('9'), isFalse, reason: 'length 1');
      if (testCalculate) {
        expect(
          () => routine.calculate(null),
          throwsA(
            isA<CheckDigitException>()
                .having((e) => e.message, 'message', missingMessage),
          ),
        );
        expect(
          () => routine.calculate(''),
          throwsA(
            isA<CheckDigitException>()
                .having((e) => e.message, 'message', missingMessage),
          ),
        );
      }
    });

    if (zeroSum != null) {
      test('a zero-sum code is rejected', () {
        expect(routine.isValid(zeroSum), isFalse);
        if (testCalculate) {
          expect(
            () => routine.calculate(zeroSum),
            throwsA(
              isA<CheckDigitException>().having(
                (e) => e.message,
                'message',
                'Invalid code, sum is zero',
              ),
            ),
          );
        }
      });
    }
  });
}
