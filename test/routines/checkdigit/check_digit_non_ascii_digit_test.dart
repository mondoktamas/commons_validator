import 'package:commons_validator/src/routines/checkdigit/check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/cusip_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/ean13_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isbn10_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isin_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/issn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/luhn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/modulus_ten_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/sedol_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/verhoeff_check_digit.dart';
import 'package:test/test.dart';

/// Ported from `CheckDigitNonAsciiDigitTest`.
///
/// Java's `Character.isDigit` and `Character.getNumericValue` accept fullwidth
/// and Arabic-Indic digits, so upstream needs these assertions to prove the
/// routines reject them. The Dart port restricts to ASCII explicitly (see
/// `internal/ascii.dart`), and this test is what holds it to that.
void main() {
  /// Maps ASCII digits to Arabic-Indic (U+0660..U+0669), leaving others alone.
  String toArabicIndic(String code) => String.fromCharCodes([
        for (final c in code.codeUnits)
          if (c >= 0x30 && c <= 0x39) 0x660 + (c - 0x30) else c,
      ]);

  /// Maps ASCII digits to fullwidth (U+FF10..U+FF19), leaving others alone.
  String toFullwidth(String code) => String.fromCharCodes([
        for (final c in code.codeUnits)
          if (c >= 0x30 && c <= 0x39) 0xFF10 + (c - 0x30) else c,
      ]);

  final alphaNum = RegExp('[a-zA-Z0-9]');

  void assertRejectsNonAscii(CheckDigit routine, String validCode) {
    expect(routine.isValid(validCode), isTrue, reason: 'ASCII: $validCode');
    expect(
      routine.isValid(toFullwidth(validCode)),
      isFalse,
      reason: 'fullwidth: $validCode',
    );
    expect(
      routine.isValid(toArabicIndic(validCode)),
      isFalse,
      reason: 'arabic-indic: $validCode',
    );
    // Substituting any C0 or C1 control character must also be rejected.
    for (final ranges in [
      [0, 32],
      [127, 256],
    ]) {
      for (var i = ranges[0]; i < ranges[1]; i++) {
        final mutated =
            validCode.replaceFirst(alphaNum, String.fromCharCode(i));
        expect(
          routine.isValid(mutated),
          isFalse,
          reason: 'U+${i.toRadixString(16)} in $validCode',
        );
      }
    }
  }

  test(
      'CUSIP',
      () =>
          assertRejectsNonAscii(CUSIPCheckDigit.cusipCheckDigit, '037833100'));
  test(
      'EAN13',
      () => assertRejectsNonAscii(
          EAN13CheckDigit.ean13CheckDigit, '9780072129519'));
  test(
      'ISBN10',
      () => assertRejectsNonAscii(
          ISBN10CheckDigit.isbn10CheckDigit, '1930110995'));
  test(
      'ISIN',
      () =>
          assertRejectsNonAscii(ISINCheckDigit.isinCheckDigit, 'US0378331005'));
  test('ISSN',
      () => assertRejectsNonAscii(ISSNCheckDigit.issnCheckDigit, '03178471'));
  test(
      'Luhn',
      () => assertRejectsNonAscii(
          LuhnCheckDigit.luhnCheckDigit, '4417123456789113'));
  test('Sedol',
      () => assertRejectsNonAscii(SedolCheckDigit.sedolCheckDigit, '0263494'));
  test(
      'Verhoeff',
      () => assertRejectsNonAscii(
          VerhoeffCheckDigit.verhoeffCheckDigit, '1428570'));

  test(
    'ModulusTen as Luhn',
    () => assertRejectsNonAscii(
      ModulusTenCheckDigit(const [1, 2],
          useRightPos: true, sumWeightedDigits: true),
      '4417123456789113',
    ),
  );
}
