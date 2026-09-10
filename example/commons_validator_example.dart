// ignore_for_file: avoid_print
import 'package:commons_validator/commons_validator.dart';

void main() {
  // --- Network and domain ---
  print(EmailValidator.getInstance().isValid('someone@example.com')); // true
  print(
      UrlValidator.getInstance().isValid('https://example.com/a?b=c')); // true
  print(DomainValidator.getInstance().isValid('example.co.uk')); // true
  print(InetAddressValidator.getInstance().isValid('2001:db8::1')); // true

  // Unicode domains are converted to punycode first, so these agree.
  final domains = DomainValidator.getInstance();
  print(domains.isValid('exämple.com')); // true
  print(domains.isValid('xn--exmple-cua.com')); // true

  // --- Financial codes ---
  print(IBANValidator.getInstance().isValid('GB29NWBK60161331926819')); // true
  print(IBANValidator.getInstance().validate('GB29NWBK60161331926810').name);
  // invalidChecksum

  print(ISBNValidator.getInstance().validate('1-930110-99-5'));
  // 9781930110991 - a valid ISBN-10, converted to ISBN-13

  print(CreditCardValidator().isValid('4417123456789113')); // true
  print(
    CreditCardValidator(CreditCardValidator.amex).isValid('4417123456789113'),
  ); // false - a Visa number, and only Amex is enabled

  // --- Check digits on their own ---
  print(LuhnCheckDigit.luhnCheckDigit.calculate('441712345678911')); // 3
  print(
      IBANCheckDigit.ibanCheckDigit.isValid('GB29NWBK60161331926819')); // true

  // --- Numbers ---
  // Always pass the locale: unlike Java there is no mutable global default.
  final amounts = BigDecimalValidator.getInstance();
  print(amounts.parse('1,234.56', locale: 'en_US')); // 1234.56
  print(amounts.parse('1.234,56', locale: 'de_DE')); // 1234.56

  print(IntegerValidator.getInstance().parse('1,234', locale: 'en_US')); // 1234
  print(CurrencyValidator.getInstance().parse(r'$1,234.56', locale: 'en_US'));
  // 1234.56

  // A lenient validator keeps the parsed prefix instead of failing.
  print(
      const IntegerValidator(strict: false).parse('1234abc', locale: 'en_US'));
  // 1234

  // --- Dates ---
  final dates = DateValidator.getInstance();
  print(dates.parse('2026-06-15', pattern: 'yyyy-MM-dd')); // 2026-06-15 00:00
  print(dates.parse('2026-02-30', pattern: 'yyyy-MM-dd')); // null

  final june = dates.parse('2026-06-15', pattern: 'yyyy-MM-dd')!;
  final july = dates.parse('2026-07-15', pattern: 'yyyy-MM-dd')!;
  print(dates.compareMonths(june, july)); // -1

  final time =
      TimeValidator.getInstance().parse('12:30:45', pattern: 'HH:mm:ss')!;
  print('${time.hour}:${time.minute}:${time.second}'); // 12:30:45
}
