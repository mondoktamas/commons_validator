import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/checkdigit/aba_number_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/cas_number_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/check_digit_exception.dart';
import 'package:commons_validator/src/routines/checkdigit/cusip_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/ean13_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/ec_number_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/iban_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isbn10_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isbn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/isin_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/issn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/luhn_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/modulus_ten_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/sedol_check_digit.dart';
import 'package:commons_validator/src/routines/checkdigit/verhoeff_check_digit.dart';

CheckDigit routine(String name) => switch (name) {
      'luhn' => LuhnCheckDigit.luhnCheckDigit,
      'aban' => ABANumberCheckDigit.abanCheckDigit,
      'ean13' => EAN13CheckDigit.ean13CheckDigit,
      'isbn10' => ISBN10CheckDigit.isbn10CheckDigit,
      'isbn' => ISBNCheckDigit.isbnCheckDigit,
      'issn' => ISSNCheckDigit.issnCheckDigit,
      'cusip' => CUSIPCheckDigit.cusipCheckDigit,
      'sedol' => SedolCheckDigit.sedolCheckDigit,
      'isin' => ISINCheckDigit.isinCheckDigit,
      'verhoeff' => VerhoeffCheckDigit.verhoeffCheckDigit,
      'iban' => IBANCheckDigit.ibanCheckDigit,
      'cas' => CASNumberCheckDigit.casNumberCheckDigit,
      'ec' => ECNumberCheckDigit.ecNumberCheckDigit,
      'mod10luhn' => ModulusTenCheckDigit(const [1, 2],
          useRightPos: true, sumWeightedDigits: true),
      'mod10aban' => ModulusTenCheckDigit(const [1, 7, 3], useRightPos: true),
      'mod10ean13' => ModulusTenCheckDigit(const [1, 3], useRightPos: true),
      _ => throw ArgumentError(name),
    };

/// Maps a Dart exception to the Java simple class name the JVM harness prints,
/// so the two outputs are comparable.
String javaExceptionName(Object e) => switch (e) {
      CheckDigitException() => 'CheckDigitException',
      RangeError() => 'StringIndexOutOfBoundsException',
      ArgumentError() => 'IllegalArgumentException',
      _ => e.runtimeType.toString(),
    };

void main(List<String> args) {
  final lines = File(args[0]).readAsLinesSync();
  final out = StringBuffer();
  final cache = <String, CheckDigit>{};
  for (final line in lines) {
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    final name = line.substring(0, tab);
    final code = line.substring(tab + 1);
    final r = cache.putIfAbsent(name, () => routine(name));
    bool valid;
    try {
      valid = r.isValid(code);
    } catch (_) {
      valid = false;
    }
    String calc;
    try {
      calc = r.calculate(code);
    } catch (e) {
      calc = '!${javaExceptionName(e)}';
    }
    out.writeln('$name\t$code\t$valid\t$calc');
  }
  stdout.write(utf8.decode(utf8.encode(out.toString())));
}
