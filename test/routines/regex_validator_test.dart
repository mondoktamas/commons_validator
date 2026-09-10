import 'package:commons_validator/src/routines/regex_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.RegexValidatorTest`.
void main() {
  const regex = r'^([abc]*)(?:\-)([DEF]*)(?:\-)([123]*)$';
  const component1 = '([abc]{3})';
  const component2 = '([DEF]{3})';
  const component3 = '([123]{3})';
  const separator1 = r'(?:\-)';
  const separator2 = r'(?:\s)';
  const regex1 = '^$component1$separator1$component2$separator1$component3\$';
  const regex2 = '^$component1$separator2$component2$separator2$component3\$';
  const regex3 = '^$component1$component2$component3\$';
  const multipleRegex = [regex1, regex2, regex3];

  test('a malformed pattern throws', () {
    expect(
        () => RegexValidator(r'^([abCD12]*$'), throwsA(isA<FormatException>()));
  });

  test('patterns are exposed in order', () {
    final validator = RegexValidator.fromList(multipleRegex);
    expect(validator.patterns.map((p) => p.pattern), [regex1, regex2, regex3]);
  });

  test('a missing regex is rejected', () {
    expect(
      () => RegexValidator(''),
      throwsA(isA<ArgumentError>().having(
          (e) => e.message, 'message', 'Regular expression[0] is missing')),
    );
    expect(
      () => RegexValidator.fromList([]),
      throwsA(isA<ArgumentError>().having(
          (e) => e.message, 'message', 'Regular expressions are missing')),
    );
    expect(
      () => RegexValidator.fromList(['ABC', '']),
      throwsA(isA<ArgumentError>().having(
          (e) => e.message, 'message', 'Regular expression[1] is missing')),
    );
    expect(
      () => RegexValidator.fromList(['', 'ABC']),
      throwsA(isA<ArgumentError>().having(
          (e) => e.message, 'message', 'Regular expression[0] is missing')),
    );
  });

  test('multiple patterns, case sensitive', () {
    final multiple = RegexValidator.fromList(multipleRegex);
    final single1 = RegexValidator(regex1);
    final single2 = RegexValidator(regex2);
    final single3 = RegexValidator(regex3);

    const value = 'aac FDE 321';
    expect(multiple.isValid(value), isTrue);
    expect(single1.isValid(value), isFalse);
    expect(single2.isValid(value), isTrue);
    expect(single3.isValid(value), isFalse);

    expect(multiple.validate(value), 'aacFDE321');
    expect(single1.validate(value), isNull);
    expect(single2.validate(value), 'aacFDE321');
    expect(single3.validate(value), isNull);

    expect(multiple.match(value), ['aac', 'FDE', '321']);
    expect(single1.match(value), isNull);
    expect(single2.match(value), ['aac', 'FDE', '321']);
    expect(single3.match(value), isNull);

    const invalid = 'AAC*FDE*321';
    expect(multiple.isValid(invalid), isFalse);
    expect(multiple.validate(invalid), isNull);
    expect(multiple.match(invalid), isNull);
  });

  test('multiple patterns, case insensitive', () {
    final multiple =
        RegexValidator.fromList(multipleRegex, caseSensitive: false);
    final single1 = RegexValidator(regex1, caseSensitive: false);
    final single2 = RegexValidator(regex2, caseSensitive: false);
    final single3 = RegexValidator(regex3, caseSensitive: false);

    const value = 'AAC FDE 321';
    expect(multiple.isValid(value), isTrue);
    expect(single1.isValid(value), isFalse);
    expect(single2.isValid(value), isTrue);
    expect(single3.isValid(value), isFalse);

    expect(multiple.validate(value), 'AACFDE321');
    expect(single2.validate(value), 'AACFDE321');
    expect(multiple.match(value), ['AAC', 'FDE', '321']);
    expect(single1.match(value), isNull);
    expect(single3.match(value), isNull);
  });

  test('null value', () {
    final validator = RegexValidator(regex);
    expect(validator.isValid(null), isFalse);
    expect(validator.validate(null), isNull);
    expect(validator.match(null), isNull);
  });

  test('single pattern, sensitive and insensitive', () {
    final sensitive = RegexValidator(regex);
    final insensitive = RegexValidator(regex, caseSensitive: false);

    expect(sensitive.isValid('ac-DE-1'), isTrue);
    expect(sensitive.isValid('AB-de-1'), isFalse);
    expect(insensitive.isValid('AB-de-1'), isTrue);
    expect(insensitive.isValid('ABd-de-1'), isFalse);

    expect(sensitive.validate('ac-DE-1'), 'acDE1');
    expect(sensitive.validate('AB-de-1'), isNull);
    expect(insensitive.validate('AB-de-1'), 'ABde1');
    expect(insensitive.validate('ABd-de-1'), isNull);

    expect(sensitive.match('ac-DE-1'), ['ac', 'DE', '1']);
    expect(sensitive.match('AB-de-1'), isNull);
    expect(insensitive.match('AB-de-1'), ['AB', 'de', '1']);
    expect(insensitive.match('ABd-de-1'), isNull);

    expect(RegexValidator(r'^([A-Z]*)$').validate('ABC'), 'ABC');
    expect(RegexValidator(r'^([A-Z]*)$').match('ABC'), ['ABC']);
  });

  test('toString lists every pattern', () {
    expect(RegexValidator(regex).toString(), 'RegexValidator{$regex}');
    expect(
      RegexValidator.fromList([regex, regex]).toString(),
      'RegexValidator{$regex,$regex}',
    );
  });

  test('an unmatched optional group yields null in match and "" in validate',
      () {
    final validator = RegexValidator(r'^(abc)?def$');
    expect(validator.isValid('def'), isTrue);
    expect(validator.match('def'), [null]);
    expect(validator.validate('def'), '');
  });
}
