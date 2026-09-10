import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/commons_validator.dart';

String eval(String which, String locale, String v) {
  try {
    final d = Decimal.parse(v);
    return switch (which) {
      'bigdec' => BigDecimalValidator.getInstance().format(d, locale: locale),
      'int' => IntegerValidator.getInstance()
          .format(d.truncate().toBigInt().toInt(), locale: locale),
      'long' => LongValidator.getInstance()
          .format(d.truncate().toBigInt().toInt(), locale: locale),
      'currency' => CurrencyValidator.getInstance().format(d, locale: locale),
      'percent' => PercentValidator.getInstance().format(d, locale: locale),
      'bigdec_p' => BigDecimalValidator.getInstance()
          .format(d, pattern: '#,##0.00', locale: locale),
      'int_p' => IntegerValidator.getInstance().format(
          d.truncate().toBigInt().toInt(),
          pattern: '#,##0',
          locale: locale),
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
    out.writeln('$line\t${eval(p[0], p[1], p[2])}');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
