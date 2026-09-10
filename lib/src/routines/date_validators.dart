import 'abstract_calendar_validator.dart';

/// Validates dates and compares them at a chosen granularity.
///
/// Ported from `org.apache.commons.validator.routines.DateValidator`, whose
/// `java.util.Date` return becomes a [DateTime].
class DateValidator extends AbstractCalendarValidator<DateTime> {
  /// Creates a validator.
  ///
  /// Defaults to [DateStyle.short] with no time portion, as upstream does.
  const DateValidator({super.strict = true, super.dateStyle = DateStyle.short});

  static const DateValidator _instance = DateValidator();

  /// The shared strict instance.
  static DateValidator getInstance() => _instance;

  @override
  DateTime? processParsedValue(DateTime parsed, Duration zoneOffset) =>
      parsed.subtract(zoneOffset);

  /// The calendar fields of [value] as read in [zoneOffset].
  ///
  /// Stands in for `DateValidator.getCalendar`. Note the week rules default to
  /// the US ones, where Java would take them from the default locale - pass them
  /// explicitly if that matters, since [compareWeeks] depends on them.
  CalendarFields fieldsOf(
    DateTime value, {
    Duration zoneOffset = Duration.zero,
    int firstDayOfWeek = DayOfWeek.sunday,
    int minimalDaysInFirstWeek = 1,
  }) =>
      CalendarFields.fromDateTime(
        value,
        zoneOffset: zoneOffset,
        firstDayOfWeek: firstDayOfWeek,
        minimalDaysInFirstWeek: minimalDaysInFirstWeek,
      );

  /// Compares [value] and [other] down to the day.
  int compareDates(
    DateTime value,
    DateTime other, {
    Duration zoneOffset = Duration.zero,
  }) =>
      compare(
        fieldsOf(value, zoneOffset: zoneOffset),
        fieldsOf(other, zoneOffset: zoneOffset),
        CalendarField.date,
      );

  /// Compares [value] and [other] by week.
  int compareWeeks(
    DateTime value,
    DateTime other, {
    Duration zoneOffset = Duration.zero,
    int firstDayOfWeek = DayOfWeek.sunday,
    int minimalDaysInFirstWeek = 1,
  }) =>
      compare(
        fieldsOf(
          value,
          zoneOffset: zoneOffset,
          firstDayOfWeek: firstDayOfWeek,
          minimalDaysInFirstWeek: minimalDaysInFirstWeek,
        ),
        fieldsOf(
          other,
          zoneOffset: zoneOffset,
          firstDayOfWeek: firstDayOfWeek,
          minimalDaysInFirstWeek: minimalDaysInFirstWeek,
        ),
        CalendarField.weekOfYear,
      );

  /// Compares [value] and [other] by month.
  int compareMonths(
    DateTime value,
    DateTime other, {
    Duration zoneOffset = Duration.zero,
  }) =>
      compare(
        fieldsOf(value, zoneOffset: zoneOffset),
        fieldsOf(other, zoneOffset: zoneOffset),
        CalendarField.month,
      );

  /// Compares [value] and [other] by quarter.
  ///
  /// [monthOfFirstQuarter] is one-based and defaults to January, as upstream.
  int compareQuartersOf(
    DateTime value,
    DateTime other, {
    int monthOfFirstQuarter = 1,
    Duration zoneOffset = Duration.zero,
  }) =>
      compareQuarters(
        fieldsOf(value, zoneOffset: zoneOffset),
        fieldsOf(other, zoneOffset: zoneOffset),
        monthOfFirstQuarter,
      );

  /// Compares [value] and [other] by year.
  int compareYears(
    DateTime value,
    DateTime other, {
    Duration zoneOffset = Duration.zero,
  }) =>
      compare(
        fieldsOf(value, zoneOffset: zoneOffset),
        fieldsOf(other, zoneOffset: zoneOffset),
        CalendarField.year,
      );
}

