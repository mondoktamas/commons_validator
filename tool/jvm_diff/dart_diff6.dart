import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/calendar_fields.dart';
import 'package:commons_validator/src/routines/date_validators.dart';

final dv = DateValidator.getInstance();
final cv = CalendarValidator.getInstance();
final tv = TimeValidator.getInstance();

DateTime parseIso(String s) => DateTime.parse('${s}Z');

CalendarFields fields(String s) =>
    CalendarFields.fromDateTime(parseIso(s), zoneOffset: Duration.zero);

/// Java's Integer.compare yields -1/0/1 for these fields, and so does Dart's
/// compareTo, but signum the result anyway so the two are directly comparable.
int sign(int v) => v == 0 ? 0 : (v < 0 ? -1 : 1);

String eval(String op, String a, String b, String extra) {
  try {
    return switch (op) {
      'dates' => '${sign(dv.compareDates(parseIso(a), parseIso(b)))}',
      'weeks' => '${sign(dv.compareWeeks(parseIso(a), parseIso(b)))}',
      'months' => '${sign(dv.compareMonths(parseIso(a), parseIso(b)))}',
      'years' => '${sign(dv.compareYears(parseIso(a), parseIso(b)))}',
      'quarters' =>
        '${sign(dv.compareQuartersOf(parseIso(a), parseIso(b), monthOfFirstQuarter: int.parse(extra)))}',
      'cal_dates' => '${sign(cv.compareDates(fields(a), fields(b)))}',
      'cal_weeks' => '${sign(cv.compareWeeks(fields(a), fields(b)))}',
      'cal_months' => '${sign(cv.compareMonths(fields(a), fields(b)))}',
      'cal_years' => '${sign(cv.compareYears(fields(a), fields(b)))}',
      'hours' => '${sign(tv.compareHours(fields(a), fields(b)))}',
      'minutes' => '${sign(tv.compareMinutes(fields(a), fields(b)))}',
      'seconds' => '${sign(tv.compareSeconds(fields(a), fields(b)))}',
      'times' => '${sign(tv.compareTimes(fields(a), fields(b)))}',
      _ => throw ArgumentError(op),
    };
  } catch (e) {
    return '!${e.runtimeType}';
  }
}

void main(List<String> args) {
  final out = StringBuffer();
  for (final line in const LineSplitter()
      .convert(File(args[0]).readAsStringSync(encoding: utf8))) {
    final p = line.split('\t');
    if (p.length < 3) continue;
    out.writeln('$line\t${eval(p[0], p[1], p[2], p.length > 3 ? p[3] : "1")}');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
