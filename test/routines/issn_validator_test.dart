import 'package:commons_validator/src/routines/checkdigit/ean13_check_digit.dart';
import 'package:commons_validator/src/routines/issn_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.ISSNValidatorTest`.
void main() {
  final validator = ISSNValidator.getInstance();

  const validFormat = [
    'ISSN 0317-8471',
    '1050-124X',
    'ISSN 1562-6865',
    '1063-7710',
    '1748-7188',
    'ISSN 0264-2875',
    '1750-0095',
    '1188-1534',
    '1911-1479',
    'ISSN 1911-1460',
    '0001-6772',
    '1365-201X',
    '0264-3596',
    '1144-875X',
  ];

  const invalidFormat = [
    '', // empty
    '   ', // blank
    'ISBN 0317-8471', // wrong prefix
    "'1050-124X", // leading garbage
    'ISSN1562-6865', // missing separator
    '10637710', // missing separator
    "1748-7188'", // trailing garbage
    'ISSN  0264-2875', // extra space
    '1750 0095', // invalid separator
    '1188_1534', // invalid separator
    '1911-1478', // invalid check digit
  ];

  test('valid ISSNs', () {
    for (final f in validFormat) {
      expect(validator.isValid(f), isTrue, reason: f);
    }
  });

  test('invalid ISSNs', () {
    for (final f in invalidFormat) {
      expect(validator.isValid(f), isFalse, reason: f);
    }
  });

  test('null is rejected', () => expect(validator.isValid(null), isFalse));

  test('convertToEAN13 produces a Luhn-valid EAN-13', () {
    for (final f in validFormat) {
      final ean13 = validator.convertToEAN13(f, '00');
      expect(EAN13CheckDigit.ean13CheckDigit.isValid(ean13), isTrue,
          reason: '$ean13');
    }
    expect(validator.convertToEAN13('1144-875X', '00'), '9771144875007');
    expect(validator.convertToEAN13('0264-3596', '00'), '9770264359008');
    expect(validator.convertToEAN13('1234-5679', '00'), '9771234567003');
  });

  test('convertToEAN13 of null is null', () {
    expect(validator.convertToEAN13(null, '00'), isNull);
  });

  test('convertToEAN13 rejects a suffix that is not two digits', () {
    for (final suffix in [null, '', '0', 'A', 'AA', '999']) {
      expect(
        () => validator.convertToEAN13(null, suffix),
        throwsA(isA<ArgumentError>()),
        reason: 'suffix: $suffix',
      );
    }
  });

  test('extractFromEAN13 recovers the ISSN', () {
    expect(validator.extractFromEAN13('9771234567003'), '12345679');
    expect(validator.extractFromEAN13('9770001466006'), '00014664');
    expect(validator.extractFromEAN13('9770317847001'), '03178471');
    expect(validator.extractFromEAN13('9771144875007'), '1144875X');
  });

  test('extractFromEAN13 rejects bad prefixes and lengths', () {
    for (final input in ['9780072129519', '9791090636071', '03178471']) {
      expect(
        () => validator.extractFromEAN13(input),
        throwsA(isA<ArgumentError>()),
        reason: input,
      );
    }
  });

  test('extractFromEAN13 returns null unless the check digit is right', () {
    for (var i = 0; i <= 9; i++) {
      final code = '977123456700$i';
      final result = validator.extractFromEAN13(code);
      if (i == 3) {
        expect(result, isNotNull, reason: '$code has the valid check digit');
      } else {
        expect(result, isNull, reason: code);
      }
    }
  });
}
