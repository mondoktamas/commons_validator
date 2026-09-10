import 'package:commons_validator/commons_validator.dart';
import 'package:commons_validator/src/internal/decimal_parser.dart';
import 'package:commons_validator/src/internal/number_spec.dart';
import 'package:commons_validator/src/internal/punycode.dart';
import 'package:test/test.dart';

/// Regression tests for the five defects a code review of the port turned up.
///
/// Every expectation here was checked against OpenJDK 17.0.18 before being
/// written down, using `tool/jvm_diff` and `jshell`.
void main() {
  const us = 'en_US';

  group('the two-digit-year pivot applies at any field position', () {
    // The bug: _yearRunLength returned -1 for a non-leading `yy`, and the caller
    // treated -1 as "not two digits", widening the pattern and disabling the
    // pivot. So `MM/dd/yy` and `dd/MM/yy` - the two commonest two-digit-year
    // patterns - silently read `99` as the year 99.
    final v = DateValidator.getInstance();

    test('a two-digit year pivots wherever yy sits', () {
      expect(
          v.parse('12/31/99', pattern: 'MM/dd/yy'), DateTime.utc(1999, 12, 31));
      expect(
          v.parse('31/12/99', pattern: 'dd/MM/yy'), DateTime.utc(1999, 12, 31));
      expect(
          v.parse('99-12-31', pattern: 'yy-MM-dd'), DateTime.utc(1999, 12, 31));
      expect(
          v.parse('31-12-26', pattern: 'dd-MM-yy'), DateTime.utc(2026, 12, 31));
      expect(v.parse('26/01/01', pattern: 'yy/MM/dd'), DateTime.utc(2026));
      expect(v.parse('12-99', pattern: 'MM-yy'), DateTime.utc(1999, 12));
    });

    test('more than two digits is read literally, with no pivot', () {
      expect(v.parse('12/31/1999', pattern: 'MM/dd/yy'),
          DateTime.utc(1999, 12, 31));
      expect(
          v.parse('12/31/0099', pattern: 'MM/dd/yy'), DateTime.utc(99, 12, 31));
      expect(v.parse('0001-01-01', pattern: 'yy-MM-dd'), DateTime.utc(1));
    });

    test('the pivot survives a pattern whose digit count cannot be measured',
        () {
      // A textual month means the offsets are unknowable, so the pivot must be
      // kept rather than guessed away.
      expect(v.parse('31-Dec-99', pattern: 'dd-MMM-yy'),
          DateTime.utc(1999, 12, 31));
    });
  });

  group('an extreme exponent is bounded rather than materialised', () {
    // The bug: scale was applied by building 10^|scale| as a BigInt, so
    // `1E20000000` took about 2.4 minutes and hundreds of megabytes - a denial
    // of service from a 12-byte input. Java pays nothing, because BigDecimal
    // keeps an int scale.
    test('the double family answers infinity or zero, as Java does', () {
      final d = DoubleValidator.getInstance();
      expect(d.parse('1E20000000', locale: us), double.infinity);
      expect(d.parse('-1E20000000', locale: us), double.negativeInfinity);
      expect(d.parse('1E-20000000', locale: us), 0.0);
      expect(FloatValidator.getInstance().parse('1E20000000', locale: us),
          double.infinity);
    });

    test('the exact families decline instead', () {
      expect(BigDecimalValidator.getInstance().parse('1E20000000', locale: us),
          isNull);
      expect(BigIntegerValidator.getInstance().parse('1E20000000', locale: us),
          isNull);
      expect(IntegerValidator.getInstance().parse('1E20000000', locale: us),
          isNull);
      expect(
          LongValidator.getInstance().parse('1E20000000', locale: us), isNull);
    });

    test('and it returns promptly', () {
      final sw = Stopwatch()..start();
      for (final input in ['1E20000000', '1E-20000000', '1E999999999']) {
        DoubleValidator.getInstance().isValid(input, locale: us);
        BigDecimalValidator.getInstance().isValid(input, locale: us);
      }
      // Comfortably generous; before the fix a single input took minutes.
      expect(sw.elapsedMilliseconds, lessThan(2000),
          reason: 'took ${sw.elapsedMilliseconds}ms');
    });

    test('scales inside the bound still work exactly', () {
      expect(BigDecimalValidator.getInstance().parse('1E100', locale: us),
          Decimal.parse('1${'0' * 100}'));
      expect(parseDecimal('1E1024', NumberSpec.forLocale(us))!.magnitude,
          NumberMagnitude.normal);
      expect(parseDecimal('1E-1025', NumberSpec.forLocale(us))!.magnitude,
          NumberMagnitude.underflow);
    });
  });

  group('subnormal doubles survive the parse', () {
    // Found while fixing the exponent bound: Decimal.toDouble flushes
    // subnormals to zero, so DoubleValidator answered 0.0 for 1E-320 where Java
    // gives 1.0E-320. The double is now read straight from the digits.
    test('DoubleValidator keeps them', () {
      final d = DoubleValidator.getInstance();
      expect(d.parse('1E-320', locale: us), 1e-320);
      expect(d.parse('1E-310', locale: us), 1e-310);
      expect(d.parse('5E-324', locale: us), 5e-324);
      expect(d.parse('1E-300', locale: us), 1e-300);
    });

    test('FloatValidator still rejects them, as Java does', () {
      // Below Float.MIN_VALUE, so upstream returns null - which only works if
      // the value reaching the bounds check is the real subnormal, not zero.
      expect(FloatValidator.getInstance().parse('1E-320', locale: us), isNull);
    });
  });

  group('scientific patterns report the right fraction digits', () {
    // The bug: inFraction was never cleared at `E`, so the exponent's own digits
    // were counted as fraction digits.
    test('min and max match Java', () {
      const expected = {
        '0.00E00': (2, 2),
        '0.###E0': (0, 3),
        '#0.#####E0': (0, 5),
        '0.00': (2, 2),
        '#,##0.00': (2, 2),
      };
      expected.forEach((pattern, want) {
        final spec = NumberSpec.forPattern(pattern, us);
        expect(
          (spec.minimumFractionDigits, spec.maximumFractionDigits),
          want,
          reason: pattern,
        );
      });
    });

    test('so a strict parse truncates to the right scale', () {
      // Was 1234.5670 (scale 4) because the exponent digits inflated the count.
      expect(
        BigDecimalValidator.getInstance()
            .parse('1234.567', pattern: '0.00E00', locale: us),
        Decimal.parse('1234.56'),
      );
    });
  });

  group('punycode rejects non-digit basic code points', () {
    // The bug: RFC 3492's `cp - 48 < 10` relies on unsigned wraparound. Ported
    // to signed ints it accepted everything below '9' as a digit and decoded
    // silent garbage.
    test('code units between 0x16 and 0x2F throw', () {
      // 0x2D is excluded deliberately: the hyphen is punycode's own delimiter,
      // so it is legitimate there and cannot be tested as a stray character.
      for (final cp in [0x16, 0x20, 0x21, 0x27, 0x2B, 0x2C, 0x2E, 0x2F]) {
        final input = 'abc-${String.fromCharCode(cp)}a';
        expect(
          () => punycodeDecode(input),
          throwsA(isA<PunycodeException>()),
          reason: 'U+${cp.toRadixString(16)}',
        );
      }
    });

    test('and genuine digits still decode', () {
      expect(punycodeDecode('abc-'), 'abc');
      expect(punycodeDecode('caf-dma'),
          String.fromCharCodes([0x63, 0x61, 0x66, 0xE9]));
    });
  });

  group('week numbering floor-divides correctly', () {
    // The bug: `normalized % 7 == 0` assumed a negative modulus, which Dart
    // never produces, so an exact negative multiple of 7 came out one too high.
    test('a partial first week still reports week 0', () {
      // 2026-08-01 is a Saturday; under Monday/4 rules it is a partial week.
      for (final day in [1, 2]) {
        final f = CalendarFields(
          year: 2026,
          month: 8,
          day: day,
          firstDayOfWeek: DayOfWeek.monday,
          minimalDaysInFirstWeek: 4,
        );
        expect(f.weekOfMonth, 0, reason: '2026-08-0$day');
      }
      final third = CalendarFields(
        year: 2026,
        month: 8,
        day: 3,
        firstDayOfWeek: DayOfWeek.monday,
        minimalDaysInFirstWeek: 4,
      );
      expect(third.weekOfMonth, 1);
    });
  });

  group('defects found by closing the coverage gaps', () {
    // The review's finding about the year pivot only showed up once the date
    // corpus gained non-leading `yy` patterns. Widening it that far turned up
    // three more, and adding scientific patterns to the number corpus turned up
    // a fourth. All four are verified against the JVM.
    final v = DateValidator.getInstance();

    test('there is no year 0', () {
      // 1 BC is followed by 1 AD, and Java's non-lenient GregorianCalendar
      // refuses year 0. `intl` hands one back happily.
      expect(v.parse('0000-10-28', pattern: 'yyyy-MM-dd'), isNull);
      expect(v.parse('00-10-28', pattern: 'yyyy-MM-dd'), isNull);
      expect(v.parse('06/28/0000', pattern: 'MM/dd/yyyy'), isNull);
      // Year 1 is fine, and a two-digit 00 pivots into the 2000s.
      expect(v.parse('0001-10-28', pattern: 'yyyy-MM-dd'),
          DateTime.utc(1, 10, 28));
      expect(
          v.parse('00-10-28', pattern: 'yy-MM-dd'), DateTime.utc(2000, 10, 28));
    });

    test('a yy field abutting another numeric field is exactly two digits', () {
      // Where numeric fields touch, Java honours the declared width instead of
      // reading greedily. Measuring greedily widened the pattern and accepted
      // both of the first two below.
      expect(v.parse('460330', pattern: 'yyMMdd'), DateTime.utc(2046, 3, 30));
      expect(v.parse('000330', pattern: 'yyMMdd'), DateTime.utc(2000, 3, 30));
      expect(v.parse('20460330', pattern: 'yyMMdd'), isNull,
          reason: 'yy takes 20, so MM sees 46');
      expect(
          v.parse('20460330', pattern: 'yyyyMMdd'), DateTime.utc(2046, 3, 30));
      expect(v.parse('460330', pattern: 'yyyyMMdd'), isNull);
    });

    test('the pivot window is an instant, not a year', () {
      // SimpleDateFormat's window starts exactly eighty years before now, and
      // the resolved *date* must fall inside it. Measured on the JVM, the
      // boundary sits at yy=46 -> 20xx and yy=47 -> 19xx during 2026 - which a
      // year-only approximation gets wrong by one.
      final now = DateTime.now();
      final windowStart = DateTime.utc(now.year - 80, now.month, now.day);
      for (final yy in [0, 45, 46, 47, 99]) {
        final parsed = v.parse(
          '01/01/${yy.toString().padLeft(2, '0')}',
          pattern: 'MM/dd/yy',
        )!;
        expect(parsed.year % 100, yy);
        expect(
          parsed.isBefore(windowStart),
          isFalse,
          reason: 'yy=$yy resolved to ${parsed.year}, before the window',
        );
        expect(
          parsed.isBefore(DateTime.utc(
            windowStart.year + 100,
            windowStart.month,
            windowStart.day,
          )),
          isTrue,
          reason: 'yy=$yy resolved to ${parsed.year}, past the window',
        );
      }
    });

    test('a pattern without grouping rejects grouping separators', () {
      // Java's isGroupingUsed() is false without a `,` in the pattern, and
      // parsing then stops at the separator: `1,234` under `0.00` is 1 with
      // `,234` left over, which a strict validator refuses.
      final d = BigDecimalValidator.getInstance();
      expect(d.parse('1,234', pattern: '0.00', locale: us), isNull);
      expect(d.parse('1,234', pattern: '0.00E00', locale: us), isNull);
      expect(
          d.parse('1234', pattern: '0.00', locale: us), Decimal.fromInt(1234));
      // With grouping in the pattern it is accepted again.
      expect(d.parse('1,234', pattern: '#,##0.00', locale: us),
          Decimal.fromInt(1234));
      // Locale formats all use grouping, so they are unaffected.
      expect(d.parse('1,234', locale: us), Decimal.fromInt(1234));
    });
  });

  group('behaviours the review flagged that are in fact faithful', () {
    // Both of these match upstream exactly; they are pinned so a future
    // "cleanup" does not introduce a divergence.
    test('validate returns the empty string for a null single group', () {
      // RegexValidator.java: `return group != null ? group : "";`
      expect(RegexValidator(r'^abc(x)?$').validate('abc'), '');
      expect(CodeValidator(r'^abc(x)?$').validate('abc'), '');
    });

    test('isValidPath decodes the path, as upstream does', () {
      // UrlValidator.java passes decodedPath to both the URI constructor and
      // countToken, so Java rejects all three of these too.
      final v = UrlValidator.getInstance();
      expect(v.isValid('http://example.com/%2E%2E/x'), isFalse);
      expect(v.isValid('http://example.com/a%2F%2Fb'), isFalse);
      expect(v.isValid('http://example.com/a%zzb'), isFalse);
      // With two slashes allowed, the encoded pair is fine.
      expect(
        UrlValidator(options: UrlValidator.allow2Slashes)
            .isValid('http://example.com/a%2F%2Fb'),
        isTrue,
      );
    });
  });
}
