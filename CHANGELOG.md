# Changelog

## 0.1.0

First release. A Dart port of the `org.apache.commons.validator.routines`
packages from Apache Commons Validator 1.11.1-SNAPSHOT (git `770f7846`).

- All 16 check-digit routines: ABA, CAS, CUSIP, EAN-13, EC, IBAN, ISBN,
  ISBN-10, ISIN, ISSN, Luhn, Modulus, ModulusTen, SEDOL, Verhoeff.
- Code validators: `RegexValidator`, `CodeValidator`, `CreditCardValidator`,
  `ISBNValidator`, `ISSNValidator`, `ISINValidator`, `IBANValidator`.
- Network validators: `DomainValidator`, `EmailValidator`, `UrlValidator`,
  `InetAddressValidator`, including an IDNA-2003 implementation that reproduces
  `java.net.IDN.toASCII` and an RFC 2396 URI splitter standing in for
  `java.net.URI`.
- Number validators: Byte, Short, Integer, Long, Float, Double, BigDecimal,
  BigInteger, Currency and Percent, on a locale-aware parser written for the
  purpose because `intl` returns only `double`.
- Date validators: `DateValidator`, `CalendarValidator`, `TimeValidator`, with
  `CalendarFields` replacing `java.util.Calendar` and Java's week-numbering
  rules reproduced exactly.
- The legacy XML-driven framework is deliberately not ported; see the README.

Behaviour is verified against the real Java classes by the differential harness
in `tool/jvm_diff/`. See the README for the results table and the documented
divergences.
