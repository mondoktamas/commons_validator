// Compares commons_validator's EmailValidator against the two most-used email
// validators on pub.dev.
//
// Run with `dart run bin/compare.dart` from this directory.
//
// The scored corpus only contains addresses where RFC 5321/5322 and common
// practice agree on the answer. Cases where implementations may legitimately
// differ are reported separately and not scored, so the totals do not quietly
// reward this package for its own judgement calls.

import 'package:commons_validator/commons_validator.dart' as cv;
import 'package:email_validator/email_validator.dart' as ev;
import 'package:string_validator/string_validator.dart' as sv;

/// A validator returning false rather than throwing, so one package's exception
/// on hostile input is not scored as a crash of the harness.
bool _safe(bool Function() f) {
  try {
    return f();
  } catch (_) {
    return false;
  }
}

final validators = <String, bool Function(String)>{
  'commons_validator': (s) =>
      _safe(() => cv.EmailValidator.getInstance().isValid(s)),
  'email_validator': (s) => _safe(() => ev.EmailValidator.validate(s)),
  'string_validator': (s) => _safe(() => sv.isEmail(s)),
};

class Case {
  const Case(this.address, this.valid, this.why);

  final String address;
  final bool valid;
  final String why;
}

final nul = String.fromCharCode(0);
final long64 = 'a' * 64;
final long65 = 'a' * 65;
final label63 = 'a' * 63;
final label64 = 'a' * 64;

/// Addresses whose correct answer is not in dispute.
final scored = <Case>[
  // Valid.
  const Case('simple@example.com', true, 'the basic case'),
  const Case('very.common@example.com', true, 'dot in the local part'),
  const Case('x@example.com', true, 'one-character local part'),
  const Case(
      'user+tag@example.co.uk', true, 'plus addressing, multi-label TLD'),
  const Case('user.name+tag+sorting@example.com', true, 'multiple plus tags'),
  const Case(
    'other.email-with-hyphen@example.com',
    true,
    'hyphen in the local part',
  ),
  const Case(
      'example-indeed@strange-example.com', true, 'hyphen in the domain'),
  const Case('1234567890@example.com', true, 'all-digit local part'),
  const Case('_______@example.com', true, 'underscores'),
  const Case('email@example.name', true, 'the .name TLD'),
  const Case('email@example.museum', true, 'a long TLD'),
  const Case('test/test@test.com', true, 'a slash is legal in a local part'),
  const Case(
    r"!#$%&'*+-/=?^_`{|}~@example.com",
    true,
    'every legal special character',
  ),
  const Case('"quoted"@example.com', true, 'quoted local part, RFC 5321 4.1.2'),
  const Case(
    '"much.more unusual"@example.com',
    true,
    'space inside a quoted local part',
  ),
  const Case('user@[192.168.1.1]', true, 'IPv4 address literal, RFC 5321'),
  const Case('user@[IPv6:2001:db8::1]', true, 'IPv6 address literal'),
  const Case('email@subdomain.example.com', true, 'subdomain'),
  const Case('user@example.app', true, 'a real modern TLD'),
  const Case('user@example.co', true, 'a real ccTLD'),
  const Case('user@xn--exmple-cua.com', true, 'punycoded IDN domain'),
  Case('$long64@example.com', true, 'local part of exactly 64, the RFC limit'),
  Case('user@$label63.com', true, 'domain label of exactly 63'),

  // Invalid.
  const Case('plainaddress', false, 'no @ at all'),
  const Case('@example.com', false, 'empty local part'),
  const Case('email@', false, 'empty domain'),
  const Case('.email@example.com', false, 'local part starts with a dot'),
  const Case('email.@example.com', false, 'local part ends with a dot'),
  const Case(
    'email..email@example.com',
    false,
    'consecutive dots in the local part',
  ),
  const Case('email@example..com', false, 'consecutive dots in the domain'),
  const Case('email@-example.com', false, 'domain label starts with a hyphen'),
  const Case('email@example-.com', false, 'domain label ends with a hyphen'),
  const Case('a@b@c@example.com', false, 'multiple @'),
  const Case('email@111.222.333.44444', false, 'octets out of range'),
  const Case(
    'just"not"right@example.com',
    false,
    'quotes in the middle, unquoted',
  ),
  const Case('this is not allowed@example.com', false, 'unquoted spaces'),
  const Case('email@example.com ', false, 'trailing space'),
  const Case(' email@example.com', false, 'leading space'),
  const Case('email@.com', false, 'domain starts with a dot'),
  const Case('email@example.com.', false, 'trailing dot on the domain'),
  const Case('Abc..123@example.com', false, 'consecutive dots again'),
  const Case(
    'email@[192.168.1.256]',
    false,
    'out-of-range octet in a literal',
  ),
  const Case('user@example.zzzzzz', false, 'TLD not in the IANA list'),
  const Case('user@example.qwerty', false, 'another made-up TLD'),
  Case('$long65@example.com', false, 'local part of 65, over the RFC limit'),
  Case('user@$label64.com', false, 'domain label of 64, over the limit'),
  const Case(
    'user@example.com\n',
    false,
    'trailing newline, header injection',
  ),
  const Case('user\n@example.com', false, 'newline in the local part'),
  const Case(
    'user@example.com\r\nBcc: x@y.com',
    false,
    'CRLF header injection',
  ),
  Case('user@exam${nul}ple.com', false, 'NUL byte in the domain'),
  const Case('user@example.c', false, 'single-letter TLD'),
  const Case('user@example.123', false, 'all-numeric TLD'),
];

