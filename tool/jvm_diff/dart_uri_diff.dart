import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/internal/uri_parts.dart';

String n(String? s) => s ?? '<null>';

void main(List<String> args) {
  final out = StringBuffer();
  for (final line in const LineSplitter()
      .convert(File(args[0]).readAsStringSync(encoding: utf8))) {
    final p = parseUri(line);
    final r = p == null
        ? '!URISyntaxException'
        : [
            n(p.scheme),
            n(p.rawAuthority),
            n(p.rawPath),
            n(p.rawQuery),
            n(p.rawFragment)
          ].join('<|>');
    out.writeln('$line\t$r');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
