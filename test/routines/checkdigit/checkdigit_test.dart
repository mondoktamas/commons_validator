import 'package:commons_validator/src/routines/checkdigit/aba_number_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/cas_number_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/cusip_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/ean13_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/ec_number_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/iban_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isbn10_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isbn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isin_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/issn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/luhn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/modulus_ten_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/sedol_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/verhoeff_check_digit.dart';
import 'package:test/test.dart';

import 'check_digit_harness.dart';

/// Ported from the 18 subclasses of upstream's `AbstractCheckDigitTest`.
/// All valid/invalid code data is taken verbatim from those test classes.
void main() {
  // --- LuhnCheckDigitTest ---
  const validVisa = '4417123456789113';
  const validShortVisa = '4222222222222';
  const validAmex = '378282246310005';
  const validMastercard = '5105105105105100';
  const validDiscover = '6011000990139424';
  const validDiners = '30569309025904';

  runCheckDigitTests(
    'LuhnCheckDigit',
    LuhnCheckDigit.luhnCheckDigit,
    valid: const [
      validVisa,
      validShortVisa,
      validAmex,
      validMastercard,
      validDiscover,
      validDiners,
    ],
  );

  // --- ABANumberCheckDigitTest ---
  runCheckDigitTests(
    'ABANumberCheckDigit',
    ABANumberCheckDigit.abanCheckDigit,
    valid: const [
      '123456780',
      '123123123',
      '011000015',
      '111000038',
      '231381116',
      '121181976',
    ],
    zeroSum: '000000000',
  );

  group('ABANumberCheckDigit length', () {
    test('rejects codes that are not nine characters', () {
      for (final code in ['0123456780', '00123456780', '0011000015']) {
        expect(ABANumberCheckDigit.abanCheckDigit.isValid(code), isFalse,
            reason: code);
      }
    });
  });

  // --- EAN13CheckDigitTest ---
  runCheckDigitTests(
    'EAN13CheckDigit',
    EAN13CheckDigit.ean13CheckDigit,
    valid: const [
      '9780072129519',
      '9780764558313',
      '4025515373438',
      '0095673400332',
    ],
    zeroSum: '0000000000000',
  );

  group('EAN13CheckDigit length', () {
    test('rejects over-length codes', () {
      for (final code in ['09780072129519', '00095673400332']) {
        expect(EAN13CheckDigit.ean13CheckDigit.isValid(code), isFalse,
            reason: code);
      }
    });
  });

  // --- ISBN10CheckDigitTest ---
  runCheckDigitTests(
    'ISBN10CheckDigit',
    ISBN10CheckDigit.isbn10CheckDigit,
    valid: const ['1930110995', '020163385X', '1932394354', '1590596277'],
  );

  group('ISBN10CheckDigit length', () {
    test('rejects over-length codes', () {
      for (final code in [
        '01930110995',
        '51930110995',
        '91930110995',
        '0020163385X'
      ]) {
        expect(ISBN10CheckDigit.isbn10CheckDigit.isValid(code), isFalse,
            reason: code);
      }
    });
  });

  // --- ISSNCheckDigitTest ---
  runCheckDigitTests(
    'ISSNCheckDigit',
    ISSNCheckDigit.issnCheckDigit,
    valid: const [
      '03178471',
      '1050124X',
      '15626865',
      '10637710',
      '17487188',
      '02642875',
      '17500095',
      '11881534',
      '19111479',
      '19111460',
      '00016772',
      '1365201X',
    ],
    invalid: const [
      '03178472', // wrong check digit
      '1050-124X', // format character
      ' 1365201X',
      '1365201X ',
      ' 1365201X ',
    ],
    zeroSum: '00000000',
  );

  group('ISSNCheckDigit length', () {
    test('rejects over-length codes', () {
      for (var i = 0; i <= 9; i++) {
        expect(ISSNCheckDigit.issnCheckDigit.isValid('03178471$i'), isFalse);
      }
      expect(ISSNCheckDigit.issnCheckDigit.isValid('0317847100'), isFalse);
    });
  });

  // --- ISBNCheckDigitTest ---
  runCheckDigitTests(
    'ISBNCheckDigit',
    ISBNCheckDigit.isbnCheckDigit,
    valid: const [
      '9780072129519',
      '9780764558313',
      '1930110995',
      '020163385X',
      '1590596277',
      '9781590596272',
    ],
    missingMessage: 'ISBN Code is missing',
    zeroSum: '000000000000',
  );

  // --- CUSIPCheckDigitTest ---
  const cusipValid = [
    'DUS0421C5',
    '037833100',
    '931142103',
    '837649128',
    '392690QT3',
    '594918104',
    '86770G101',
    'Y8295N109',
    'G8572F100',
    '17275R102',
    'EJ7125481',
  ];
  const cusipInvalid = ['DUS0421CW', 'DUS0421CN', 'DUS0421CE', '0378#3100'];

  runCheckDigitTests(
    'CUSIPCheckDigit',
    CUSIPCheckDigit.cusipCheckDigit,
    valid: cusipValid,
    invalid: cusipInvalid,
    zeroSum: '000000000',
  );

  group('CUSIPCheckDigit VALIDATOR-336', () {
    test('over-length codes are rejected', () {
      for (final code in ['0037833100', '0931142103']) {
        expect(CUSIPCheckDigit.cusipCheckDigit.isValid(code), isFalse,
            reason: code);
      }
    });
  });

  // --- SedolCheckDigitTest ---
  runCheckDigitTests(
    'SedolCheckDigit',
    SedolCheckDigit.sedolCheckDigit,
    valid: const ['0263494', '0870612', 'B06LQ97', '3437575', 'B07LF55'],
    invalid: const ['123#567'],
    zeroSum: '0000000',
  );

  group('SedolCheckDigit', () {
    test('rejects codes of the wrong length', () {
      for (final code in ['55', '550', '5500', '0055']) {
        expect(SedolCheckDigit.sedolCheckDigit.isValid(code), isFalse,
            reason: code);
      }
    });

    test('rejects vowels', () {
      for (final code in [
        'A000000',
        'E000006',
        'I000002',
        'O000006',
        'U000000',
        'B0AKT02',
        '0EIOU02',
        'BAEIOU7',
        'AAAAAA0',
      ]) {
        expect(SedolCheckDigit.sedolCheckDigit.isValid(code), isFalse,
            reason: code);
      }
    });
  });

  // --- ISINCheckDigitTest ---
  runCheckDigitTests(
    'ISINCheckDigit',
    ISINCheckDigit.isinCheckDigit,
    valid: const [
      'US0378331005',
      'BMG8571G1096',
      'AU0000XVGZA3',
      'GB0002634946',
      'FR0004026250',
      '3133EHHF3', // VALIDATOR-422
      'DK0009763344',
      'dk0009763344', // lowercase is currently accepted upstream
      'AU0000xvgza3', // lowercase NSIN
      'EZ0000000003',
      'XS0000000009',
      'AA0000000006',
    ],
    invalid: const ['0378#3100'],
    zeroSum: '000000000000',
  );

  // --- VerhoeffCheckDigitTest ---
  runCheckDigitTests(
    'VerhoeffCheckDigit',
    VerhoeffCheckDigit.verhoeffCheckDigit,
    valid: const ['15', '1428570', '12345678902'],
    // Verhoeff has no zero-sum rule: an all-zero code has checksum 0, so it is
    // valid. Upstream inherits zeroSum but VerhoeffCheckDigitTest overrides it.
    zeroSum: null,
  );

  // --- CASNumberCheckDigitTest ---
  runCheckDigitTests(
    'CASNumberCheckDigit',
    CASNumberCheckDigit.casNumberCheckDigit,
    valid: const [
      '00-01-1', // theoretical minimum
      '7732-18-5', // water
      '64-17-5', // ethanol
      '50-78-2', // aspirin
      '58-08-2', // caffeine
      '50-00-0', // formaldehyde
      '50-02-2', // dexamethasone
      '7440-38-2', // arsenic
      '1332-21-4', // asbestos
      '9999999-99-5', // theoretical maximum
    ],
    // The dashes mean the harness cannot mechanically strip a check digit, so
    // only the isValid half of the suite applies.
    testCalculate: false,
    zeroSum: null,
  );

  // --- ECNumberCheckDigitTest ---
  runCheckDigitTests(
    'ECNumberCheckDigit',
    ECNumberCheckDigit.ecNumberCheckDigit,
    valid: const [
      '000-001-6', // theoretical minimum
      '200-001-8', // formaldehyde, first entry in EINECS
      '200-003-9', // dexamethasone
      '231-148-6', // arsenic
      '603-721-4', // asbestos
      '999-999-2', // theoretical maximum
    ],
    testCalculate: false,
    zeroSum: null,
  );

  // --- IBANCheckDigitTest ---
  // IBAN's check digit sits at positions 2-3, not at the end, so the three
  // position-dependent harness helpers are overridden exactly as upstream's
  // IBANCheckDigitTest overrides them.
  runCheckDigitTests(
    'IBANCheckDigit',
    IBANCheckDigit.ibanCheckDigit,
    valid: const [
      'AD1200012030200359100100',
      'AE070331234567890123456',
      'AT611904300234573201',
      'BE68539007547034',
      'CH9300762011623852957',
      'DE89370400440532013000',
      'ES9121000418450200051332',
      'FR1420041010050500013M02606',
      'GB29NWBK60161331926819',
      'GR1601101250000000012300695',
      'IT60X0542811101000000123456',
      'NL91ABNA0417164300',
      'PL61109010140000071219812874',
      'SE4550000000058398257466',
    ],
    invalid: const ['DE89370400440532013001'],
    checkDigitLength: 2,
    zeroSum: null,
    // Upstream's IBANCheckDigitTest sets exactly this message: IBAN reports a
    // length error rather than the generic missing-code one.
    missingMessage: 'Invalid Code length=0',
    checkDigitOfOverride: (code) =>
        code.length <= 2 ? '' : code.substring(2, 4),
    removeCheckDigitOverride: (code) =>
        '${code.substring(0, 2)}00${code.substring(4)}',
    createInvalidCodesOverride: (codes) => [
      for (final full in codes)
        // Check digits run 02-98; 00, 01 and 99 are impossible.
        for (var j = 2; j <= 98; j++)
          if (j.toString().padLeft(2, '0') != full.substring(2, 4))
            '${full.substring(0, 2)}${j.toString().padLeft(2, '0')}'
                '${full.substring(4)}',
    ],
  );

  // --- ModulusTenCheckDigit variants (ModulusTen*CheckDigitTest) ---
  runCheckDigitTests(
    'ModulusTenCheckDigit as Luhn',
    ModulusTenCheckDigit(const [1, 2],
        useRightPos: true, sumWeightedDigits: true),
    valid: const [
      validVisa,
      validShortVisa,
      validAmex,
      validMastercard,
      validDiscover,
      validDiners,
    ],
  );

  runCheckDigitTests(
    'ModulusTenCheckDigit as ABA',
    ModulusTenCheckDigit(const [1, 7, 3], useRightPos: true),
    valid: const [
      '123456780',
      '123123123',
      '011000015',
      '111000038',
      '231381116',
      '121181976',
    ],
    zeroSum: '000000000',
  );

  runCheckDigitTests(
    'ModulusTenCheckDigit as EAN13',
    ModulusTenCheckDigit(const [1, 3], useRightPos: true),
    valid: const [
      '9780072129519',
      '9780764558313',
      '4025515373438',
      '0095673400332',
    ],
    zeroSum: '0000000000000',
  );

  // Sedol's weights, but without its vowel rejection - so the generic routine
  // accepts codes SedolCheckDigit would refuse.
  runCheckDigitTests(
    'ModulusTenCheckDigit as SEDOL',
    ModulusTenCheckDigit(const [1, 3, 1, 7, 3, 9, 1]),
    valid: const ['0263494', '0870612', 'B06LQ97', '3437575', 'B07LF55'],
    invalid: const ['123#567'],
    zeroSum: '0000000',
  );

  runCheckDigitTests(
    'ModulusTenCheckDigit as CUSIP',
    ModulusTenCheckDigit(const [1, 2],
        useRightPos: true, sumWeightedDigits: true),
    valid: cusipValid,
    invalid: cusipInvalid,
    zeroSum: '000000000',
  );
}
