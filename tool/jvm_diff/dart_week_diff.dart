import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/calendar_fields.dart';

void main(List<String> args) {
  final out = StringBuffer();
  for (final line in const LineSplitter()
      .convert(File(args[0]).readAsStringSync(encoding: utf8))) {
    final p = line.split('\t');
    if (p.length < 3) continue;
    final d = p[0].split('-');
    final f = CalendarFields(
      year: int.parse(d[0]),
      month: int.parse(d[1]),
      day: int.parse(d[2]),
      firstDayOfWeek: int.parse(p[1]),
      minimalDaysInFirstWeek: int.parse(p[2]),
    );
    out.writeln(
        '$line\t${f.dayOfYear}\t${f.dayOfWeek}\t${f.weekOfYear}\t${f.weekOfMonth}');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
