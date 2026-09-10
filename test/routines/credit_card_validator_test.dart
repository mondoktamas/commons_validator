import 'package:commons_validator/src/routines/checkdigit/luhn_check_digit.dart';
import 'package:commons_validator/src/routines/code_validator.dart';
import 'package:commons_validator/src/routines/credit_card_validator.dart';
import 'package:commons_validator/src/routines/regex_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.CreditCardValidatorTest`.
void main() {
  const validVisa = '4417123456789113'; // 16
  const errorVisa = '4417123456789112';
  const validShortVisa = '4222222222222'; // 13
  const errorShortVisa = '4222222222229';
  const validAmex = '378282246310005'; // 15
  const errorAmex = '378282246310001';
  const validMastercard = '5105105105105100';
  const errorMastercard = '5105105105105105';
  const validDiscover = '6011000990139424';
  const errorDiscover = '6011000990139421';
  const validDiscover65 = '6534567890123458';
  const errorDiscover65 = '6534567890123450';
  const validDiners = '30569309025904'; // 14
  const errorDiners = '30569309025901';
  const validVpay = '4370000000000061'; // 16
  const validVpay2 = '4370000000000012';
  const errorVpay = '4370000000000069';

  const validCards = [
    validVisa,
    validShortVisa,
    validAmex,
    validMastercard,
    validDiscover,
    validDiscover65,
    validDiners,
    validVpay,
    validVpay2,
    '60115564485789458', // VALIDATOR-403
  ];

  const errorCards = [
    errorVisa,
    errorShortVisa,
    errorAmex,
    errorMastercard,
    errorDiscover,
    errorDiscover65,
    errorDiners,
    errorVpay,
    '',
    '12345678901', // too short (11)
    '12345678901234567890', // too long (20)
    '4417123456789112', // invalid check digit
  ];

  test('the default validator accepts Amex, Visa, Mastercard and Discover', () {
    final validator = CreditCardValidator();
    expect(validator.isValid(validVisa), isTrue, reason: 'Visa');
    expect(validator.isValid(validShortVisa), isTrue, reason: 'short Visa');
    expect(validator.isValid(validAmex), isTrue, reason: 'Amex');
    expect(validator.isValid(validMastercard), isTrue, reason: 'Mastercard');
    expect(validator.isValid(validDiscover), isTrue, reason: 'Discover');
    expect(validator.isValid(validDiners), isFalse,
        reason: 'Diners is not in the default set');
    // VPay is not in the default set either, but a 16-digit VPay number also
    // satisfies Visa's `^(4)(\d{12}|\d{15})$`, so it passes anyway. Confirmed
    // against the JVM.
    for (final card in [errorVisa, errorAmex, errorMastercard, errorDiscover]) {
      expect(validator.isValid(card), isFalse, reason: card);
    }
  });

  test('NONE accepts nothing', () {
    final ccv = CreditCardValidator(CreditCardValidator.none);
    for (final card in [
      validVisa,
      validAmex,
      validMastercard,
      validDiscover,
      validDiners,
    ]) {
      expect(ccv.isValid(card), isFalse, reason: card);
    }
  });

  test('the generic validator accepts every valid card and rejects the rest',
      () {
    final validator = CreditCardValidator.generic();
    for (final card in validCards) {
      expect(validator.isValid(card), isTrue, reason: 'valid: $card');
    }
    for (final card in errorCards) {
      expect(validator.isValid(card), isFalse, reason: 'error: $card');
    }
  });

  group('single brands', () {
    void expectOnly(
        CreditCardValidator v, String accepted, List<String> rejected) {
      expect(v.isValid(accepted), isTrue, reason: 'accepts $accepted');
      expect(v.validate(accepted), accepted);
      for (final card in rejected) {
        expect(v.isValid(card), isFalse, reason: 'rejects $card');
      }
    }

    test('Amex only', () {
      expectOnly(
        CreditCardValidator(CreditCardValidator.amex),
        validAmex,
        [
          errorAmex,
          validDiners,
          validDiscover,
          validMastercard,
          validVisa,
          validShortVisa
        ],
      );
      expect(CreditCardValidator(CreditCardValidator.amex).validate(errorAmex),
          isNull);
    });

    test('Visa only accepts both lengths', () {
      final v = CreditCardValidator(CreditCardValidator.visa);
      expect(v.isValid(validVisa), isTrue);
      expect(v.isValid(validShortVisa), isTrue);
      expect(v.isValid(errorVisa), isFalse);
      expect(v.isValid(errorShortVisa), isFalse);
      expect(v.isValid(validAmex), isFalse);
    });

    test('Mastercard only', () {
      expectOnly(
        CreditCardValidator(CreditCardValidator.mastercard),
        validMastercard,
        [errorMastercard, validAmex, validVisa, validDiscover, validDiners],
      );
    });

    test('Discover only, including the 65 prefix', () {
      final v = CreditCardValidator(CreditCardValidator.discover);
      expect(v.isValid(validDiscover), isTrue);
      expect(v.isValid(validDiscover65), isTrue);
      expect(v.isValid(errorDiscover), isFalse);
      expect(v.isValid(errorDiscover65), isFalse);
      expect(v.isValid(validVisa), isFalse);
    });

    test('Diners only', () {
      expectOnly(
        CreditCardValidator(CreditCardValidator.diners),
        validDiners,
        [errorDiners, validAmex, validVisa, validDiscover, validMastercard],
      );
    });

    test('VPay only', () {
      final v = CreditCardValidator(CreditCardValidator.vpay);
      expect(v.isValid(validVpay), isTrue);
      expect(v.isValid(validVpay2), isTrue);
      expect(v.isValid(errorVpay), isFalse);
      // VPay's pattern is a superset of Visa's, so Visa numbers pass too.
      expect(v.isValid(validVisa), isTrue);
    });
  });

  test('brands can be combined', () {
    final v = CreditCardValidator(
      CreditCardValidator.amex | CreditCardValidator.visa,
    );
    expect(v.isValid(validAmex), isTrue);
    expect(v.isValid(validVisa), isTrue);
    expect(v.isValid(validMastercard), isFalse);
  });

  test('an explicit validator list is honoured', () {
    final v = CreditCardValidator.fromValidators([
      CodeValidator(r'^(4)(\d{12}|\d{15})$',
          checkDigit: LuhnCheckDigit.luhnCheckDigit),
    ]);
    expect(v.isValid(validVisa), isTrue);
    expect(v.isValid(validAmex), isFalse);
  });

  test('a regex that matches is still subject to the check digit', () {
    final regex = RegexValidator(r'^(3[47]\d{13})$');
    expect(regex.isValid(errorAmex), isTrue, reason: 'the shape is fine');
    final v = CreditCardValidator(CreditCardValidator.amex);
    expect(v.isValid(errorAmex), isFalse, reason: 'but the check digit is not');
    expect(v.validate(errorAmex), isNull);
  });

  group('ranges', () {
    test('a single-prefix range', () {
      final v = CreditCardValidator.fromRanges([
        const CreditCardRange('34', null, 15, 15),
      ]);
      // validAmex starts with 37, so the 34 prefix does not match it.
      expect(v.isValid(validAmex), isFalse);
      expect(v.isValid('343434343434343'), isTrue,
          reason: '34 prefix, 15 digits');
      expect(v.isValid(validVisa), isFalse);
    });

    test('a low-to-high range', () {
      final v = CreditCardValidator.fromRanges([
        const CreditCardRange('300', '305', 14, 14),
      ]);
      expect(v.isValid(validDiners), isTrue);
      expect(v.isValid(validAmex), isFalse);
    });

    test('explicit lengths', () {
      final v = CreditCardValidator.fromRanges([
        const CreditCardRange.withLengths('4', null, [13, 16]),
      ]);
      expect(v.isValid(validVisa), isTrue, reason: '16 digits');
      expect(v.isValid(validShortVisa), isTrue, reason: '13 digits');
      expect(v.isValid('60115564485789458'), isFalse, reason: '17 digits');
    });

    test('validLength honours both forms', () {
      expect(
          CreditCardValidator.validLength(
              15, const CreditCardRange('34', null, 15, 15)),
          isTrue);
      expect(
          CreditCardValidator.validLength(
              16, const CreditCardRange('34', null, 15, 15)),
          isFalse);
      expect(
        CreditCardValidator.validLength(
            13, const CreditCardRange.withLengths('4', null, [13, 16])),
        isTrue,
      );
      expect(
        CreditCardValidator.validLength(
            14, const CreditCardRange.withLengths('4', null, [13, 16])),
        isFalse,
      );
    });

    test('validators and ranges can be combined', () {
      final v = CreditCardValidator.fromValidatorsAndRanges(
        [CreditCardValidator.amexValidator],
        [const CreditCardRange('4', null, 13, 16)],
      );
      expect(v.isValid(validAmex), isTrue);
      expect(v.isValid(validVisa), isTrue);
      expect(v.isValid(validDiners), isFalse);
    });
  });

  test('blank and null input', () {
    final v = CreditCardValidator();
    expect(v.isValid(null), isFalse);
    expect(v.isValid(''), isFalse);
    expect(v.isValid('   '), isFalse);
    expect(v.validate(null), isNull);
    expect(v.validate(''), isNull);
  });

  test('generic bounds are enforced', () {
    final exact = CreditCardValidator.generic(minLen: 16, maxLen: 16);
    expect(exact.isValid(validVisa), isTrue, reason: '16 digits');
    expect(exact.isValid(validShortVisa), isFalse, reason: '13 digits');
  });
}
