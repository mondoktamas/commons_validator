# commons_validator

A Dart port of the validation routines from
[Apache Commons Validator](https://commons.apache.org/proper/commons-validator/),
covering email, URL, domain, IP, IBAN, ISBN, ISIN, ISSN, credit card, check
digit, number and date validation.

Pure Dart, so it works in Flutter, Dart CLI and server code alike. It pulls in no
`dart:io` and no `dart:mirrors`.

Ported from Apache Commons Validator **1.11.1-SNAPSHOT** (git `770f7846`).

## Why this exists

Nothing on pub.dev covers this ground. The closest packages are thin regular
expression wrappers with none of the check-digit arithmetic, IBAN country
registry, TLD-aware domain validation, or locale-aware number and date parsing
that Commons Validator has accumulated over twenty years.

## Install

```yaml
dependencies:
  commons_validator: ^0.1.0
```

The `intl` constraint is deliberately loose (`>=0.20.0 <0.21.0`) because
`flutter_localizations` pins `intl` to an exact version; a tighter constraint
would make this package unusable in any app that uses Flutter's own
localizations.

## Use

```dart
import 'package:commons_validator/commons_validator.dart';

EmailValidator.getInstance().isValid('someone@example.com');      // true
UrlValidator.getInstance().isValid('https://example.com/a?b=c');  // true
DomainValidator.getInstance().isValid('exämple.com');             // true
IBANValidator.getInstance().isValid('GB29NWBK60161331926819');    // true
ISBNValidator.getInstance().validate('1-930110-99-5');            // 9781930110991

// Numbers and dates take an explicit locale or pattern - see "Locale handling".
BigDecimalValidator.getInstance().parse('1.234,56', locale: 'de_DE'); // 1234.56
DateValidator.getInstance().parse('2026-06-15', pattern: 'yyyy-MM-dd');
```

See [`example/commons_validator_example.dart`](example/commons_validator_example.dart)
for a fuller tour.

## What is ported

The whole of `org.apache.commons.validator.routines`, plus the two helpers it
depends on.

| Java | Dart |
| --- | --- |
| `RegexValidator`, `CodeValidator` | `RegexValidator`, `CodeValidator` |
| `DomainValidator` | `DomainValidator` |
| `EmailValidator` | `EmailValidator` |
| `UrlValidator` | `UrlValidator` |
| `InetAddressValidator` | `InetAddressValidator` |
| `CreditCardValidator` | `CreditCardValidator`, `CreditCardRange` |
| `IBANValidator`, `IBANValidatorStatus` | `IBANValidator`, `IBANCountryValidator`, `IBANValidatorStatus` |
| `ISBNValidator`, `ISSNValidator`, `ISINValidator` | same names |
| all 16 `routines.checkdigit` classes | same names |
| `Byte`/`Short`/`Integer`/`Long`/`Float`/`Double`/`BigDecimal`/`BigInteger`/`Currency`/`Percent` validators | same names |
| `DateValidator`, `CalendarValidator`, `TimeValidator` | same names |
| `AbstractFormatValidator` + `AbstractNumberValidator` | `AbstractNumberValidator<T>` (merged, generic) |
| `AbstractCalendarValidator` | `AbstractCalendarValidator<T>` |
| `GenericValidator.isBlankOrNull`, `matchRegexp` | `GenericValidator` |
| `util.Flags` | `Flags` |

### What is not ported

The legacy `org.apache.commons.validator` root package — `Validator`,
`ValidatorResources`, `ValidatorAction`, `Form`, `FormSet`, `Field`, `Arg`,
`Msg`, `Var` — is **not** included and cannot be. It is an XML-configured engine
whose entire premise is resolving a class name, a method name and parameter type
names from strings at runtime and invoking them by reflection, driven by
commons-digester. Flutter has no runtime reflection, so there is no faithful
translation, only a redesign around code generation or a registry of closures.
For declarative form validation in Dart, reach for a combinator API or
`build_runner` codegen instead.

## How closely does it match Java?

Where Dart *can* match the JVM exactly, it does, and that is measured rather
than asserted. `tool/jvm_diff/` compiles the real Java classes and runs the same
generated inputs through both implementations:

| Layer | Inputs | Disagreements |
| --- | --- | --- |
| Check digits (all 16 routines) | 12,249 | **0** |
| Regex, code and financial validators | 30,664 | **0** |
| Domain, email, URL, IP | 46,892 | **0** |
| `java.net.IDN.toASCII` (every BMP code point) | 130,240 | **0** |
| RFC 2396 URI splitting | 568 | **0** |
| Number validators, `en_US` | 1,148 | **0** |
| `format()`, seven locales | 1,372 | **0** |
| Number validators, seven locales | 840 | 1 (CLDR data, below) |
| Date and time comparisons | 3,024 | **0** |
| Date and time parsing | 10,788 | 1 case (below) |
| `Calendar` week numbering | 11,692 | **0** |

**249,477 inputs, 7 disagreements** in total, both documented below.

The corpora include every single-character substitution at every position,
transpositions, truncations, control characters, NBSP, Arabic-Indic and
fullwidth digits, and — for dates — every month/day combination across several
years under four different week-rule settings.

## Documented divergences

These are the places the port deliberately or unavoidably differs. Nothing else
is known to differ.

### Locale handling is explicit, not ambient

**This is the largest deliberate change.** In Java, passing `null` for a
`Locale` or `TimeZone` means "read the JVM global default", and Commons
Validator's own tests mutate that global to control the outcome. Dart has no
mutable default time zone and `Intl.defaultLocale` is a much weaker analogue, so:

- the number validators take a `locale:` argument, falling back to
  `Intl.defaultLocale` and then the system locale;
- the date validators take a `pattern:` and an optional `zoneOffset:`, and read
  values as UTC when no offset is given.

Pass them explicitly and results are deterministic. This also means the ported
tests assert against a stated locale instead of an ambient one.

### Time zones are fixed offsets

`java.util.TimeZone` becomes a `Duration` offset. Dart's `DateTime` supports only
local time and UTC, so full IANA zone support would mean depending on
`package:timezone`, and `TimeZone.hasSameRules` — rule equivalence rather than
identity — has no equivalent at all.

### `Decimal` has no scale

`java.math.BigDecimal` carries a scale, so Java prints `1234.00` where
`package:decimal` prints `1234`. The *values* are equal and compare equal; only
the rendering differs. Truncation still happens where Java truncates: a strict
validator applies the pattern's scale with round-toward-zero, so `1234.567`
under a two-decimal format is `1234.56`, not `1234.57`.

### `ja_JP` currency symbol

Java's `DecimalFormatSymbols` gives U+FFE5 (fullwidth `￥`); `intl` gives U+00A5
(`¥`). A Japanese currency amount written with the halfwidth sign validates here
and not on the JVM. This is the only locale-data difference found across
`en_US`, `de_DE`, `fr_FR`, `ru_RU`, `sv_SE`, `it_IT` and `ja_JP` — separators,
minus signs and affix positions otherwise agree exactly, including `fr`'s U+202F
grouping separator, `ru`/`sv`'s U+00A0, and `sv`'s U+2212 minus.

### An exponent in a date field

Java parses date number fields with `DecimalFormat`, which accepts exponents, so
`SimpleDateFormat("yyyy-MM-dd")` reads `1E3-06-15` as the year 1000. This port
rejects it. The divergence makes the port *stricter*, and reproducing the quirk
would mean accepting nonsense as a date.

### `DateStyle` is approximate

Java's `DateFormat.SHORT`/`MEDIUM`/`LONG`/`FULL` map onto the nearest `intl`
skeletons. They are not identical — Java's `SHORT` for `en_US` uses a two-digit
year where `intl`'s equivalent uses four. **Pass an explicit `pattern:` when
exact agreement with the JVM matters**; pattern-driven parsing is exact.

### IDNA is 2003, not UTS-46

`DomainValidator` reproduces `java.net.IDN.toASCII`, which implements IDNA-2003
with RFC 3491 nameprep. IDNA-2008 and UTS-46 disagree with it on `ß`, final
sigma and the zero-width joiners. Every table in `lib/src/internal/idna_data.dart` is derived by measuring OpenJDK
17.0.18 itself rather than transcribed from the RFCs — guessing at the tables from
the specification produced 319 disagreements before that approach replaced it.
Regenerating against a different JDK would legitimately shift the
unassigned-code-point boundary, since a newer Unicode version assigns more code
points.

### `ISINValidator` country codes are pinned

Upstream reads its country list from `Locale.getISOCountries()`, live JDK data
Dart cannot reach. The list in `lib/src/routines/isin_data.dart` is a snapshot of
OpenJDK 17.0.18's 249 codes. A newer JDK may know more.

### Web `int` is a JavaScript double

The package **does** compile and run on Flutter web — that is verified, not
assumed. But `int` above 2^53 is inexact there, so:

- `LongValidator` cannot distinguish values near the 64-bit boundary as
  precisely as the JVM does. Its bounds are held as `BigInt` and built with
  `BigInt.parse`, because a literal `9223372036854775807` is a **compile error**
  for the web, not merely an imprecise value — one anywhere in the package would
  break every Flutter web build. Keep that in mind if you extend it.
- `Flags.turnOnAll` and `Flags.toString` are not accurate above bit 52.
  `UrlValidator`'s own option mask uses only bits 0–3, so it is unaffected.

Tests that depend on exact 64-bit behaviour are marked `testOn: 'vm'`.

### Smaller, deliberate choices

- **No `Serializable`, no `clone()`.** `Flags` offers `copy()` instead.
- **`AbstractNumberValidator<T>` is generic**, so `IntegerValidator.parse`
  returns `int?` and `BigDecimalValidator.parse` returns `Decimal?`. Java works
  in `Object` and casts in every leaf.
- **`CalendarField` is an enum**, so the `IllegalArgumentException` Java throws
  for an unsupported comparison field becomes a compile-time guarantee.
- **`CalendarFields` is immutable.** Java returns the `DateFormat`'s own mutable
  `Calendar`; this returns a value type, with week rules configurable because
  `compareWeeks` depends on them.
- **`DomainValidator.resetOverridesForTesting`** is not in the Java API. Upstream
  isolates its TLD-override tests with a fresh classloader per test, which Dart
  has no equivalent of.
- **`DomainValidator.isValidDomainSyntax` is public**; it is package-private in
  Java.
- **Exception messages** are close to but not byte-identical with Java's, since
  Dart has no `String.format`. No test asserts on message text except where
  upstream's own tests do.

## Behaviours worth knowing about

These are upstream's, not the port's, and they surprise people:

- **`strict` controls trailing input, not validity.** A lenient number or date
  validator accepts `1234abc` as 1234 — a parse *error* always fails, but
  leftover input only fails when strict.
- **`CodeValidator.isValid` is `validate(x) != null`**, and `validate` returns the
  *reformatted* code with separators stripped. So a code can be valid while its
  raw text would fail the check digit.
- **A zero weighted sum is invalid.** `ModulusCheckDigit` rejects all-zero codes.
- **Grouping placement is not checked.** `1,2,3,4` parses as 1234, as it does in
  Java.
- **Non-ASCII digits split two ways.** The number validators *accept* Arabic-Indic
  and fullwidth digits, because `DecimalFormat` falls back to
  `Character.digit`; the check-digit routines *reject* them, because their Java
  source checks explicitly. Both behaviours are reproduced.
- **`DomainValidator`'s TLD overrides are process-global** and freeze on the first
  `getInstance()` call. Prefer `getInstanceWithOverrides`, which scopes them to
  one instance.

## Regenerating the data tables

Four files are generated and should not be hand-edited:

| File | Source |
| --- | --- |
| `lib/src/routines/domain_tlds.dart` | the `String[]` tables in `DomainValidator.java` |
| `lib/src/routines/iban_validators.dart` | `IBANValidator.DEFAULT_VALIDATORS` |
| `lib/src/routines/isin_data.dart` | `Locale.getISOCountries()` + `ISINValidator.SPECIALS` |
| `lib/src/internal/idna_data.dart` | the reference JDK: `IDN.toASCII`/`toUnicode` round trips, its rejections, and `Character.getDirectionality` |
| `lib/src/internal/unicode_digits.dart` | the reference JDK's `Character.digit` |

Each has a script, and each is reproducible: running it regenerates the committed
data byte-for-byte.

```sh
dart run tool/generate_tlds.dart        ../commons-validator
dart run tool/generate_iban.dart        ../commons-validator
dart run tool/generate_isin_data.dart   ../commons-validator
dart run tool/generate_idna_data.dart   # needs a JDK on PATH
dart run tool/generate_unicode_digits.dart  # needs a JDK on PATH
```

Note the two TLD tables come from *different* IANA snapshots upstream — generic
TLDs from 2026-06-23, country codes from 2024-04-02 — so do not refresh one in
isolation.

## Licence

Apache License 2.0, as a derivative work of Apache Commons Validator. See
[`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
