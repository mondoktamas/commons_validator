import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/date_validators.dart';

String fmt(DateTime d) {
  final u = d.toUtc();
  String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
  return '${p(u.year, 4)}-${p(u.month)}-${p(u.day)}T'
      '${p(u.hour)}:${p(u.minute)}:${p(u.second)}.${p(u.millisecond, 3)}';
}

String eval(String which, String pattern, String v) {
  try {
    switch (which) {
      case 'date':
        final d = DateValidator.getInstance().parse(v, pattern: pattern);
        return d == null ? 'null' : fmt(d);
      case 'date_lax':
        final d = const DateValidator(strict: false).parse(v, pattern: pattern);
        return d == null ? 'null' : fmt(d);
      case 'cal':
        final f = CalendarValidator.getInstance().parse(v, pattern: pattern);
        return f == null ? 'null' : fmt(f.instant);
      case 'time':
        final f = TimeValidator.getInstance().parse(v, pattern: pattern);
        return f == null ? 'null' : fmt(f.instant);
      default:
        throw ArgumentError(which);
    }
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
    out.writeln('$line\t${eval(p[0], p[1], p.sublist(2).join("\t"))}');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
