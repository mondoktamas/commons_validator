import 'package:commons_validator/src/internal/decimal_parser.dart';
import 'package:commons_validator/src/internal/number_spec.dart';
import 'package:commons_validator/src/routines/big_number_validators.dart';
import 'package:commons_validator/src/routines/float_validators.dart';
import 'package:commons_validator/src/routines/integer_validators.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

/// Ported from the `AbstractNumberValidatorTest` hierarchy.
///
/// Every expectation here was checked against OpenJDK 17.0.18 rather than
/// assumed. The locale is always passed explicitly: Java falls back to
/// `Locale.getDefault()` and upstream's tests mutate that global, which Dart has
/// no equivalent of.
void main() {
  const us = 'en_US';

  group('ByteValidator', () {
    final v = ByteValidator.getInstance();
    test('range', () {
      expect(v.parse('127', locale: us), 127);
      expect(v.parse('-128', locale: us), -128);
      expect(v.parse('128', locale: us), isNull);
      expect(v.parse('-129', locale: us), isNull);
    });
    test('isInRange', () {
      expect(v.isInRange(10, 0, 20), isTrue);
      expect(v.isInRange(30, 0, 20), isFalse);
      expect(v.minValue(10, 10), isTrue);
      expect(v.maxValue(10, 10), isTrue);
    });
  });

  group('ShortValidator', () {
    final v = ShortValidator.getInstance();
    test('range', () {
      expect(v.parse('32767', locale: us), 32767);
      expect(v.parse('-32768', locale: us), -32768);
      expect(v.parse('32768', locale: us), isNull);
      expect(v.parse('-32769', locale: us), isNull);
    });
  });

  group('IntegerValidator', () {
    final v = IntegerValidator.getInstance();
    test('range', () {
      expect(v.parse('2147483647', locale: us), 2147483647);
      expect(v.parse('-2147483648', locale: us), -2147483648);
      expect(v.parse('2147483648', locale: us), isNull);
      expect(v.parse('-2147483649', locale: us), isNull);
    });

    test('grouping separators are accepted but not checked', () {
      expect(v.parse('1,234', locale: us), 1234);
      // Java does not validate grouping placement.
      expect(v.parse('1,2,3,4', locale: us), 1234);
    });

    test('a fraction makes a strict parse fail', () {
      // parseIntegerOnly stops at the separator, leaving `.5` unconsumed.
      expect(v.parse('1234.5', locale: us), isNull);
      expect(const IntegerValidator(strict: false).parse('1234.5', locale: us),
          1234);
    });

    test('a lenient validator keeps the parsed prefix', () {
      expect(v.parse('1234abc', locale: us), isNull);
      expect(const IntegerValidator(strict: false).parse('1234abc', locale: us),
          1234);
    });

    test('a leading plus is rejected', () {
      expect(v.parse('+1234', locale: us), isNull);
    });

    test('a pattern can be supplied', () {
      expect(v.parse('1,234', pattern: '#,##0', locale: us), 1234);
      expect(v.isValid('1,234', pattern: '#,##0', locale: us), isTrue);
    });

    test('blank and null', () {
      expect(v.parse(null, locale: us), isNull);
      expect(v.parse('', locale: us), isNull);
      expect(v.parse('   ', locale: us), isNull);
    });
  });

  group('LongValidator', () {
    final v = LongValidator.getInstance();
    test('the 64-bit boundary', () {
      // The bounds are built with int.parse rather than written as literals: a
      // literal 9223372036854775807 does not *compile* for the web, so having
      // one anywhere in the package would break Flutter web builds outright.
      expect(
        v.parse('9223372036854775807', locale: us),
        int.parse('9223372036854775807'),
      );
      // Upstream rejects this because NumberFormat hands it back as a Double
      // rather than a Long, not because of an explicit bound.
      expect(v.parse('9223372036854775808', locale: us), isNull);
      expect(
        v.parse('-9223372036854775808', locale: us),
        int.parse('-9223372036854775808'),
      );
      expect(v.parse('-9223372036854775809', locale: us), isNull);
    }, testOn: 'vm');
  });

  group('FloatValidator', () {
    final v = FloatValidator.getInstance();

    test('results are narrowed to 32-bit precision, as Java casts to float',
        () {
      expect(v.parse('2147483647', locale: us), 2147483648.0);
      expect(v.parse('1.5', locale: us), 1.5);
    });

    test('the float bounds are the exact widened values', () {
      // Java rejects the *printed* Float.MAX_VALUE because as a double it is
      // slightly larger than the real maximum.
      expect(v.parse('3.4028235E38', locale: us), isNull);
      expect(v.parse('1.4E-45', locale: us), isNull);
      expect(v.parse('3.4028234663852886E38', locale: us), isNotNull);
    });

    test('an underflowing exponent reaches zero before the bounds check', () {
      // 1E-400 is already 0.0 as a double, so `value > 0` and `value < 0` are
      // both false and the subnormal bound is never consulted. Java returns
      // 0.0f here too - verified against the JVM.
      expect(v.parse('1E-400', locale: us), 0.0);
    });
  });

  group('DoubleValidator', () {
    final v = DoubleValidator.getInstance();
    test('has no range check at all and accepts infinity', () {
      // The asymmetry with FloatValidator is upstream's.
      expect(v.parse('2E308', locale: us), double.infinity);
      expect(v.parse('1234.5', locale: us), 1234.5);
    });
  });

  group('BigDecimalValidator', () {
    final v = BigDecimalValidator.getInstance();

    test('parses exactly, past the range of a double', () {
      expect(v.parse('9223372036854775808', locale: us),
          Decimal.parse('9223372036854775808'));
      expect(v.parse('1234.567', locale: us), Decimal.parse('1234.567'));
    });

    test('a strict pattern truncates toward zero, it does not round', () {
      // Java's setScale(2, ROUND_DOWN).
      expect(v.parse('1234.567', pattern: '#,##0.00', locale: us),
          Decimal.parse('1234.56'));
      expect(v.parse('1234.999', pattern: '#,##0.00', locale: us),
          Decimal.parse('1234.99'));
    });

    test('range checks are exact', () {
      final ten = Decimal.fromInt(10);
      expect(v.isInRange(ten, Decimal.zero, Decimal.fromInt(20)), isTrue);
      expect(
          v.isInRange(ten, Decimal.fromInt(11), Decimal.fromInt(20)), isFalse);
    });
  });

  group('BigIntegerValidator', () {
    final v = BigIntegerValidator.getInstance();

    test('parses exactly past 64 bits', () {
      expect(v.parse('9223372036854775808', locale: us),
          BigInt.parse('9223372036854775808'));
    });

    test('rejects a fractional value arriving through an exponent', () {
      // parseIntegerOnly stops at a decimal separator but *not* at an exponent,
      // so `15E-1` reaches this validator as 1.5 and only its own guard rejects
      // it. This is the single reason that guard exists upstream.
      expect(v.parse('15E-1', locale: us), isNull);
      expect(v.parse('1E3', locale: us), BigInt.from(1000));
    });
  });

  group('CurrencyValidator', () {
    final v = CurrencyValidator.getInstance();

    test('accepts the symbol', () {
      expect(v.parse(r'$1,234.56', locale: us), Decimal.parse('1234.56'));
      expect(v.parse(r'-$1,234.56', locale: us), Decimal.parse('-1234.56'));
    });

    test('retries without the symbol when it is absent', () {
      // A locale currency format requires its symbol, so the bare number fails
      // the first parse; upstream rewrites the pattern and retries.
      expect(v.parse('1,234.56', locale: us), Decimal.parse('1234.56'));
    });

    test('an accounting-style negative is not accepted', () {
      expect(v.parse(r'($1,234.56)', locale: us), isNull);
    });
  });

  group('PercentValidator', () {
    final v = PercentValidator.getInstance();

    test('divides by a hundred', () {
      expect(v.parse('12%', locale: us), Decimal.parse('0.12'));
      expect(v.parse('-12%', locale: us), Decimal.parse('-0.12'));
    });

    test('a strict percent truncates to two decimal places', () {
      // determineScale adds 2 for the x100 multiplier, and the result is
      // truncated toward zero - so 0.125 becomes 0.12, not 0.13. Confirmed
      // against the JVM.
      expect(v.parse('12.5%', locale: us), Decimal.parse('0.12'));
      expect(v.parse('0.12', locale: us), Decimal.zero);
    });

    test('retries without the percent sign, applying the multiplier by hand',
        () {
      expect(v.parse('12', locale: us), Decimal.parse('0.12'));
    });
  });

  group('locale handling', () {
    test('separators follow the locale', () {
      final v = BigDecimalValidator.getInstance();
      expect(v.parse('1.234,56', locale: 'de_DE'), Decimal.parse('1234.56'));
      expect(v.parse('1,234.56', locale: 'en_US'), Decimal.parse('1234.56'));
      // In de_DE a dot is the *grouping* separator, so this is 123456.
      expect(v.parse('1234.56', locale: 'de_DE'), Decimal.parse('123456'));
    });

    test('non-breaking grouping separators are handled', () {
      final v = BigDecimalValidator.getInstance();
      // fr groups with U+202F, ru with U+00A0. Using Dart's String.trim instead
      // of javaTrim would strip these and change the result.
      expect(v.parse('1 234', locale: 'fr_FR'), Decimal.fromInt(1234));
      expect(v.parse('1 234', locale: 'ru_RU'), Decimal.fromInt(1234));
    });

    test('a locale whose minus sign is not a hyphen', () {
      // sv uses U+2212 MINUS SIGN.
      expect(
        BigDecimalValidator.getInstance().parse('−1234', locale: 'sv_SE'),
        Decimal.fromInt(-1234),
      );
    });
  });

  group('the parser reproduces ParsePosition', () {
    test('consumed length is tracked, which is what strict tests', () {
      final spec = NumberSpec.forLocale(us).withParseIntegerOnly(true);
      final result = parseDecimal('1234.5', spec)!;
      expect(result.value, Decimal.fromInt(1234));
      expect(result.consumed, 4, reason: 'stops at the decimal separator');

      final full = parseDecimal('1234', spec)!;
      expect(full.consumed, 4);
    });

    test('a failed parse is distinct from leftover input', () {
      final spec = NumberSpec.forLocale(us);
      expect(parseDecimal('abc', spec), isNull, reason: 'parse error');
      expect(parseDecimal('1234abc', spec)!.consumed, 4, reason: 'leftover');
    });
  });

  group('Unicode digits', () {
    test('are accepted, as Java accepts them', () {
      // The opposite of the check-digit routines: DecimalFormat falls back to
      // Character.digit, so these parse. Verified against the JVM.
      final v = IntegerValidator.getInstance();
      expect(v.parse('١٢٣', locale: us), 123, reason: 'Arabic-Indic');
      expect(v.parse('１２３', locale: us), 123, reason: 'fullwidth');
    });
  });

  test('an exponent may not carry a plus sign', () {
    // Java stops at the `E`, leaving `E+3` over, so a strict parse fails.
    final v = IntegerValidator.getInstance();
    expect(v.parse('1E+3', locale: us), isNull);
    expect(const IntegerValidator(strict: false).parse('1E+3', locale: us), 1);
    expect(v.parse('1E3', locale: us), 1000);
  });
}
