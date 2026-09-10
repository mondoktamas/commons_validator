import 'package:intl/intl.dart';

import '../generic_validator.dart';
import '../internal/java_compat.dart';
import 'calendar_fields.dart';

export 'calendar_fields.dart';

/// How much of a date or time a locale format should show.
///
/// Maps `java.text.DateFormat`'s style constants onto the nearest `intl`
/// skeletons. The mapping is approximate by nature - Java's `SHORT` for `en_US`
/// uses a two-digit year where `intl`'s equivalent uses four - so pass an
/// explicit pattern when exact agreement with the JVM matters.
enum DateStyle {
  /// Java's `DateFormat.SHORT`.
  short,

  /// Java's `DateFormat.MEDIUM`.
  medium,

  /// Java's `DateFormat.LONG`.
  long,

  /// Java's `DateFormat.FULL`.
  full,
}

/// Base class for the date, calendar and time validators.
///
/// Ported from `AbstractCalendarValidator`.
///
/// Java always parses with `setLenient(false)`, so out-of-range fields such as
/// month 13 or 30 February are rejected rather than rolled over; the validator's
/// own `strict` flag controls only whether *trailing input* is tolerated. `intl`
/// bundles both behaviours into `parseStrict`, so lenient mode is rebuilt here
/// as a longest-valid-prefix search - keeping the calendar range checks while
/// allowing a tail.
abstract class AbstractCalendarValidator<T> {
  /// Creates a validator.
  const AbstractCalendarValidator({
    required this.strict,
    this.dateStyle,
    this.timeStyle,
  });

  /// Whether the whole input must be consumed.
  final bool strict;

  /// The date portion's style, or null for a time-only validator.
  final DateStyle? dateStyle;

  /// The time portion's style, or null for a date-only validator.
  final DateStyle? timeStyle;

  /// Whether [value] parses.
  bool isValid(String? value, {String? pattern, String? locale}) =>
      parse(value, pattern: pattern, locale: locale) != null;

  /// The parsed value, or null if [value] is not a valid date or time.
  ///
  /// [zoneOffset] plays the role of Java's `TimeZone` argument; when omitted the
  /// value is read as UTC.
  T? parse(
    String? value, {
    String? pattern,
    String? locale,
    Duration? zoneOffset,
  }) {
    final trimmed = value == null ? null : javaTrim(value);
    if (GenericValidator.isBlankOrNull(trimmed)) return null;
    final format = formatFor(pattern: pattern, locale: locale);
    final parsed = _parseWithFormat(format, trimmed!, pattern);
    if (parsed == null) return null;
    return processParsedValue(parsed, zoneOffset ?? Duration.zero);
  }

  /// Formats [value] with the same format the validator parses with.
  String? format(
    DateTime? value, {
    String? pattern,
    String? locale,
    Duration? zoneOffset,
  }) {
    if (value == null) return null;
    final shifted = zoneOffset == null ? value : value.toUtc().add(zoneOffset);
    return formatFor(pattern: pattern, locale: locale).format(shifted);
  }

  /// The `intl` format for the given [pattern] and [locale].
  DateFormat formatFor({String? pattern, String? locale}) {
    if (pattern != null && javaTrim(pattern).isNotEmpty) {
      return DateFormat(pattern, locale);
    }
    final date = dateStyle;
    final time = timeStyle;
    if (date != null && time != null) {
      return _dateFormatFor(date, locale).add_jms();
    }
    if (time != null) {
      return _timeFormatFor(time, locale);
    }
    // A date-only validator defaults to SHORT, as upstream does.
    return _dateFormatFor(date ?? DateStyle.short, locale);
  }

  static DateFormat _dateFormatFor(DateStyle style, String? locale) =>
      switch (style) {
        DateStyle.short => DateFormat.yMd(locale),
        DateStyle.medium => DateFormat.yMMMd(locale),
        DateStyle.long => DateFormat.yMMMMd(locale),
        DateStyle.full => DateFormat.yMMMMEEEEd(locale),
      };

  static DateFormat _timeFormatFor(DateStyle style, String? locale) =>
      switch (style) {
        DateStyle.short => DateFormat.jm(locale),
        DateStyle.medium ||
        DateStyle.long ||
        DateStyle.full =>
          DateFormat.jms(locale),
      };

