import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/big_number_validators.dart';
import 'package:commons_validator/src/routines/float_validators.dart';
import 'package:commons_validator/src/routines/integer_validators.dart';

String s(Object? o) {
  if (o == null) return 'null';
  if (o is double) {
    if (o == double.infinity) return 'Infinity';
    if (o == double.negativeInfinity) return '-Infinity';
  }
  return o.toString();
}

String eval(String which, String locale, String v) {
  try {
    return switch (which) {
      'bigdec' => s(BigDecimalValidator.getInstance().parse(v, locale: locale)),
      'int' => s(IntegerValidator.getInstance().parse(v, locale: locale)),
      'currency' => s(CurrencyValidator.getInstance().parse(v, locale: locale)),
      'percent' => s(PercentValidator.getInstance().parse(v, locale: locale)),
      'double' => s(DoubleValidator.getInstance().parse(v, locale: locale)),
      _ => throw ArgumentError(which),
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
    out.writeln('$line\t${eval(p[0], p[1], p.sublist(2).join("\t"))}');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
