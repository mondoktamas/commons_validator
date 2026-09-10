import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/checkdigit/iban_check_digit.dart';
import 'package:commons_validator/src/routines/iban_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.IBANValidatorTest`.
///
/// The fixture lists and the registry file are upstream's own. `@FieldSource`
/// and `@MethodSource` become plain loops.
void main() {
  final validator = IBANValidator.getInstance();

  const validIbanFixtures = [
    'AD1200012030200359100100',
    'AE070331234567890123456',
    'AL47212110090000000235698741',
    'AT611904300234573201',
    'AZ21NABZ00000000137010001944',
    'BA391290079401028494',
    'BE68539007547034',
    'BG80BNBG96611020345678',
    'BH67BMAG00001299123456',
    'BI4210000100010000332045181',
    'BR1800000000141455123924100C2',
    'BR1800360305000010009795493C1',
    'BR9700360305000010009795493P1',
    'BY13NBRB3600900000002Z00AB00',
    'CH9300762011623852957',
    'CR05015202001026284066',
    'CY17002001280000001200527600',
    'CZ6508000000192000145399',
    'CZ9455000000001011038930',
    'DE89370400440532013000',
    'DJ2110002010010409943020008',
    'DK5000400440116243',
    'DO28BAGR00000001212453611324',
    'EE382200221020145685',
    'EG380019000500000000263180002',
    'ES9121000418450200051332',
    'FI2112345600000785',
    'FI5542345670000081',
    'AX2112345600000785',
    'AX5542345670000081',
    'FK88SC123456789012',
    'FO6264600001631634',
    'FR1420041010050500013M02606',
    'BL6820041010050500013M02606',
    'GF4120041010050500013M02606',
    'GP1120041010050500013M02606',
    'MF8420041010050500013M02606',
    'MQ5120041010050500013M02606',
    'NC8420041010050500013M02606',
    'PF5720041010050500013M02606',
    'PM3620041010050500013M02606',
    'RE4220041010050500013M02606',
    'TF2120041010050500013M02606',
    'WF9120041010050500013M02606',
    'YT3120041010050500013M02606',
    'GB29NWBK60161331926819',
    'GE29NB0000000101904917',
    'GI75NWBK000000007099453',
    'GL8964710001000206',
    'GR1601101250000000012300695',
    'GT82TRAJ01020000001210029690',
    'HN88CABF00000000000250005469',
    'HR1210010051863000160',
    'HU42117730161111101800000000',
    'IE29AIBK93115212345678',
    'IL620108000000099999999',
    'IQ98NBIQ850123456789012',
    'IS140159260076545510730339',
    'IT60X0542811101000000123456',
    'JO94CBJO0010000000000131000302',
    'KW81CBKU0000000000001234560101',
    'KZ86125KZT5004100100',
    'LB62099900000001001901229114',
    'LC55HEMM000100010012001200023015',
    'LI21088100002324013AA',
    'LT121000011101001000',
    'LU280019400644750000',
    'LY83002048000020100120361',
    'LV80BANK0000435195001',
    'LY83002048000020100120361',
    'MC5811222000010123456789030',
    'MD24AG000225100013104168',
    'ME25505000012345678951',
    'MK07250120000058984',
    'MN121234123456789123',
    'MR1300020001010000123456753',
    'MT84MALT011000012345MTLCAST001S',
    'MU17BOMM0101101030300200000MUR',
    'NI45BAPR00000013000003558124',
    'NL91ABNA0417164300',
    'NO9386011117947',
    'OM810180000001299123456',
    'PK36SCBL0000001123456702',
    'PL61109010140000071219812874',
    'PS92PALS000000000400123456702',
    'PT50000201231234567890154',
    'QA58DOHB00001234567890ABCDEFG',
    'RO49AAAA1B31007593840000',
    'RS35260005601001611379',
    'RU0204452560040702810412345678901',
    'SA0380000000608010167519',
    'SC18SSCB11010000000000001497USD',
    'SD8811123456789012',
    'SE4550000000058398257466',
    'SI56191000000123438',
    'SI56263300012039086',
    'SK3112000000198742637541',
    'SM86U0322509800000000270100',
    'SO211000001001000100141',
    'ST68000100010051845310112',
    'SV62CENR00000000000000700025',
    'SV43ACAT00000000000000123123',
    'TL380080012345678910157',
    'TN5910006035183598478831',
    'TR330006100519786457841326',
    'UA213223130000026007233566001',
    'UA213996220000026007233566001',
    'VA59001123000012345678',
    'VG96VPVG0000012345678901',
    'XK051212012345678906',
    'YE15CBYE0001018861234567891234',
  ];

  const invalidIbanFixtures = [
    '',
    '   ',
    'A',
    'AB',
    'FR1420041010050500013m02606',
    'MT84MALT011000012345mtlcast001s',
    'LI21088100002324013aa',
    'QA58DOHB00001234567890abcdefg',
    'RO49AAAA1b31007593840000',
    'LC62HEMM000100010012001200023015',
    'BY00NBRB3600000000000Z00AB00',
    'ST68000200010192194210112',
    'SV62CENR0000000000000700025',
    'NI04BAPR00000013000003558124',
    'RU1704452522540817810538091310419',
  ];

  group('fixtures', () {
    test('every valid fixture passes checksum, has a validator, and is valid',
        () {
      for (final iban in validIbanFixtures) {
        expect(IBANCheckDigit.ibanCheckDigit.isValid(iban), isTrue,
            reason: 'checksum fail: $iban');
        expect(validator.hasValidator(iban), isTrue,
            reason: 'missing validator: $iban');
        expect(validator.isValid(iban), isTrue, reason: iban);
      }
    });

    test('every invalid fixture is rejected', () {
      for (final iban in invalidIbanFixtures) {
        expect(validator.isValid(iban), isFalse, reason: iban);
      }
    });

    test('null is rejected', () => expect(validator.isValid(null), isFalse));
  });

  group('validator lookup', () {
    test('country code is case sensitive', () {
      expect(validator.getValidator('GB'), isNotNull, reason: 'GB');
      expect(validator.getValidator('gb'), isNull, reason: 'gb');
      expect(validator.hasValidator('GB'), isTrue);
      expect(validator.hasValidator('gb'), isFalse);
    });

    test('GB has patterns', () {
      expect(validator.getValidator('GB')!.regexValidator.patterns, isNotEmpty);
    });

    test('the shipped definitions are sorted by country code', () {
      final vals = validator.defaultValidators;
      for (var i = 1; i < vals.length; i++) {
        expect(
          vals[i].countryCode.compareTo(vals[i - 1].countryCode),
          greaterThan(0),
          reason:
              'not sorted: ${vals[i].countryCode} <= ${vals[i - 1].countryCode}',
        );
      }
    });
  });

  group('status precedence', () {
    const cases = {
      'XX': IBANValidatorStatus.unknownCountry,
      'AD0101': IBANValidatorStatus.invalidLength,
      'AD12XX012030200359100100': IBANValidatorStatus.invalidPattern,
      'AD9900012030200359100100': IBANValidatorStatus.invalidChecksum,
      'AD1200012030200359100100': IBANValidatorStatus.valid,
    };
    cases.forEach((iban, expected) {
      test('$iban -> ${expected.name}', () {
        expect(validator.validate(iban), expected);
      });
    });
  });

  group('the singleton is immutable', () {
    test('setValidator throws', () {
      expect(
        () => validator.setValidator('GB', 15, 'GB'),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            'The singleton validator cannot be modified')),
      );
    });

    test('a constructed instance is mutable', () {
      final mutable = IBANValidator();
      expect(mutable.setValidator('GB', -1, 'GB'), isNotNull,
          reason: 'removing GB returns the previous definition');
      expect(mutable.hasValidator('GB'), isFalse);
      // Removing GB must also drop its alias country codes.
      expect(mutable.hasValidator('IM'), isFalse);
    });
  });

  group('IBAN registry v99', () {
    // The registry is transposed: one row per data element, one column per
    // country, tab separated, encoded windows-1252 (latin1 is close enough for
    // the fields read here - the accented characters only appear in country
    // names, which are used solely in failure messages).
    late Map<String, List<String>> rows;

    setUpAll(() {
      final file = File('test/_data/iban_registry_v99.txt');
      final text = latin1.decode(file.readAsBytesSync());

      /// Strips the surrounding double quotes commons-csv would remove, which
      /// the multi-value cells such as `"GF, GP, MQ, ..."` carry.
      String unquote(String cell) =>
          cell.length >= 2 && cell.startsWith('"') && cell.endsWith('"')
              ? cell.substring(1, cell.length - 1).replaceAll('""', '"')
              : cell;

      rows = {
        for (final line in text.split(RegExp(r'\r?\n')))
          if (line.isNotEmpty)
            line.split('\t')[0]: line.split('\t').map(unquote).toList(),
      };
    });

    /// Converts a registry structure fragment such as `4!n6!n8!c` into the
    /// regular expression upstream's `fmtRE` produces.
    String structureToRegex(String ibanPat, int expectedLength) {
      final parts = RegExp(r'(\d+)!([acn])').allMatches(ibanPat).toList();
      expect(parts, isNotEmpty, reason: 'unexpected IBAN pattern $ibanPat');
      final sb = StringBuffer();
      var totLen = 0;
      var curType = parts.first.group(2)!;
      var len = 0;
      String toRe(String type, int n) => switch (type) {
            'n' => '\\d{$n}',
            'a' => '[A-Z]{$n}',
            'c' => '[A-Z0-9]{$n}',
            _ => throw ArgumentError('Unexpected type $type'),
          };
      for (final p in parts) {
        final count = int.parse(p.group(1)!);
        final type = p.group(2)!;
        totLen += count;
        if (type == curType) {
          len += count;
        } else {
          sb.write(toRe(curType, len));
          curType = type;
          len = count;
        }
      }
      sb.write(toRe(curType, len));
      expect(totLen, expectedLength, reason: 'wrong length for $ibanPat');
      return sb.toString();
    }

    test('a validator exists for every registry country, correctly configured',
        () {
      final countries = rows['Name of country']!;
      final ccs = rows['IBAN prefix country code (ISO 3166)']!;
      final additional =
          rows['Country code includes other countries/territories']!;
      final structures = rows['IBAN structure']!;
      final lengths = rows['IBAN length']!;

      for (var i = 1; i < countries.length; i++) {
        final countryCode = ccs[i].trim();
        final info = 'countryCode: $countryCode, countryName: ${countries[i]}';
        final ibanLength = int.parse(lengths[i].trim());

        final v = validator.getValidator(countryCode);
        expect(v, isNotNull, reason: 'no validator for $info');
        expect(v!.ibanLength, ibanLength, reason: 'length for $info');

        final expectedRe =
            structureToRegex(structures[i].trim().substring(2), ibanLength - 2);
        final remaining =
            v.regexValidator.patterns.map((p) => p.pattern).toList();

        expect(remaining.remove('$countryCode$expectedRe'), isTrue,
            reason: 'no pattern $countryCode$expectedRe for $info');

        final aliases = additional[i]
            .split(',')
            .where((s) => s != 'N/A')
            .map((s) => s.replaceAll('(French part)', '').trim())
            .where((s) => s.isNotEmpty);
        for (final ac in aliases) {
          expect(remaining.remove('$ac$expectedRe'), isTrue,
              reason: 'no additional country code $ac for $info');
        }
        expect(remaining, isEmpty, reason: 'unrecognized patterns for $info');
      }
    });

    test('every registry example account is valid', () {
      final countries = rows['Name of country']!;
      final examples = rows['IBAN electronic format example']!;
      for (var i = 1; i < countries.length; i++) {
        final example = examples[i].trim();
        // Upstream skips examples that are themselves in the invalid fixtures.
        if (invalidIbanFixtures.contains(example)) continue;
        expect(validator.isValid(example), isTrue,
            reason: 'invalid example $example for ${countries[i]}');
      }
    });
  });
}
