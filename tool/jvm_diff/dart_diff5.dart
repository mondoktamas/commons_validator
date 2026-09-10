import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/big_number_validators.dart';
import 'package:commons_validator/src/routines/float_validators.dart';
import 'package:commons_validator/src/routines/integer_validators.dart';

const locale = 'en_US';

/// Renders a value the way the Java harness prints its counterpart.
String s(Object? o) {
  if (o == null) return 'null';
  if (o is double) {
    if (o.isNaN) return 'NaN';
    if (o == double.infinity) return 'Infinity';
    if (o == double.negativeInfinity) return '-Infinity';
  }
  return o.toString();
}

String eval(String which, String v) {
  try {
    return switch (which) {
      'byte' => s(ByteValidator.getInstance().parse(v, locale: locale)),
      'byte_lax' =>
        s(const ByteValidator(strict: false).parse(v, locale: locale)),
      'short' => s(ShortValidator.getInstance().parse(v, locale: locale)),
      'int' => s(IntegerValidator.getInstance().parse(v, locale: locale)),
      'int_lax' =>
        s(const IntegerValidator(strict: false).parse(v, locale: locale)),
      'long' => s(LongValidator.getInstance().parse(v, locale: locale)),
      'float' => s(FloatValidator.getInstance().parse(v, locale: locale)),
      'double' => s(DoubleValidator.getInstance().parse(v, locale: locale)),
      'bigdec' => s(BigDecimalValidator.getInstance().parse(v, locale: locale)),
      'bigint' => s(BigIntegerValidator.getInstance().parse(v, locale: locale)),
      'currency' => s(CurrencyValidator.getInstance().parse(v, locale: locale)),
      'percent' => s(PercentValidator.getInstance().parse(v, locale: locale)),
      'int_pat' => s(IntegerValidator.getInstance()
          .parse(v, pattern: '#,##0', locale: locale)),
      'bigdec_pat' => s(BigDecimalValidator.getInstance()
          .parse(v, pattern: '#,##0.00', locale: locale)),
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
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    out.writeln(
        '$line\t${eval(line.substring(0, tab), line.substring(tab + 1))}');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