  /// Parses [value], honouring [strict].
  DateTime? _parseWithFormat(DateFormat format, String value, String? pattern) {
    var effectiveFormat = format;
    var effectiveValue = value;

    // `intl` cannot parse adjacent numeric fields: for `yyyyMMdd` it reads
    // `yyyy` greedily, swallows all eight digits and then fails looking for
    // `MM`. Java resolves these by field width, so do the same by splitting both
    // pattern and input at the width boundaries before handing them over.
    var pivotPattern = pattern;
    if (pattern != null) {
      // A `yy` field handed more than two digits is read literally by Java, with
      // no century pivot at all: `0001-01-01` under `yy-MM-dd` is year 1, not
      // 2001. Widening the pattern makes `intl` agree and disables the pivot.
      //
      // Only act when the digit count is actually known. A run length of -1
      // means "could not tell", and the pivot has to stay: treating -1 like
      // "not two digits" silently disabled the pivot for every pattern whose
      // year is not the first field, which is most of them - `MM/dd/yy` and
      // `dd/MM/yy` included.
      final yearDigits =
          _hasTwoDigitYear(pattern) ? _yearRunLength(pattern, value) : -1;
      if (yearDigits > 0 && yearDigits != 2) {
        effectiveFormat = DateFormat(_widenYearField(pattern), format.locale);
        pivotPattern = null;
      }
      final split = _splitAdjacentNumericFields(
        effectiveFormat.pattern ?? pattern,
        value,
      );
      if (split == null) return null;
      if (split.pattern != (effectiveFormat.pattern ?? pattern)) {
        effectiveFormat = DateFormat(split.pattern, format.locale);
        effectiveValue = split.value;
      }
    }

    final parsed = strict
        ? _parseExactly(effectiveFormat, effectiveValue)
        : _parseLongestPrefix(effectiveFormat, effectiveValue);
    if (parsed == null) return null;
    final pivoted = _applyTwoDigitYearPivot(parsed, pivotPattern);
    // The Gregorian era has no year 0 - 1 BC is followed by 1 AD - and Java's
    // non-lenient GregorianCalendar rejects it. `intl` will happily hand one
    // back, so `0000-10-28` has to be refused here.
    if (pivoted != null && pivoted.year == 0) return null;
    return pivoted;
  }

