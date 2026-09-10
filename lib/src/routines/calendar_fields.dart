/// An immutable snapshot of the calendar fields Commons Validator compares.
///
/// Java's validators return a `java.util.Calendar`, a mutable field bag whose
/// unset fields default to the 1970-01-01 epoch and whose week numbering comes
/// from the default locale. Dart's [DateTime] has no field-set concept, no
/// week-of-year, and no locale-sensitive week rules, so the fields are modelled
/// explicitly here.
library;

/// Which field a comparison should stop at.
///
/// Replaces the `Calendar.FIELD` integer constants. Upstream throws
/// `IllegalArgumentException` for a field its time comparison does not handle;
/// an enum turns that into a compile-time guarantee.
enum CalendarField {
  /// Compare years only.
  year,

  /// Compare down to the month.
  month,

  /// Compare down to the day of the month.
  date,

  /// Compare the day of the year, within the same year.
  dayOfYear,

  /// Compare down to the day. Despite the name this does *not* compare weekday
  /// numbers - upstream falls through to the day comparison.
  dayOfWeek,

  /// As [dayOfWeek]; also compares down to the day.
  dayOfWeekInMonth,

  /// Compare by week of year.
  weekOfYear,

  /// Compare by week of month.
  weekOfMonth,

  /// Compare down to the hour. Uses the 24-hour value even though the name
  /// refers to Java's 12-hour field.
  hour,

  /// Compare down to the hour.
  hourOfDay,

  /// Compare down to the minute.
  minute,

  /// Compare down to the second.
  second,

  /// Compare down to the millisecond.
  millisecond,
}

/// Java's `Calendar.SUNDAY` through `Calendar.SATURDAY`, 1 through 7.
class DayOfWeek {
  const DayOfWeek._();

  /// `Calendar.SUNDAY`.
  static const int sunday = 1;

  /// `Calendar.MONDAY`.
  static const int monday = 2;

  /// `Calendar.SATURDAY`.
  static const int saturday = 7;
}

/// A date and time broken into fields, with an explicit zone offset.
///
/// [zoneOffset] replaces `java.util.TimeZone`. Dart's [DateTime] supports only
/// local time and UTC, so a fixed offset is used; full IANA zone support would
/// mean depending on `package:timezone`, and `TimeZone.hasSameRules` has no
/// equivalent at all.
class CalendarFields implements Comparable<CalendarFields> {
  /// Creates a field set.
  ///
  /// [firstDayOfWeek] and [minimalDaysInFirstWeek] drive week numbering and so
  /// affect [weekOfYear], [weekOfMonth] and week comparisons. They default to
  /// the US rules Java uses for `en_US`.
  CalendarFields({
    required this.year,
    this.month = 1,
    this.day = 1,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
    this.zoneOffset = Duration.zero,
    this.firstDayOfWeek = DayOfWeek.sunday,
    this.minimalDaysInFirstWeek = 1,
  });

  /// The fields of [dateTime], read in its own zone.
  factory CalendarFields.fromDateTime(
    DateTime dateTime, {
    Duration? zoneOffset,
    int firstDayOfWeek = DayOfWeek.sunday,
    int minimalDaysInFirstWeek = 1,
  }) {
    final offset = zoneOffset ?? dateTime.timeZoneOffset;
    final shifted = dateTime.toUtc().add(offset);
    return CalendarFields(
      year: shifted.year,
      month: shifted.month,
      day: shifted.day,
      hour: shifted.hour,
      minute: shifted.minute,
      second: shifted.second,
      millisecond: shifted.millisecond,
      zoneOffset: offset,
      firstDayOfWeek: firstDayOfWeek,
      minimalDaysInFirstWeek: minimalDaysInFirstWeek,
    );
  }

  /// The year. Note Java's `Calendar.YEAR` is era-relative and its `ERA` is
  /// never consulted by the comparisons, so 1 BC and 1 AD compare equal there.
  final int year;

  /// The month, 1 through 12.
  ///
  /// One-based, unlike `Calendar.MONTH`. The comparison logic is adjusted to
  /// match, and `monthOfFirstQuarter` was already one-based upstream.
  final int month;

  /// The day of the month, 1 through 31.
  final int day;

  /// The hour of day, 0 through 23.
  final int hour;

  /// The minute, 0 through 59.
  final int minute;

  /// The second, 0 through 59.
  final int second;

  /// The millisecond, 0 through 999.
  final int millisecond;

  /// The offset from UTC these fields are expressed in.
  final Duration zoneOffset;

  /// The day the week starts on, as a [DayOfWeek] constant.
  final int firstDayOfWeek;

  /// How many days of a new year must fall in a week for it to count as week 1.
  final int minimalDaysInFirstWeek;

  /// The instant these fields denote.
  DateTime get instant =>
      DateTime.utc(year, month, day, hour, minute, second, millisecond)
          .subtract(zoneOffset);

  /// Milliseconds since the Unix epoch, used by the week comparison.
  int get millisecondsSinceEpoch => instant.millisecondsSinceEpoch;

  /// The day of the year, 1 through 366.
  int get dayOfYear => _fixedDate - _fixedDateOfJanuary1(year) + 1;

