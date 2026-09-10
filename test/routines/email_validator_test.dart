import 'package:commons_validator/src/routines/domain_validator.dart';
import 'package:commons_validator/src/routines/email_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.EmailValidatorTest`.
///
/// The case lists are extracted from upstream's assertions on the default
/// instance.
void main() {
  final validator = EmailValidator.getInstance();

  const validAddresses = [
    'jsmith@apache.org',
    'jsmith@apache.org',
    'jsmith@apache.com',
    'jsmith@apache.net',
    'jsmith@apache.info',
    'someone@yahoo.museum',
    'joe1blow@apache.org',
    'joe\$blow@apache.org',
    'joe-@apache.org',
    'joe_@apache.org',
    'joe+@apache.org',
    'joe!@apache.org',
    'joe*@apache.org',
    'joe\'@apache.org',
    'joe%45@apache.org',
    'joe?@apache.org',
    'joe&@apache.org',
    'joe=@apache.org',
    '+joe@apache.org',
    '!joe@apache.org',
    '*joe@apache.org',
    '\'joe@apache.org',
    '%joe45@apache.org',
    '?joe@apache.org',
    '&joe@apache.org',
    '=joe@apache.org',
    '+@apache.org',
    '!@apache.org',
    '*@apache.org',
    '\'@apache.org',
    '%@apache.org',
    '?@apache.org',
    '&@apache.org',
    '=@apache.org',
    'joe.ok@apache.org',
    '"joe."@apache.org',
    '".joe"@apache.org',
    '"joe+"@apache.org',
    '"joe@"@apache.org',
    '"joe!"@apache.org',
    '"joe*"@apache.org',
    '"joe\'"@apache.org',
    '"joe("@apache.org',
    '"joe)"@apache.org',
    '"joe,"@apache.org',
    '"joe%45"@apache.org',
    '"joe;"@apache.org',
    '"joe?"@apache.org',
    '"joe&"@apache.org',
    '"joe="@apache.org',
    '".."@apache.org',
    '"john\\"doe"@apache.org',
    'john56789.john56789.john56789.john56789.john56789.john56789.john@example.com',
    '\\>escape\\\\special\\^characters\\<@example.com',
    'Abc\\@def@example.com',
    'space\\ monkey@example.com',
    'andy.o\'reilly@data-workshop.com',
    'foo+bar@i.am.not.in.us.example.com',
    'andy.noble@data-workshop.com',
    'someone@[IPv6:2001:db8::1]',
    'someone@[IPv6:::1]',
    'someone@[ipv6:fe80::1]',
    'someone@[216.109.118.76]',
    'someone@[216.109.118.76]',
    'someone@yahoo.com',
    'joe!/blow@apache.org',
    '"joeblow "@apache.org',
    '" joeblow"@apache.org',
    '" joe blow "@apache.org',
    'someone@xn--d1abbgf6aiiy.xn--p1ai',
    'someone@\u{043f}\u{0440}\u{0435}\u{0437}\u{0438}\u{0434}\u{0435}\u{043d}\u{0442}.\u{0440}\u{0444}',
    'someone@www.b\u{00fc}cher.ch',
    'someone@www.b\u{00fc}cher.ch',
    'abc-@abc.com',
    'abc_@abc.com',
    'abc-def@abc.com',
    'abc_def@abc.com',
    'me@att.net',
    'abc@school.school',
  ];

  const invalidAddresses = [
    'jsmith@apache.',
    'jsmith@apache.c',
    'someone@yahoo.mu-seum',
    'joe.@apache.org',
    '.joe@apache.org',
    '.@apache.org',
    'joe..ok@apache.org',
    '..@apache.org',
    'joe(@apache.org',
    'joe)@apache.org',
    'joe,@apache.org',
    'joe;@apache.org',
    'john56789.john56789.john56789.john56789.john56789.john56789.john5@example.com',
    'Abc@def@example.com',
    'andy.noble@\u{008f}data-workshop.com',
    'andy@o\'reilly.data-workshop.com',
    'foo+bar@example+3.com',
    'test@%*.com',
    'test@^&#.com',
    'joeblow@apa,che.org',
    'joeblow@apache.o,rg',
    'joeblow@apache,org',
    'andy-noble@data-workshop.-com',
    'andy-noble@data-workshop.c-om',
    'andy-noble@data-workshop.co-m',
    'andy.noble@data-workshop.com.',
    'someone@[2001:db8::1]',
    'someone@[::1]',
    'someone@[IPv6:216.109.118.76]',
    'joe@ap/ache.org',
    'joe@apac!he.org',
    'joeblow @apache.org',
    'joeblow@ apache.org',
    ' joeblow@apache.org',
    'joeblow@apache.org ',
    'joe blow@apache.org ',
    'joeblow@apa che.org ',
    'someone@www.\u{fffd}.ch',
    'someone@www.\u{fffd}.ch',
    'someone@-test.com',
    'someone@test-.com',
    'abc@abc_def.com',
    'me@at&t.net',
  ];

  test('valid addresses', () {
    for (final email in validAddresses) {
      expect(validator.isValid(email), isTrue, reason: email);
    }
  });

  test('invalid addresses', () {
    for (final email in invalidAddresses) {
      expect(validator.isValid(email), isFalse, reason: email);
    }
  });

  test('null is rejected', () => expect(validator.isValid(null), isFalse));

  test('a trailing dot is rejected before anything else', () {
    expect(validator.isValid('a@example.com.'), isFalse);
  });

  test('the local part is capped at 64 characters', () {
    expect(validator.isValid('${'a' * 64}@example.com'), isTrue);
    expect(validator.isValid('${'a' * 65}@example.com'), isFalse);
  });

  test('bracketed IP literals', () {
    expect(validator.isValid('a@[1.2.3.4]'), isTrue);
    expect(validator.isValid('a@[256.1.1.1]'), isFalse);
    expect(validator.isValid('a@[IPv6:::1]'), isTrue);
    // Upstream's inline (?i) makes the IPv6 tag case-insensitive; the port
    // spells that out in the character classes instead.
    expect(validator.isValid('a@[ipv6:::1]'), isTrue);
    expect(validator.isValid('a@[IPV6:::1]'), isTrue);
    expect(validator.isValid('a@[IPv6:not-an-address]'), isFalse);
  });

  test('allowLocal accepts a local domain', () {
    expect(validator.isValid('a@localhost'), isFalse);
    expect(
      EmailValidator.getInstance(allowLocal: true).isValid('a@localhost'),
      isTrue,
    );
  });

  test('allowTld accepts a bare TLD as the domain', () {
    expect(validator.isValid('a@com'), isFalse);
    final withTld = EmailValidator.getInstance(allowTld: true);
    expect(withTld.isValid('a@com'), isTrue);
    expect(withTld.isValid('a@example.com'), isTrue);
    expect(withTld.isValid('a@.com'), isFalse, reason: 'a leading dot is not');
  });

  test('a control character in the local part is rejected', () {
    // This is what \\p{Cc} guards, and why it must cover the C1 range too.
    for (final cp in [0x00, 0x1F, 0x7F, 0x85, 0x9F]) {
      final email = 'a${String.fromCharCode(cp)}b@example.com';
      expect(validator.isValid(email), isFalse,
          reason: 'U+\${cp.toRadixString(16)}');
    }
  });

  test('a DomainValidator disagreeing with allowLocal is rejected', () {
    expect(
      () => EmailValidator.withDomainValidator(
        allowLocal: true,
        allowTld: false,
        domainValidator: DomainValidator.getInstance(),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
