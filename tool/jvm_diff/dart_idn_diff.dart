import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/internal/idna.dart';
import 'package:commons_validator/src/internal/punycode.dart';

void main(List<String> args) {
  final out = StringBuffer();
  final lines = const LineSplitter().convert(
    File(args[0]).readAsStringSync(encoding: utf8),
  );
  for (final label in lines) {
    String result;
    try {
      result = toAscii(label);
    } on IdnaException {
      result = '!IllegalArgumentException';
    } on PunycodeException {
      result = '!IllegalArgumentException';
    } catch (e) {
      result = '!${e.runtimeType}';
    }
    out.writeln('$label\t$result');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
