import 'package:commons_validator/src/routines/checkdigit/ean13_check_digit.dart';
import 'package:commons_validator/src/routines/code_validator.dart';
import 'package:commons_validator/src/routines/regex_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.CodeValidatorTest`.
void main() {
  const invalidEan = '9781930110992';
  const validEan = '9781930110991';

  test('with no check digit, both codes pass', () {
    final validator = CodeValidator(null);
    expect(validator.checkDigit, isNull);
    expect(validator.validate(invalidEan), invalidEan);
    expect(validator.validate(validEan), validEan);
    expect(validator.isValid(invalidEan), isTrue);
    expect(validator.isValid(validEan), isTrue);
  });

  test('with an EAN-13 check digit, only the valid code passes', () {
    final validator =
        CodeValidator(null, checkDigit: EAN13CheckDigit.ean13CheckDigit);
    expect(validator.checkDigit, isNotNull);
    expect(validator.validate(invalidEan), isNull);
    expect(validator.validate(validEan), validEan);
    expect(validator.isValid(invalidEan), isFalse);
    expect(validator.isValid(validEan), isTrue);
    expect(validator.validate('978193011099X'), isNull);
  });

  group('constructors', () {
    final regex = RegexValidator(r'^[0-9]*$');

    test('from a RegexValidator, no bounds', () {
      final v = CodeValidator.fromRegexValidator(
        regex,
        checkDigit: EAN13CheckDigit.ean13CheckDigit,
      );
      expect(v.regexValidator, same(regex));
      expect(v.minLength, -1);
      expect(v.maxLength, -1);
      expect(v.checkDigit, EAN13CheckDigit.ean13CheckDigit);
    });

    test('from a RegexValidator with explicit bounds', () {
      final v = CodeValidator.fromRegexValidator(
        regex,
        minLength: 10,
        maxLength: 20,
        checkDigit: EAN13CheckDigit.ean13CheckDigit,
      );
      expect(v.minLength, 10);
      expect(v.maxLength, 20);
    });

    test('from a pattern string', () {
      final v = CodeValidator(
        r'^[0-9]*$',
        checkDigit: EAN13CheckDigit.ean13CheckDigit,
      );
      expect(v.regexValidator.toString(), r'RegexValidator{^[0-9]*$}');
      expect(v.minLength, -1);
      expect(v.maxLength, -1);
    });

    test('withLength sets both bounds', () {
      final v = CodeValidator.withLength(r'^[0-9]*$', 13);
      expect(v.minLength, 13);
      expect(v.maxLength, 13);
    });
  });

  group('length bounds', () {
    const length10 = '1234567890';
    const length11 = '12345678901';
    const length12 = '123456789012';
    const length20 = '12345678901234567890';
    const length21 = '123456789012345678901';
    const length22 = '1234567890123456789012';

    test('no bounds accepts everything', () {
      final v = CodeValidator(null);
      for (final s in [
        length10,
        length11,
        length12,
        length20,
        length21,
        length22
      ]) {
        expect(v.validate(s), s);
      }
    });

    test('minimum only', () {
      final v = CodeValidator(null, minLength: 11);
      expect(v.validate(length10), isNull);
      for (final s in [length11, length12, length20, length21, length22]) {
        expect(v.validate(s), s);
      }
    });

    test('maximum only', () {
      final v = CodeValidator(null, maxLength: 21);
      for (final s in [length10, length11, length12, length20, length21]) {
        expect(v.validate(s), s);
      }
      expect(v.validate(length22), isNull);
    });

    test('both bounds', () {
      final v = CodeValidator(null, minLength: 11, maxLength: 21);
      expect(v.validate(length10), isNull);
      for (final s in [length11, length12, length20, length21]) {
        expect(v.validate(s), s);
      }
      expect(v.validate(length22), isNull);
    });

    test('exact length', () {
      final v = CodeValidator(null, minLength: 11, maxLength: 11);
      expect(v.validate(length10), isNull);
      expect(v.validate(length11), length11);
      expect(v.validate(length12), isNull);
    });
  });

  test('no input', () {
    final v = CodeValidator(null);
    expect(v.validate(null), isNull);
    expect(v.validate(''), isNull);
    expect(v.validate('   '), isNull);
    expect(v.validate(' A  '), 'A', reason: 'input is trimmed');
  });

  group('regex', () {
    const value2 = '12';
    const value3 = '123';
    const value4 = '1234';
    const value5 = '12345';
    const invalid = '12a4';

    test('no regex accepts anything', () {
      final v = CodeValidator(null);
      expect(v.regexValidator, isNull);
      for (final s in [value2, value3, value4, value5, invalid]) {
        expect(v.validate(s), s);
      }
    });

    test('a length-constraining regex', () {
      final v = CodeValidator(r'^([0-9]{3,4})$');
      expect(v.regexValidator, isNotNull);
      expect(v.validate(value2), isNull);
      expect(v.validate(value3), value3);
      expect(v.validate(value4), value4);
      expect(v.validate(value5), isNull);
      expect(v.validate(invalid), isNull);
    });

    test('capture groups reformat by dropping the separator', () {
      final v = CodeValidator.fromRegexValidator(
        RegexValidator(r'^([0-9]{3})(?:[-\s])([0-9]{3})$'),
        minLength: 6,
        maxLength: 6,
      );
      expect(v.validate('123-456'), '123456');
      expect(v.validate('123 456'), '123456');
      expect(v.validate('123456'), isNull, reason: 'separator is required');
      expect(v.validate('123.456'), isNull);
    });

    test('an alternation with an unseparated branch', () {
      const regex = r'^(?:([0-9]{3})(?:[-\s])([0-9]{3}))|([0-9]{6})$';
      final v = CodeValidator.fromRegexValidator(
        RegexValidator(regex),
        minLength: 6,
        maxLength: 6,
      );
      expect(v.regexValidator.toString(), 'RegexValidator{$regex}');
      expect(v.validate('123-456'), '123456');
      expect(v.validate('123 456'), '123456');
      expect(v.validate('123456'), '123456');
    });
  });

  test('VALIDATOR-294: a zero bound with null input', () {
    expect(CodeValidator(null, minLength: 0).validate(null), isNull);
    expect(CodeValidator(null, maxLength: 0).validate(null), isNull);
  });
}