/// Legitimately contested: reported, never scored.
const contested = <Case>[
  Case(
    'admin@mailserver1',
    false,
    'a bare hostname, valid only if local domains are allowed',
  ),
  Case('email@123.123.123.123', false, 'an IP address without brackets'),
  Case('email@example', false, 'no TLD at all'),
  Case('user@exämple.com', true,
      'a unicode domain the caller has not punycoded'),
];

/// Typos a real user makes in a signup form. Every TLD here is fictional.
const typos = <String>[
  'user@gmail.con',
  'user@gmail.cmo',
  'user@gmail.ocm',
  'user@hotmail.comm',
  'user@yahoo.co.ukk',
  'user@outlook.cm',
  'user@company.nte',
  'user@company.orgg',
];

String _show(String address, {int width = 40}) {
  final escaped = address
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll(nul, r'\0');
  if (escaped.length <= width) return escaped;
  return '${escaped.substring(0, width - 3)}...';
}

String _header() => '${'address'.padRight(42)}${'want'.padRight(7)}'
    '${validators.keys.map((k) => k.split('_').first.padRight(11)).join()}';

void main() {
  final score = {for (final k in validators.keys) k: 0};
  final wrong = {for (final k in validators.keys) k: <Case>[]};

  print('SCORED — ${scored.length} cases whose answer is not in dispute\n');
  print(_header());
  print('-' * 86);

  for (final c in scored) {
    final got = {for (final e in validators.entries) e.key: e.value(c.address)};
    for (final e in got.entries) {
      if (e.value == c.valid) {
        score[e.key] = score[e.key]! + 1;
      } else {
        wrong[e.key]!.add(c);
      }
    }
    print('${_show(c.address).padRight(42)}${'${c.valid}'.padRight(7)}'
        '${got.entries.map((e) => (e.value == c.valid ? 'ok' : 'WRONG').padRight(11)).join()}');
  }

  print('\n${'=' * 86}');
  for (final e in score.entries) {
    print('  ${e.key.padRight(20)} ${e.value}/${scored.length}');
  }
  print('=' * 86);

  for (final e in wrong.entries) {
    if (e.value.isEmpty) continue;
    print('\n${e.key} gets ${e.value.length} wrong:');
    for (final c in e.value) {
      print('  ${_show(c.address, width: 34).padRight(36)} ${c.why}');
    }
  }

  print('\n\nTYPO TLDs — every one of these should be rejected\n');
  print('${'address'.padRight(42)}'
      '${validators.keys.map((k) => k.split('_').first.padRight(11)).join()}');
  print('-' * 79);
  final caught = {for (final k in validators.keys) k: 0};
  for (final t in typos) {
    final got = {for (final e in validators.entries) e.key: e.value(t)};
    for (final e in got.entries) {
      if (!e.value) caught[e.key] = caught[e.key]! + 1;
    }
    print('${t.padRight(42)}'
        '${got.values.map((v) => (v ? 'accepted' : 'rejected').padRight(11)).join()}');
  }
  print('');
  for (final e in caught.entries) {
    print('  ${e.key.padRight(20)} caught ${e.value}/${typos.length}');
  }
  print('\n  Note: .cm is Cameroon, so accepting user@outlook.cm is correct.');

  print('\n\nCONTESTED — reported, not scored\n');
  for (final c in contested) {
    final got = {for (final e in validators.entries) e.key: e.value(c.address)};
    print('  ${_show(c.address, width: 24).padRight(26)}'
        '${got.entries.map((e) => '${e.key.split('_').first}=${e.value}').join('  ')}');
    print('      ${c.why}');
  }
}
