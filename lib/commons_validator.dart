/// A Dart port of the Apache Commons Validator `routines` packages.
///
/// See the README for the list of ported classes and the documented
/// behavioural divergences from the Java original.
library;

/// Re-exported because `BigDecimalValidator`, `CurrencyValidator` and
/// `PercentValidator` return a [Decimal]. Without this, naming the return type
/// would force every caller to depend on `package:decimal` directly.
export 'package:decimal/decimal.dart' show Decimal;

export 'src/generic_validator.dart';
export 'src/routines/checkdigit/aba_number_check_digit.dart';
export 'src/routines/checkdigit/cas_number_check_digit.dart';
export 'src/routines/checkdigit/check_digit.dart';
export 'src/routines/checkdigit/check_digit_exception.dart';
export 'src/routines/checkdigit/cusip_check_digit.dart';
export 'src/routines/checkdigit/ean13_check_digit.dart';
export 'src/routines/checkdigit/ec_number_check_digit.dart';
export 'src/routines/checkdigit/iban_check_digit.dart';
export 'src/routines/checkdigit/isbn10_check_digit.dart';
export 'src/routines/checkdigit/isbn_check_digit.dart';
export 'src/routines/checkdigit/isin_check_digit.dart';
export 'src/routines/checkdigit/issn_check_digit.dart';
export 'src/routines/checkdigit/luhn_check_digit.dart';
export 'src/routines/checkdigit/modulus_check_digit.dart';
export 'src/routines/checkdigit/modulus_ten_check_digit.dart';
export 'src/routines/checkdigit/sedol_check_digit.dart';
export 'src/routines/checkdigit/verhoeff_check_digit.dart';
export 'src/routines/abstract_calendar_validator.dart';
export 'src/routines/abstract_number_validator.dart';
export 'src/routines/big_number_validators.dart';
export 'src/routines/calendar_fields.dart';
export 'src/routines/code_validator.dart';
export 'src/routines/date_validators.dart';
export 'src/routines/domain_tlds.dart';
export 'src/routines/domain_validator.dart';
export 'src/routines/email_validator.dart';
export 'src/routines/float_validators.dart';
export 'src/routines/inet_address_validator.dart';
export 'src/routines/integer_validators.dart';
export 'src/routines/credit_card_validator.dart';
export 'src/routines/iban_validator.dart';
export 'src/routines/iban_validator_status.dart';
export 'src/routines/isbn_validator.dart';
export 'src/routines/isin_validator.dart';
export 'src/routines/issn_validator.dart';
export 'src/routines/regex_validator.dart';
export 'src/routines/url_validator.dart';
export 'src/util/flags.dart';