  /// The day of the week, `Calendar.SUNDAY` (1) through `Calendar.SATURDAY` (7).
  int get dayOfWeek => _dayOfWeekOf(_fixedDate);

  /// The week of the year, computed with Java's `GregorianCalendar` rules.
  int get weekOfYear {
    final jan1 = _fixedDateOfJanuary1(year);
    var week = _weekNumber(jan1, _fixedDate);
    if (week == 0) {
      // This day belongs to the last week of the previous year.
      final prevJan1 = _fixedDateOfJanuary1(year - 1);
      return _weekNumber(prevJan1, _fixedDate);
    }
    if (week >= 52) {
      // It may instead be week 1 of the next year.
      final nextJan1 = _fixedDateOfJanuary1(year + 1);
      var nextJan1st = _dayOfWeekOnOrBefore(nextJan1 + 6, firstDayOfWeek);
      final days = nextJan1st - nextJan1;
      if (days >= minimalDaysInFirstWeek) nextJan1st -= 7;
      if (_fixedDate >= nextJan1st) week = 1;
    }
    return week;
  }

  /// The week of the month, computed with Java's `GregorianCalendar` rules.
  ///
  /// Can be 0 for a day in a partial first week.
  int get weekOfMonth {
    final firstOfMonth = _fixedDate - day + 1;
    return _weekNumber(firstOfMonth, _fixedDate);
  }

  /// The quarter index Java packs as `year * 10 + quarter`.
  ///
  /// [monthOfFirstQuarter] is **one-based**, as it is upstream.
  int quarterKey(int monthOfFirstQuarter) {
    var quarterYear = year;
    final relativeMonth = month >= monthOfFirstQuarter
        ? month - monthOfFirstQuarter
        : month + 12 - monthOfFirstQuarter;
    final quarter = relativeMonth ~/ 3 + 1;
    if (month < monthOfFirstQuarter) quarterYear--;
    return quarterYear * 10 + quarter;
  }

  /// These fields re-expressed in [offset], keeping the same wall-clock reading.
  ///
  /// Mirrors `CalendarValidator.adjustToTimeZone`, which preserves the year,
  /// month, day, hour and minute and lets the instant move. Seconds and
  /// milliseconds are carried over unchanged, as they are upstream.
  CalendarFields adjustToZone(Duration offset) => CalendarFields(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        zoneOffset: offset,
        firstDayOfWeek: firstDayOfWeek,
        minimalDaysInFirstWeek: minimalDaysInFirstWeek,
      );

  /// The same instant expressed in [offset], so the wall clock shifts.
  CalendarFields toZone(Duration offset) => CalendarFields.fromDateTime(
        instant,
        zoneOffset: offset,
        firstDayOfWeek: firstDayOfWeek,
        minimalDaysInFirstWeek: minimalDaysInFirstWeek,
      );

  /// Days since 1970-01-01 for these fields' date.
  int get _fixedDate =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static int _fixedDateOfJanuary1(int year) =>
      DateTime.utc(year).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  /// 1970-01-01 was a Thursday, which is `Calendar.THURSDAY` (5).
  static int _dayOfWeekOf(int fixedDate) => ((fixedDate + 4) % 7 + 7) % 7 + 1;

  /// The latest day on or before [fixedDate] falling on [targetDayOfWeek].
  static int _dayOfWeekOnOrBefore(int fixedDate, int targetDayOfWeek) {
    final diff = (_dayOfWeekOf(fixedDate) - targetDayOfWeek + 7) % 7;
    return fixedDate - diff;
  }

  /// Java's `GregorianCalendar.getWeekNumber`.
  int _weekNumber(int firstDayOfPeriod, int fixedDate) {
    var firstWeekStart =
        _dayOfWeekOnOrBefore(firstDayOfPeriod + 6, firstDayOfWeek);
    final daysInFirstWeek = firstWeekStart - firstDayOfPeriod;
    if (daysInFirstWeek >= minimalDaysInFirstWeek) firstWeekStart -= 7;
    final normalized = fixedDate - firstWeekStart;
    if (normalized >= 0) return normalized ~/ 7 + 1;
    // Floor division, so a day before the first week start gives 0 or less.
    return ((normalized + 1) ~/ 7) - (normalized % 7 == 0 ? 0 : 1) + 1;
  }

  @override
  int compareTo(CalendarFields other) =>
      millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);

  @override
  bool operator ==(Object other) =>
      other is CalendarFields &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.hour == hour &&
      other.minute == minute &&
      other.second == second &&
      other.millisecond == millisecond &&
      other.zoneOffset == zoneOffset;

  @override
  int get hashCode => Object.hash(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        zoneOffset,
      );

  @override
  String toString() => '$year-${_two(month)}-${_two(day)} '
      '${_two(hour)}:${_two(minute)}:${_two(second)}.'
      '${millisecond.toString().padLeft(3, '0')} '
      '${zoneOffset.isNegative ? '-' : '+'}'
      '${_two(zoneOffset.abs().inHours)}:'
      '${_two(zoneOffset.abs().inMinutes % 60)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