  static DateTime? _parseExactly(DateFormat format, String value) {
    try {
      return format.parseStrict(value, true);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  /// The longest prefix of [value] that parses strictly.
  ///
  /// This is how lenient mode keeps Java's non-lenient calendar range checks
  /// while still tolerating trailing text, which `intl` offers no flag for.
  ///
  /// A cut is only allowed where it would not split a run of digits. Without
  /// that rule `2026-02-30` would be salvaged as `2026-02-3`, i.e. 3 February,
  /// where Java rejects the input outright because 30 February does not exist.
  static DateTime? _parseLongestPrefix(DateFormat format, String value) {
    for (var end = value.length; end > 0; end--) {
      if (end < value.length &&
          _isDigit(value.codeUnitAt(end - 1)) &&
          _isDigit(value.codeUnitAt(end))) {
        continue; // would cut a number in half
      }
      final parsed = _parseExactly(format, value.substring(0, end));
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  /// Fixed field widths for the numeric pattern letters, as Java uses them when
  /// numeric fields sit next to each other.
  static const Map<String, int> _numericFieldWidths = {
    'yyyy': 4,
    'yy': 2,
    'MM': 2,
    'dd': 2,
    'HH': 2,
    'hh': 2,
    'mm': 2,
    'ss': 2,
    'SSS': 3,
    'DDD': 3,
  };

  /// Rewrites [pattern] and [value] so no two numeric fields are adjacent.
  ///
  /// Returns null when [value] does not supply the digits the widths demand;
  /// returns the inputs unchanged when the pattern has no adjacent numeric
  /// fields.
  static ({String pattern, String value})? _splitAdjacentNumericFields(
    String pattern,
    String value,
  ) {
    final runs = _numericRuns(pattern);
    if (runs.length < 2) return (pattern: pattern, value: value);

    // Only act when two runs actually touch.
    var adjacent = false;
    for (var i = 1; i < runs.length; i++) {
      if (runs[i - 1].end == runs[i].start) {
        adjacent = true;
        break;
      }
    }
    if (!adjacent) return (pattern: pattern, value: value);

    const separator = '\u0001';
    final newPattern = StringBuffer();
    final newValue = StringBuffer();
    var patternCursor = 0;
    var valueCursor = 0;

    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      // Literal text before this run is copied through and matched in the input.
      final literal = pattern.substring(patternCursor, run.start);
      newPattern.write(literal);
      if (literal.isNotEmpty) {
        if (!value.startsWith(literal, valueCursor)) return null;
        newValue.write(literal);
        valueCursor += literal.length;
      }
      // Java treats these widths as maxima, and lets the *last* field take
      // whatever digits are left - so `2026061` under `yyyyMMdd` is 2026-06-01.
      var width = run.width;
      final isLast = i == runs.length - 1;
      if (valueCursor + width > value.length) {
        if (!isLast) return null;
        width = value.length - valueCursor;
        if (width < 1) return null;
      }
      final digits = value.substring(valueCursor, valueCursor + width);
      for (final unit in digits.codeUnits) {
        if (!_isDigit(unit)) return null;
      }
      newPattern.write(pattern.substring(run.start, run.end));
      newValue.write(digits);
      valueCursor += width;
      patternCursor = run.end;
      // Insert a separator between two touching runs.
      if (i + 1 < runs.length && runs[i + 1].start == run.end) {
        newPattern.write(separator);
        newValue.write(separator);
      }
    }
    newPattern.write(pattern.substring(patternCursor));
    newValue.write(value.substring(valueCursor));
    return (pattern: newPattern.toString(), value: newValue.toString());
  }

  /// The runs of repeated numeric pattern letters in [pattern].
  static List<({int start, int end, int width})> _numericRuns(String pattern) {
    final runs = <({int start, int end, int width})>[];
    var i = 0;
    while (i < pattern.length) {
      final ch = pattern[i];
      var j = i;
      while (j < pattern.length && pattern[j] == ch) {
        j++;
      }
      final token = pattern.substring(i, j);
      final width = _numericFieldWidths[token];
      if (width != null) {
        runs.add((start: i, end: j, width: width));
      }
      i = j;
    }
    return runs;
  }

  /// Re-pivots a two-digit year onto Java's moving window.
  ///
  /// `SimpleDateFormat` resolves `yy` into the hundred years beginning at the
  /// *instant* eighty years before the formatter was created, and the resolved
  /// **date** has to fall inside it - not merely the year. Measured against
  /// OpenJDK on 2026-09-10, `46` gives 2046 while `47` gives 1947, because
  /// 1946-01-01 falls before the 1946-09-10 window start. A year-only
  /// approximation gets that boundary wrong, and which side it lands on shifts
  /// with today's month and day.
  ///
  /// `intl` instead uses a fixed 1969-2068 window, so this has to be applied by
  /// hand either way.
  static DateTime? _applyTwoDigitYearPivot(DateTime? parsed, String? pattern) {
    if (parsed == null || pattern == null) return parsed;
    if (!_hasTwoDigitYear(pattern)) return parsed;

    final now = DateTime.now();
    final windowStart = DateTime.utc(now.year - 80, now.month, now.day);
    final twoDigits = parsed.year % 100;

    DateTime withYear(int year) => DateTime.utc(
          year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
        );

    var candidate =
        withYear(windowStart.year - (windowStart.year % 100) + twoDigits);
    if (candidate.isBefore(windowStart)) {
      candidate = withYear(candidate.year + 100);
    }
    return candidate;
  }

  /// How many digits [value] actually supplies for [pattern]'s `yy` field.
  ///
  /// Returns -1 when it cannot be determined, in which case the caller keeps the
  /// century pivot rather than guessing.
  ///
  /// The year need not be the first field: pattern and input are walked in step
  /// through the preceding literals and numeric runs, so `MM/dd/yy` against
  /// `12/31/99` correctly reports two digits.
  static int _yearRunLength(String pattern, String value) {
    final yearIndex = pattern.indexOf('yy');
    if (yearIndex < 0) return -1;

    final runs = _numericRuns(pattern);

    // Where numeric fields abut, Java honours the declared width exactly rather
    // than reading greedily, so a `yy` there is always two digits: `yyMMdd`
    // against `460330` is 2046-03-30, and against `20460330` it is invalid
    // because `yy` takes `20` and `MM` then sees `46`. Measuring greedily here
    // would widen the pattern and quietly accept both.
    for (var i = 0; i < runs.length; i++) {
      if (runs[i].start != yearIndex) continue;
      final touchesPrevious = i > 0 && runs[i - 1].end == runs[i].start;
      final touchesNext =
          i + 1 < runs.length && runs[i + 1].start == runs[i].end;
      if (touchesPrevious || touchesNext) {
        return 2;
      }
    }

    var patternCursor = 0;
    var valueCursor = 0;

    for (final run in runs) {
      // The literal text before this run must appear verbatim in the input.
      final literal = pattern.substring(patternCursor, run.start);
      if (literal.contains(RegExp('[a-zA-Z]'))) {
        return -1; // a non-numeric field such as MMM; offsets are unknowable
      }
      if (!value.startsWith(literal, valueCursor)) return -1;
      valueCursor += literal.length;

      // Count the digits the input actually supplies for this run.
      var digits = 0;
      while (valueCursor + digits < value.length &&
          _isDigit(value.codeUnitAt(valueCursor + digits))) {
        digits++;
      }
      if (run.start == yearIndex) return digits;
      if (digits == 0) return -1;

      // Any earlier numeric field consumes at most its own width, so that the
      // following literal lines up again.
      valueCursor += digits < run.width ? digits : run.width;
      patternCursor = run.end;
    }
    return -1;
  }

  /// Replaces a `yy` field with `yyyy`, so `intl` reads the year literally.
  static String _widenYearField(String pattern) =>
      pattern.replaceFirst(RegExp('(?<!y)yy(?!y)'), 'yyyy');

  /// Whether [pattern] contains exactly two `y` characters in a row.
  static bool _hasTwoDigitYear(String pattern) =>
      RegExp('(?<!y)yy(?!y)').hasMatch(pattern);

  /// Converts a parsed instant into the validator's own type.
  T? processParsedValue(DateTime parsed, Duration zoneOffset);

  /// Compares [value] and [other] down to [field].
  ///
  /// Transcribed from `AbstractCalendarValidator.compare`, whose ordering is
  /// deliberate and unusual:
  ///
  /// * week fields are handled *before* the year comparison;
  /// * [CalendarField.dayOfWeek] and [CalendarField.dayOfWeekInMonth] compare
  ///   down to the day rather than by weekday number;
  /// * [CalendarField.hour] compares using the 24-hour value.
  int compare(CalendarFields value, CalendarFields other, CalendarField field) {
    if (field == CalendarField.weekOfYear ||
        field == CalendarField.weekOfMonth) {
      return _compareWeek(value, other, field);
    }

    var result = value.year.compareTo(other.year);
    if (result != 0 || field == CalendarField.year) return result;

    if (field == CalendarField.dayOfYear) {
      return value.dayOfYear.compareTo(other.dayOfYear);
    }

    result = value.month.compareTo(other.month);
    if (result != 0 || field == CalendarField.month) return result;

    result = value.day.compareTo(other.day);
    if (result != 0 ||
        field == CalendarField.date ||
        field == CalendarField.dayOfWeek ||
        field == CalendarField.dayOfWeekInMonth) {
      return result;
    }

    return compareTime(value, other, field);
  }

  /// Compares the time portion of [value] and [other] down to [field].
  int compareTime(
    CalendarFields value,
    CalendarFields other,
    CalendarField field,
  ) {
    var result = value.hour.compareTo(other.hour);
    // Java's 12-hour HOUR field is compared using the 24-hour value.
    if (result != 0 ||
        field == CalendarField.hour ||
        field == CalendarField.hourOfDay) {
      return result;
    }

    result = value.minute.compareTo(other.minute);
    if (result != 0 || field == CalendarField.minute) return result;

    result = value.second.compareTo(other.second);
    if (result != 0 || field == CalendarField.second) return result;

    return value.millisecond.compareTo(other.millisecond);
  }

  /// Compares by quarter, with [monthOfFirstQuarter] one-based.
  int compareQuarters(
    CalendarFields value,
    CalendarFields other,
    int monthOfFirstQuarter,
  ) =>
      value
          .quarterKey(monthOfFirstQuarter)
          .compareTo(other.quarterKey(monthOfFirstQuarter));

  /// Milliseconds in a week, `TimeUnit.DAYS.toMillis(7)`.
  static const int millisPerWeek = 604800000;

  /// Compares by week, using instant distance rather than year-then-week.
  ///
  /// Two instants share a week only when they are strictly less than seven days
  /// apart *and* their week numbers agree; the ordering is the sign of the
  /// instant difference.
  int _compareWeek(
    CalendarFields value,
    CalendarFields other,
    CalendarField field,
  ) {
    final millis = value.millisecondsSinceEpoch - other.millisecondsSinceEpoch;
    final sameNumber = field == CalendarField.weekOfYear
        ? value.weekOfYear == other.weekOfYear
        : value.weekOfMonth == other.weekOfMonth;
    if (millis.abs() >= millisPerWeek || !sameNumber) {
      return millis == 0 ? 0 : (millis < 0 ? -1 : 1);
    }
    return 0;
  }
}
