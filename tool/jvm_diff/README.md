# JVM differential harness

Runs the same generated corpus through upstream's Java classes and this Dart
port, then diffs the results. This is the strongest verification available for
the mechanical validators, and it is why the Java clone at
`../../commons-validator` is worth keeping around.

## Results so far

Across every corpus: **249,477 inputs, 7 disagreements** — the `ja_JP` currency
symbol and one exponent-in-a-year-field input, both documented in the package
README.

### Task 5 - number validators (`Diff5.java` / `dart_diff5.dart`)

Byte, Short, Integer, Long, Float, Double, BigDecimal, BigInteger, Currency and
Percent, strict and lenient, with and without an explicit pattern:
**1,148 inputs, 0 genuine disagreements**.

171 rows differ only in *rendering*, not value, and are excluded by comparing
numerically: Java's `BigDecimal` keeps its scale so it prints `1234.00` where
`Decimal` prints `1234`, and Java uses `E` notation for large doubles. The float
rows are compared at 32-bit precision, because Java prints the shortest string
that round-trips as a float.

`Diff5L.java` / `dart_diff5l.dart` repeat this across `en_US`, `de_DE`, `fr_FR`,
`ru_RU`, `sv_SE`, `it_IT` and `ja_JP`: **840 inputs, 1 genuine disagreement**,
which is a CLDR data difference rather than a logic one - see the divergences
section below.

### Task 4 - domain, email, URL and IP (`Diff4.java` / `dart_diff4.dart`)

DomainValidator (with and without local), every TLD predicate,
InetAddressValidator (v4, v6, and either), EmailValidator (default, local, TLD)
and UrlValidator under five option combinations:
**46,892 inputs, 0 disagreements**.

Two supporting layers are verified separately, because they are where the JDK is
hardest to reproduce:

- **IDNA / `IDN.toASCII`** (`IdnGen.java` / `dart_idn_diff.dart`):
  **130,240 labels covering every BMP code point, 0 disagreements**, byte-for-byte
  including which inputs throw. `IdnReject2.java` generates the rejected-code-point
  table in `lib/src/internal/idna_data.dart` from the reference JDK.
- **The RFC 2396 URI splitter** (`UriDump.java` / `dart_uri_diff.dart`):
  **568 inputs, 0 disagreements** on all five raw components and on which inputs
  are rejected.

### Task 3 - code and financial validators (`Diff3.java` / `dart_diff3.dart`)

CreditCard (default, generic, and each brand), ISBN-10/13 with and without
conversion, ISSN, ISSN-from-EAN13, ISIN with and without the country check, and
IBAN: **30,664 inputs, 0 disagreements**, comparing `isValid`, the `validate`
return value, and the `IBANValidatorStatus` enum.

### Task 2 - check digits (`Diff.java` / `dart_diff.dart`)

Check-digit routines, 12,249 inputs (valid codes, every single-character
substitution at every position, transpositions, truncations, extensions,
case changes, leading/trailing spaces, random same-length digit strings, plus
control characters, NBSP, Arabic-Indic and fullwidth digits):

**0 disagreements** on `isValid`, and **0 disagreements** on `calculate`
including which exception type is thrown.

## Running it

No Maven needed. `GenericValidator` drags in the whole legacy package, so compile
against a 4-line stub of the only method the routines use (`isBlankOrNull`,
copied verbatim from `GenericValidator.java:69-72`). `build.sh` does all of this:

```sh
./build.sh ../../../commons-validator   # or wherever the Java checkout lives
```

Then run whichever harness you want. Each reads `which<TAB>value` lines on stdin
(some take a locale or pattern column too - see the source) and writes the same
line plus the result:

| Harness | Dart counterpart | Covers |
| --- | --- | --- |
| `Diff.java` | `dart_diff.dart` | check digits |
| `Diff3.java` | `dart_diff3.dart` | regex, code and financial validators |
| `Diff4.java` | `dart_diff4.dart` | domain, email, URL, IP |
| `Diff5.java` | `dart_diff5.dart` | number validators, one locale |
| `Diff5L.java` | `dart_diff5l.dart` | number validators, several locales |
| `Diff6.java` | `dart_diff6.dart` | date and time comparisons |
| `Diff6P.java` | `dart_diff6p.dart` | date and time parsing |
| `IdnGen.java` | `dart_idn_diff.dart` | `IDN.toASCII`, one label per line |
| `UriDump.java` | `dart_uri_diff.dart` | `java.net.URI` components |
| `WeekDump.java` | `dart_week_diff.dart` | `Calendar` week numbering |

```sh
java -cp /tmp/cvdiff/classes Diff4 < corpus.tsv > java.tsv
dart run dart_diff4.dart corpus.tsv dart.tsv
diff java.tsv dart.tsv && echo identical
```

Two caveats when diffing:

- **Compare numerically, not textually,** for the number harnesses. Java's
  `BigDecimal` keeps its scale so it prints `1234.00` where `Decimal` prints
  `1234`, and Java uses `E` notation for large doubles. Float rows need comparing
  at 32-bit precision, because Java prints the shortest string that round-trips
  as a float.
- **`IdnReject2.java`** is not a comparison harness; it is the extractor that
  `../generate_idna_data.dart` supersedes. It is kept because it documents the
  "fails alone *and* embedded" rule that avoids bidi false positives.

## Known data divergences

These are differences in the *reference data* each platform ships, not in the
ported logic. They are the reason the number layer is documented as
"locale-dependent results may drift" rather than claimed to be exact.

- **`ja_JP` currency symbol.** Java's `DecimalFormatSymbols` gives U+FFE5
  (fullwidth `￥`); `intl` gives U+00A5 (`¥`). So a Japanese currency amount
  written with the halfwidth sign validates here and not on the JVM. Every other
  locale checked - `en_US`, `de_DE`, `fr_FR`, `ru_RU`, `sv_SE`, `it_IT` - agrees
  exactly, including `fr`'s U+202F grouping separator, `ru`/`sv`'s U+00A0, and
  `sv`'s U+2212 minus sign.
- **Unicode version.** The IDNA tables are generated from this JDK
  (`../generate_idna_data.dart`); a JDK built against a different Unicode version
  would legitimately shift the unassigned-code-point boundary.
