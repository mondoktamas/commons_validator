import 'package:commons_validator/src/routines/isbn_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.ISBNValidatorTest`.
void main() {
  final validator = ISBNValidator.getInstance();
  final noConvert = ISBNValidator.getInstance(convert: false);

  const validISBN10Format = [
    '1234567890',
    '123456789X',
    '12345-1234567-123456-X',
    '12345 1234567 123456 X',
    '1-2-3-4',
    '1 2 3 4',
  ];

  const invalidISBN10Format = [
    '', // empty
    '   ', // blank
    '1', // too short
    '123456789', // too short
    '12345678901', // too long
    '12345678X0', // X not at the end
    '123456-1234567-123456-X', // group too long
    '12345-12345678-123456-X', // publisher too long
    '12345-1234567-1234567-X', // title too long
    '12345-1234567-123456-X2', // check digit too long
    '--1 930110 99 5', // format
    '1 930110 99 5--', // format
    '1 930110-99 5-', // format
    '1.2.3.4', // invalid separator
    '1=2=3=4', // invalid separator
    '1_2_3_4', // invalid separator
    '123456789Y', // other character at the end
    'dsasdsadsa', // invalid characters
    'I love sparrows!', // invalid characters
    '068-556-98-45', // format
  ];

  const validISBN13Format = [
    '9781234567890',
    '9791234567890',
    '978-12345-1234567-123456-1',
    '979-12345-1234567-123456-1',
    '978 12345 1234567 123456 1',
    '979 12345 1234567 123456 1',
    '978-1-2-3-4',
    '979-1-2-3-4',
    '978 1 2 3 4',
    '979 1 2 3 4',
  ];

  const invalidISBN13Format = [
    '', // empty
    '   ', // blank
    '1', // too short
    '978123456789', // too short
    '97812345678901', // too long
    '978-123456-1234567-123456-1', // group too long
    '978-12345-12345678-123456-1', // publisher too long
    '978-12345-1234567-1234567-1', // title too long
    '978-12345-1234567-123456-12', // check digit too long
    '--978 1 930110 99 1', // format
    '978 1 930110 99 1--', // format
    '978 1 930110-99 1-', // format
    '123-4-567890-12-8', // format
    '978.1.2.3.4', // invalid separator
    '978=1=2=3=4', // invalid separator
    '978_1_2_3_4', // invalid separator
    '978123456789X', // invalid character
    '978-0-201-63385-X', // invalid character
    'dsasdsadsadsa', // invalid characters
    'I love sparrows!', // invalid characters
    '979-1-234-567-89-6', // format
  ];

  /// Matches the way upstream tests the raw patterns, via `Matcher.matches()`.
  bool fullMatch(String pattern, String value) {
    final m = RegExp(pattern).matchAsPrefix(value);
    return m != null && m.end == value.length;
  }

  test('valid ISBN-10 formats match the pattern', () {
    for (final f in validISBN10Format) {
      expect(fullMatch(ISBNValidator.isbn10Regex, f), isTrue, reason: f);
    }
  });

  test('valid ISBN-13 formats match the pattern', () {
    for (final f in validISBN13Format) {
      expect(fullMatch(ISBNValidator.isbn13Regex, f), isTrue, reason: f);
    }
  });

  test('invalid ISBN-10 formats are rejected at every layer', () {
    for (final f in invalidISBN10Format) {
      expect(fullMatch(ISBNValidator.isbn10Regex, f), isFalse,
          reason: 'pattern: $f');
      expect(validator.isValidISBN10(f), isFalse, reason: 'isValidISBN10: $f');
      expect(validator.validateISBN10(f), isNull, reason: 'validateISBN10: $f');
    }
  });

  test('invalid ISBN-13 formats are rejected at every layer', () {
    for (final f in invalidISBN13Format) {
      expect(fullMatch(ISBNValidator.isbn13Regex, f), isFalse,
          reason: 'pattern: $f');
      expect(validator.isValidISBN13(f), isFalse, reason: 'isValidISBN13: $f');
      expect(validator.validateISBN13(f), isNull, reason: 'validateISBN13: $f');
    }
  });

  test('only the correct check digit is accepted', () {
    const isbn10Base = '193011099';
    for (final d in '0123456789X'.split('')) {
      expect(validator.isValid('$isbn10Base$d'), d == '5', reason: 'ISBN10-$d');
    }
    const isbn13Base = '978193011099';
    for (var d = 0; d <= 9; d++) {
      expect(validator.isValid('$isbn13Base$d'), d == 1, reason: 'ISBN13-$d');
    }
  });

  test('valid ISBN-10s, with and without separators', () {
    for (final code in [
      '1930110995',
      '1-930110-99-5',
      '1 930110 99 5',
      '020163385X',
      '0-201-63385-X',
      '0 201 63385 X',
    ]) {
      expect(validator.isValidISBN10(code), isTrue, reason: code);
      expect(validator.isValid(code), isTrue, reason: code);
    }
  });

  test('valid ISBN-13s, with and without separators', () {
    for (final code in [
      '9781930110991',
      '978-1-930110-99-1',
      '978 1 930110 99 1',
      '9780201633856',
      '978-0-201-63385-6',
      '978 0 201 63385 6',
    ]) {
      expect(validator.isValidISBN13(code), isTrue, reason: code);
      expect(validator.isValid(code), isTrue, reason: code);
    }
  });

  test('null is rejected everywhere', () {
    expect(validator.isValid(null), isFalse);
    expect(validator.isValidISBN10(null), isFalse);
    expect(validator.isValidISBN13(null), isFalse);
    expect(validator.validate(null), isNull);
    expect(validator.validateISBN10(null), isNull);
    expect(validator.validateISBN13(null), isNull);
    expect(validator.convertToISBN13(null), isNull);
  });

  test('validate normalises ISBN-10 without converting', () {
    expect(noConvert.validateISBN10('1-930110-99-5'), '1930110995');
    expect(noConvert.validateISBN10('1 930110 99 5'), '1930110995');
    expect(noConvert.validateISBN10('0-201-63385-X'), '020163385X');
    expect(noConvert.validate('1-930110-99-5'), '1930110995');
    expect(noConvert.validate('0 201 63385 X'), '020163385X');
  });

  test('validate converts ISBN-10 to ISBN-13 by default', () {
    expect(validator.validate('1930110995'), '9781930110991');
    expect(validator.validate('1-930110-99-5'), '9781930110991');
    expect(validator.validate('1 930110 99 5'), '9781930110991');
    expect(validator.validate('020163385X'), '9780201633856');
    expect(validator.validate('0-201-63385-X'), '9780201633856');
    expect(validator.validate('0 201 63385 X'), '9780201633856');
  });

  test('validate normalises ISBN-13', () {
    expect(validator.validateISBN13('978-1-930110-99-1'), '9781930110991');
    expect(validator.validateISBN13('978 0 201 63385 6'), '9780201633856');
    expect(validator.validate('978-1-930110-99-1'), '9781930110991');
    expect(validator.validate('978 0 201 63385 6'), '9780201633856');
  });

  test('convertToISBN13 rejects the wrong length', () {
    for (final input in ['123456789 ', '12345678901', '', '1234567890X']) {
      expect(
        () => validator.convertToISBN13(input),
        throwsA(isA<ArgumentError>()),
        reason: input,
      );
    }
  });

  test('convertToISBN13 returns null for an invalid ISBN-10', () {
    expect(validator.convertToISBN13('1234567890'), isNull,
        reason: 'wrong check digit');
    expect(validator.convertToISBN13('020163385Y'), isNull,
        reason: 'invalid check character');
    expect(validator.convertToISBN13('X234567890'), isNull,
        reason: 'non-digit body');
  });
}