/// Validates dates and returns them as calendar fields.
///
/// Ported from `org.apache.commons.validator.routines.CalendarValidator`. Where
/// Java hands back the `DateFormat`'s own mutable `Calendar`, this returns an
/// immutable [CalendarFields].
class CalendarValidator extends AbstractCalendarValidator<CalendarFields> {
  /// Creates a validator.
  const CalendarValidator({
    super.strict = true,
    super.dateStyle = DateStyle.short,
    this.firstDayOfWeek = DayOfWeek.sunday,
    this.minimalDaysInFirstWeek = 1,
  });

  /// The day the week starts on, which affects week comparisons.
  final int firstDayOfWeek;

  /// How many days of a new year make its first week week 1.
  final int minimalDaysInFirstWeek;

  static const CalendarValidator _instance = CalendarValidator();

  /// The shared strict instance.
  static CalendarValidator getInstance() => _instance;

  @override
  CalendarFields? processParsedValue(DateTime parsed, Duration zoneOffset) =>
      CalendarFields.fromDateTime(
        parsed.subtract(zoneOffset),
        zoneOffset: zoneOffset,
        firstDayOfWeek: firstDayOfWeek,
        minimalDaysInFirstWeek: minimalDaysInFirstWeek,
      );

  /// Re-expresses [value] in [zoneOffset], keeping its wall-clock reading.
  ///
  /// Mirrors `CalendarValidator.adjustToTimeZone`. Java compares zones by
  /// `hasSameRules`, i.e. rule equivalence rather than identity; with fixed
  /// offsets that reduces to equality.
  CalendarFields adjustToTimeZone(CalendarFields value, Duration zoneOffset) =>
      value.zoneOffset == zoneOffset ? value : value.adjustToZone(zoneOffset);

  /// Compares [value] and [other] down to the day.
  int compareDates(CalendarFields value, CalendarFields other) =>
      compare(value, other, CalendarField.date);

  /// Compares [value] and [other] by week.
  int compareWeeks(CalendarFields value, CalendarFields other) =>
      compare(value, other, CalendarField.weekOfYear);

  /// Compares [value] and [other] by month.
  int compareMonths(CalendarFields value, CalendarFields other) =>
      compare(value, other, CalendarField.month);

  /// Compares [value] and [other] by year.
  int compareYears(CalendarFields value, CalendarFields other) =>
      compare(value, other, CalendarField.year);

  /// Compares [value] and [other] by quarter, [monthOfFirstQuarter] one-based.
  int compareQuartersOf(
    CalendarFields value,
    CalendarFields other, {
    int monthOfFirstQuarter = 1,
  }) =>
      compareQuarters(value, other, monthOfFirstQuarter);
}

/// Validates times of day and compares them at a chosen granularity.
///
/// Ported from `org.apache.commons.validator.routines.TimeValidator`.
///
/// A time-only value has no date, so the fields carry the 1970-01-01 epoch date
/// exactly as Java's internal `Calendar` does.
class TimeValidator extends AbstractCalendarValidator<CalendarFields> {
  /// Creates a validator.
  const TimeValidator({
    super.strict = true,
    super.timeStyle = DateStyle.short,
  }) : super(dateStyle: null);

  static const TimeValidator _instance = TimeValidator();

  /// The shared strict instance.
  static TimeValidator getInstance() => _instance;

  @override
  CalendarFields? processParsedValue(DateTime parsed, Duration zoneOffset) =>
      CalendarFields.fromDateTime(
        parsed.subtract(zoneOffset),
        zoneOffset: zoneOffset,
      );

  /// Compares [value] and [other] down to the hour.
  int compareHours(CalendarFields value, CalendarFields other) =>
      compareTime(value, other, CalendarField.hourOfDay);

  /// Compares [value] and [other] down to the minute.
  int compareMinutes(CalendarFields value, CalendarFields other) =>
      compareTime(value, other, CalendarField.minute);

  /// Compares [value] and [other] down to the second.
  int compareSeconds(CalendarFields value, CalendarFields other) =>
      compareTime(value, other, CalendarField.second);

  /// Compares [value] and [other] down to the millisecond.
  int compareTimes(CalendarFields value, CalendarFields other) =>
      compareTime(value, other, CalendarField.millisecond);
}
