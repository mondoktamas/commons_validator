import 'dart:io';

import 'package:commons_validator/src/routines/credit_card_validator.dart';
import 'package:commons_validator/src/routines/iban_validator.dart';
import 'package:commons_validator/src/routines/isbn_validator.dart';
import 'package:commons_validator/src/routines/isin_validator.dart';
import 'package:commons_validator/src/routines/issn_validator.dart';

final ccDefault = CreditCardValidator();
final ccGeneric = CreditCardValidator.generic();
final ccAmex = CreditCardValidator(CreditCardValidator.amex);
final ccVisa = CreditCardValidator(CreditCardValidator.visa);
final ccMc = CreditCardValidator(CreditCardValidator.mastercard);
final ccDisc = CreditCardValidator(CreditCardValidator.discover);
final ccDiners = CreditCardValidator(CreditCardValidator.diners);
final ccVpay = CreditCardValidator(CreditCardValidator.vpay);
final isbn = ISBNValidator.getInstance();
final isbnNc = ISBNValidator.getInstance(convert: false);
final issn = ISSNValidator.getInstance();
final isinT = ISINValidator.getInstance(checkCountryCode: true);
final isinF = ISINValidator.getInstance(checkCountryCode: false);
final iban = IBANValidator.getInstance();

String s(Object? o) => o == null ? 'null' : o.toString();

/// Java's enum names are SCREAMING_SNAKE; Dart's are lowerCamel.
String enumName(IBANValidatorStatus st) => switch (st) {
      IBANValidatorStatus.valid => 'VALID',
      IBANValidatorStatus.unknownCountry => 'UNKNOWN_COUNTRY',
      IBANValidatorStatus.invalidLength => 'INVALID_LENGTH',
      IBANValidatorStatus.invalidPattern => 'INVALID_PATTERN',
      IBANValidatorStatus.invalidChecksum => 'INVALID_CHECKSUM',
    };

String eval(String which, String v) {
  try {
    return switch (which) {
      'cc_default' => '${ccDefault.isValid(v)}|${s(ccDefault.validate(v))}',
      'cc_generic' => '${ccGeneric.isValid(v)}|${s(ccGeneric.validate(v))}',
      'cc_amex' => '${ccAmex.isValid(v)}|${s(ccAmex.validate(v))}',
      'cc_visa' => '${ccVisa.isValid(v)}|${s(ccVisa.validate(v))}',
      'cc_mc' => '${ccMc.isValid(v)}|${s(ccMc.validate(v))}',
      'cc_disc' => '${ccDisc.isValid(v)}|${s(ccDisc.validate(v))}',
      'cc_diners' => '${ccDiners.isValid(v)}|${s(ccDiners.validate(v))}',
      'cc_vpay' => '${ccVpay.isValid(v)}|${s(ccVpay.validate(v))}',
      'isbn' => '${isbn.isValid(v)}|${s(isbn.validate(v))}',
      'isbn_nc' => '${isbnNc.isValid(v)}|${s(isbnNc.validate(v))}',
      'isbn10' => '${isbn.isValidISBN10(v)}|${s(isbn.validateISBN10(v))}',
      'isbn13' => '${isbn.isValidISBN13(v)}|${s(isbn.validateISBN13(v))}',
      'issn' => '${issn.isValid(v)}|${s(issn.validate(v))}',
      'issn_ean' => '-|${s(issn.validateEan(v))}',
      'isin_t' => '${isinT.isValid(v)}|${s(isinT.validate(v))}',
      'isin_f' => '${isinF.isValid(v)}|${s(isinF.validate(v))}',
      'iban' => '${iban.isValid(v)}|${enumName(iban.validate(v))}',
      _ => throw ArgumentError(which),
    };
  } catch (e) {
    return '!${javaName(e)}';
  }
}

String javaName(Object e) => switch (e) {
      // RangeError extends ArgumentError, so it has to be matched first.
      RangeError() => 'StringIndexOutOfBoundsException',
      ArgumentError() => 'IllegalArgumentException',
      FormatException() => 'NumberFormatException',
      _ => e.runtimeType.toString(),
    };

void main(List<String> args) {
  final out = StringBuffer();
  for (final line in File(args[0]).readAsLinesSync()) {
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    final which = line.substring(0, tab);
    final v = line.substring(tab + 1);
    out.writeln('$which\t$v\t${eval(which, v)}');
  }
  stdout.write(out.toString());
}
