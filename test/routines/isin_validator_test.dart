import 'package:commons_validator/src/routines/isin_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.ISINValidatorTest`.
void main() {
  final validatorTrue = ISINValidator.getInstance(checkCountryCode: true);
  final validatorFalse = ISINValidator.getInstance(checkCountryCode: false);

  const validFormat = [
    'US0378331005',
    'BMG8571G1096',
    'AU0000XVGZA3',
    'GB0002634946',
    'FR0004026250',
    'DK0009763344',
    'GB00B03MLX29',
    'US7562071065',
    'US56845T3059',
    'LU0327357389',
    'US032511BN64',
    'INE112A01023',
    'EZ0000000003', // invented, for use in ISINValidator
    'EU000A0VUCF1',
    'XA2053913989',
    'XB0000000008',
    'XC0009698371',
    'XD0000000006',
    'XF0000000004',
    'QS0000000008',
    'QT0000000007',
    'QW0000000002',
    'XS0000000009',
    'EU0009652783',
    'XAC8614YAB92',
    'XC0001458477',
    'XD0209061296',
    'AN8068571086',
  ];

  const invalidFormat = <String?>[
    null,
    '',
    '   ',
    'US037833100O', // proper check digit is '5'
    'BMG8571G109D', // proper check digit is '6'
    'AU0000XVGZAD', // proper check digit is '3'
    'GB000263494I', // proper check digit is '6'
    'FR000402625C', // proper check digit is '0'
    'DK000976334H', // proper check digit is '4'
    '3133EHHF3', // VALIDATOR-422: valid check digit, but not a valid ISIN
    'AU0000xvgzA3', // lower-case NSIN is not allowed
    'gb0002634946', // lower-case ISO code is not allowed
  ];

  /// Upstream calls this list `invalidFormatTrue` and only asserts it under the
  /// country-checking validator. Verified against the JVM: `AB0000000006` is in
  /// fact rejected by *both*, because it also fails the ISIN check digit.
  const invalidFormatTrue = ['AB0000000006'];

  test('valid formats pass with and without the country check', () {
    for (final f in validFormat) {
      expect(validatorTrue.isValid(f), isTrue, reason: 'checked: $f');
      expect(validatorFalse.isValid(f), isTrue, reason: 'unchecked: $f');
    }
  });

  test('invalid formats fail with and without the country check', () {
    for (final f in invalidFormat) {
      expect(validatorTrue.isValid(f), isFalse, reason: 'checked: $f');
      expect(validatorFalse.isValid(f), isFalse, reason: 'unchecked: $f');
    }
    for (final f in invalidFormatTrue) {
      expect(validatorTrue.isValid(f), isFalse, reason: 'checked: $f');
    }
  });

  test('surrounding whitespace is trimmed', () {
    for (final code in [' US0378331005', 'US0378331005 ', ' US0378331005 ']) {
      expect(validatorFalse.isValid(code), isTrue, reason: code);
      expect(validatorTrue.isValid(code), isTrue, reason: code);
      expect(validatorTrue.validate(code), 'US0378331005', reason: code);
    }
  });

  test('validate returns the code itself', () {
    expect(validatorTrue.validate('US0378331005'), 'US0378331005');
    expect(validatorTrue.validate('AB0000000006'), isNull);
    expect(validatorFalse.validate('AB0000000006'), isNull);
  });
}
