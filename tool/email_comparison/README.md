# Email validator comparison

Compares this package's `EmailValidator` against the two most-used email
validators on pub.dev.

```sh
cd tool/email_comparison
dart pub get
dart run bin/compare.dart
```

It is its own package, so the versions under test are pinned in its
`pubspec.yaml`, and `commons_validator` is pulled **from pub.dev** rather than
from the checkout above it — the numbers below are what a user of the published
package gets, not what this working tree happens to do.

## Results

Versions under test: `commons_validator` 0.1.0, `email_validator` 3.0.0,
`string_validator` 1.2.0.

| Package | Score |
| :-- | :-- |
| `commons_validator` | **52/52** |
| `email_validator` | 50/52 |
| `string_validator` | 45/52 |

`email_validator` misses only `user@example.zzzzzz` and `user@example.qwerty` —
it does not check whether the TLD exists. `string_validator` misses those plus
IPv4 and IPv6 address literals, both RFC length limits, and a single-letter TLD.

The practical consequence is typo TLDs:

| Address | commons | email_validator | string_validator |
| :-- | :-- | :-- | :-- |
| `user@gmail.con` | rejected | accepted | accepted |
| `user@gmail.cmo` | rejected | accepted | accepted |
| `user@gmail.ocm` | rejected | accepted | accepted |
| `user@hotmail.comm` | rejected | accepted | accepted |
| `user@yahoo.co.ukk` | rejected | accepted | accepted |
| `user@outlook.cm` | accepted | accepted | accepted |
| `user@company.nte` | rejected | accepted | accepted |
| `user@company.orgg` | rejected | accepted | accepted |
| **caught** | **7/8** | **0/8** | **0/8** |

`.cm` is Cameroon, so accepting `user@outlook.cm` is correct in all three.

This is a trade-off rather than a free win: the IANA TLD list is bundled with
this package, so a newly delegated TLD is rejected until the table is
regenerated (`dart run tool/generate_tlds.dart`) and a new version published.
A regex-based validator has no such maintenance burden.

## How the corpus is built

Only addresses whose answer is **not in dispute** are scored — cases drawn from
RFC 5321 and RFC 5322 where the specification and common practice agree. Each
carries a one-line note saying what it tests.

Addresses where implementations may legitimately differ are printed in a
separate `CONTESTED` section and excluded from the totals, so this package is
never scored as "right" for its own judgement calls. Those are:

- `admin@mailserver1` — a bare hostname, valid only if local domains are allowed
- `email@123.123.123.123` — an IP address without brackets
- `email@example` — no TLD at all
- `user@exämple.com` — a unicode domain the caller has not punycoded

All three packages happen to agree on all four.

A validator that throws on hostile input is recorded as returning false rather
than crashing the run, so no package is scored down for the harness's own error
handling.
