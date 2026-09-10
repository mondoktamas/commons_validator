import 'package:commons_validator/src/routines/calendar_fields.dart';
import 'package:commons_validator/src/routines/date_validators.dart';
import 'package:test/test.dart';

/// Ported from `DateValidatorTest`, `CalendarValidatorTest` and
/// `TimeValidatorTest`.
///
/// Every expectation was checked against OpenJDK 17.0.18. Comparisons run in UTC
/// with the US week rules, because Java takes those from the default locale and
/// upstream's tests mutate that global - which Dart has no equivalent of.
void main() {
  final dv = DateValidator.getInstance();
  final cv = CalendarValidator.getInstance();
  final tv = TimeValidator.getInstance();

  DateTime utc(int y,
          [int m = 1,
          int d = 1,
          int h = 0,
          int mi = 0,
          int s = 0,
          int ms = 0]) =>
      DateTime.utc(y, m, d, h, mi, s, ms);

  CalendarFields fields(DateTime d) =>
      CalendarFields.fromDateTime(d, zoneOffset: Duration.zero);

  group('DateValidator parsing', () {
    test('a valid date', () {
      expect(dv.parse('2026-06-15', pattern: 'yyyy-MM-dd'), utc(2026, 6, 15));
      expect(dv.isValid('2026-06-15', pattern: 'yyyy-MM-dd'), isTrue);
    });

    test('out-of-range fields are rejected, not rolled over', () {
      // Java always parses with setLenient(false).
      expect(dv.parse('2026-13-01', pattern: 'yyyy-MM-dd'), isNull);
      expect(dv.parse('2026-02-30', pattern: 'yyyy-MM-dd'), isNull);
      expect(dv.parse('2026-06-31', pattern: 'yyyy-MM-dd'), isNull);
      expect(dv.parse('2026-00-01', pattern: 'yyyy-MM-dd'), isNull);
    });

    test('a leap day', () {
      expect(dv.parse('2024-02-29', pattern: 'yyyy-MM-dd'), utc(2024, 2, 29));
      expect(dv.parse('2026-02-29', pattern: 'yyyy-MM-dd'), isNull);
    });

    test('strict rejects trailing text, lenient keeps the prefix', () {
      expect(dv.parse('2026-06-15x', pattern: 'yyyy-MM-dd'), isNull);
      expect(
        const DateValidator(strict: false)
            .parse('2026-06-15x', pattern: 'yyyy-MM-dd'),
        utc(2026, 6, 15),
      );
    });

    test('a lenient parse never salvages an invalid date by truncating it', () {
      // Cutting `2026-02-30` down to `2026-02-3` would give 3 February, which
      // Java never does - so the prefix search refuses to split a digit run.
      expect(
        const DateValidator(strict: false)
            .parse('2026-02-30', pattern: 'yyyy-MM-dd'),
        isNull,
      );
    });

    test('adjacent numeric fields, which intl cannot parse unaided', () {
      expect(dv.parse('20260615', pattern: 'yyyyMMdd'), utc(2026, 6, 15));
      expect(dv.parse('15062026', pattern: 'ddMMyyyy'), utc(2026, 6, 15));
      // Java treats the widths as maxima and lets the last field take the rest.
      expect(dv.parse('2026061', pattern: 'yyyyMMdd'), utc(2026, 6, 1));
    });

    test('blank and null', () {
      expect(dv.parse(null, pattern: 'yyyy-MM-dd'), isNull);
      expect(dv.parse('', pattern: 'yyyy-MM-dd'), isNull);
      expect(dv.parse('   ', pattern: 'yyyy-MM-dd'), isNull);
    });

    test('a two-digit year uses Java moving window, not a fixed one', () {
      // SimpleDateFormat pivots on 80 years back from now, so the century of a
      // two-digit year depends on the current year. intl would use a fixed
      // 1969-2068 window.
      final now = DateTime.now().year;
      final parsed = dv.parse('26-06-15', pattern: 'yy-MM-dd')!;
      expect(parsed.year, greaterThanOrEqualTo(now - 80));
      expect(parsed.year, lessThan(now + 20));
      expect(parsed.year % 100, 26);
    });

    test('a year field given more than two digits is literal', () {
      // Java applies no pivot at all when more digits are supplied.
      expect(dv.parse('0001-01-01', pattern: 'yy-MM-dd'), utc(1));
      expect(dv.parse('9999-12-31', pattern: 'yy-MM-dd'), utc(9999, 12, 31));
    });
  });

  group('DateValidator comparisons', () {
    final base = utc(2026, 6, 15, 12, 0, 0);

    test('compareDates', () {
      expect(dv.compareDates(base, utc(2026, 6, 15, 23, 59)), 0,
          reason: 'same day, different time');
      expect(dv.compareDates(base, utc(2026, 6, 16)), lessThan(0));
      expect(dv.compareDates(base, utc(2026, 6, 14)), greaterThan(0));
    });

    test('compareMonths', () {
      expect(dv.compareMonths(base, utc(2026, 6, 1)), 0);
      expect(dv.compareMonths(base, utc(2026, 7, 1)), lessThan(0));
      expect(dv.compareMonths(base, utc(2025, 6, 1)), greaterThan(0));
    });

    test('compareYears', () {
      expect(dv.compareYears(base, utc(2026, 1, 1)), 0);
      expect(dv.compareYears(base, utc(2027, 1, 1)), lessThan(0));
    });

    test('compareWeeks is instant-distance based', () {
      // Same week only when strictly under seven days apart *and* the week
      // numbers agree.
      expect(dv.compareWeeks(base, base.add(const Duration(days: 1))), 0);
      expect(dv.compareWeeks(base, base.add(const Duration(days: 7))),
          lessThan(0));
      expect(
        dv.compareWeeks(base, base.subtract(const Duration(days: 7))),
        greaterThan(0),
      );
    });

    test('compareQuarters takes a one-based month of first quarter', () {
      final q1 = utc(2026, 2, 15);
      final q2 = utc(2026, 5, 15);
      expect(dv.compareQuartersOf(q1, q2), lessThan(0));
      expect(dv.compareQuartersOf(q1, q1), 0);
      // With the year starting in February, both fall in the same quarter.
      expect(
          dv.compareQuartersOf(utc(2026, 2, 1), utc(2026, 4, 1),
              monthOfFirstQuarter: 2),
          0);
      // A month before the first quarter belongs to the previous year.
      expect(
          dv.compareQuartersOf(utc(2026, 1, 1), utc(2026, 2, 1),
              monthOfFirstQuarter: 2),
          lessThan(0));
    });
  });

  group('CalendarValidator', () {
    test('returns fields rather than a mutable Calendar', () {
      final f = cv.parse('2026-06-15', pattern: 'yyyy-MM-dd')!;
      expect(f.year, 2026);
      expect(f.month, 6, reason: 'one-based, unlike Calendar.MONTH');
      expect(f.day, 15);
      expect(f.hour, 0);
    });

    test('adjustToTimeZone keeps the wall clock and moves the instant', () {
      final f = cv.parse('2026-06-15', pattern: 'yyyy-MM-dd')!;
      final shifted = cv.adjustToTimeZone(f, const Duration(hours: 5));
      expect(shifted.year, f.year);
      expect(shifted.day, f.day);
      expect(shifted.hour, f.hour);
      expect(shifted.instant, isNot(f.instant));
    });

    test('comparisons', () {
      final a = fields(utc(2026, 6, 15, 12));
      final b = fields(utc(2026, 6, 15, 18));
      expect(cv.compareDates(a, b), 0);
      expect(cv.compareMonths(a, fields(utc(2026, 7, 1))), lessThan(0));
      expect(cv.compareYears(a, fields(utc(2025, 1, 1))), greaterThan(0));
    });
  });

  group('TimeValidator', () {
    test('parses a time onto the epoch date, as Java does', () {
      final f = tv.parse('12:30:45', pattern: 'HH:mm:ss')!;
      expect(f.hour, 12);
      expect(f.minute, 30);
      expect(f.second, 45);
      expect(f.year, 1970, reason: 'unset date fields default to the epoch');
    });

    test('out-of-range times are rejected', () {
      expect(tv.parse('24:00', pattern: 'HH:mm'), isNull);
      expect(tv.parse('12:60', pattern: 'HH:mm'), isNull);
      expect(tv.parse('12:30:60', pattern: 'HH:mm:ss'), isNull);
    });

    test('comparisons at each granularity', () {
      final a = fields(utc(1970, 1, 1, 12, 30, 45, 123));
      final sameHour = fields(utc(1970, 1, 1, 12, 59, 59, 999));
      final laterHour = fields(utc(1970, 1, 1, 13));

      expect(tv.compareHours(a, sameHour), 0);
      expect(tv.compareHours(a, laterHour), lessThan(0));
      expect(tv.compareMinutes(a, sameHour), lessThan(0));
      expect(tv.compareSeconds(a, fields(utc(1970, 1, 1, 12, 30, 45, 999))), 0);
      expect(tv.compareTimes(a, fields(utc(1970, 1, 1, 12, 30, 45, 124))),
          lessThan(0));
      expect(tv.compareTimes(a, a), 0);
    });

    test('the 12-hour field compares using the 24-hour value', () {
      // Upstream's compareTime treats Calendar.HOUR as HOUR_OF_DAY, so 1am and
      // 1pm do not compare equal.
      final oneAm = fields(utc(1970, 1, 1, 1));
      final onePm = fields(utc(1970, 1, 1, 13));
      expect(tv.compareHours(oneAm, onePm), lessThan(0));
    });
  });

  group('CalendarFields week numbering', () {
    test('matches Java for the US rules', () {
      // 2026-01-01 is a Thursday; with firstDayOfWeek=Sunday and
      // minimalDays=1 that is week 1.
      final jan1 = CalendarFields(year: 2026);
      expect(jan1.dayOfYear, 1);
      expect(jan1.weekOfYear, 1);
    });

    test('matches Java for the ISO rules', () {
      // Monday start, four days minimum: 2026-01-01 (a Thursday) is week 1,
      // but 2021-01-01 (a Friday) belongs to week 53 of 2020.
      final iso2026 = CalendarFields(
        year: 2026,
        firstDayOfWeek: DayOfWeek.monday,
        minimalDaysInFirstWeek: 4,
      );
      expect(iso2026.weekOfYear, 1);

      final iso2021 = CalendarFields(
        year: 2021,
        firstDayOfWeek: DayOfWeek.monday,
        minimalDaysInFirstWeek: 4,
      );
      expect(iso2021.weekOfYear, 53);
    });

    test('week of month can be zero in a partial first week', () {
      final f = CalendarFields(
        year: 2026,
        month: 8,
        day: 1,
        firstDayOfWeek: DayOfWeek.monday,
        minimalDaysInFirstWeek: 4,
      );
      // 2026-08-01 is a Saturday, so it falls in a partial first week.
      expect(f.weekOfMonth, 0);
    });
  });
}
