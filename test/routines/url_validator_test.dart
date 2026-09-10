import 'package:commons_validator/src/routines/domain_validator.dart';
import 'package:commons_validator/src/routines/url_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.UrlValidatorTest`.
///
/// Upstream builds a URL out of one entry from each part table and walks the
/// whole cartesian product - 43,200 combinations - expecting the URL to be valid
/// exactly when every part is. That structure is reproduced here; the part
/// tables are upstream's own.
void main() {
  // (part, isItselfValid)
  const urlScheme = <(String, bool)>[
    ('http://', true),
    ('ftp://', true),
    ('h3t://', true),
    ('3ht://', false),
    ('http:/', false),
    ('http:', false),
    ('http/', false),
    ('://', false),
  ];
  const urlAuthority = <(String, bool)>[
    ('www.google.com', true),
    ('www.google.com.', true),
    ('go.com', true),
    ('go.au', true),
    ('0.0.0.0', true),
    ('255.255.255.255', true),
    ('256.256.256.256', false),
    ('255.com', true),
    ('1.2.3.4.5', false),
    ('1.2.3.4.', false),
    ('1.2.3', false),
    ('.1.2.3.4', false),
    ('go.a', false),
    ('go.a1a', false),
    ('go.cc', true),
    ('go.1aa', false),
    ('aaa.', false),
    ('.aaa', false),
    ('aaa', false),
    ('', false),
  ];
  const urlPort = <(String, bool)>[
    (':80', true),
    (':65535', true),
    (':65536', false),
    (':0', true),
    ('', true),
    (':-1', false),
    (':65636', false),
    (':999999999999999999', false),
    (':65a', false),
  ];
  const urlPath = <(String, bool)>[
    ('/test1', true),
    ('/t123', true),
    ('/\$23', true),
    ('/..', false),
    ('/../', false),
    ('/test1/', true),
    ('', true),
    ('/test1/file', true),
    ('/..//file', false),
    ('/test1//file', false),
  ];
  const urlPathOptions = <(String, bool)>[
    ('/test1', true),
    ('/t123', true),
    ('/\$23', true),
    ('/..', false),
    ('/../', false),
    ('/test1/', true),
    ('/#', false),
    ('', true),
    ('/test1/file', true),
    ('/t123/file', true),
    ('/\$23/file', true),
    ('/../file', false),
    ('/..//file', false),
    ('/test1//file', true),
    ('/#/file', false),
  ];
  const urlQuery = <(String, bool)>[
    ('?action=view', true),
    ('?action=edit&mode=up', true),
    ('', true),
  ];
  const schemes = <(String, bool)>[
    ('http', true),
    ('ftp', false),
    ('httpd', false),
    ('gopher', true),
    ('g0-to+.', true),
    ('not_valid', false),
    ('HtTp', true),
    ('telnet', false),
  ];

  /// Walks the cartesian product of [parts], asserting that [validator]
  /// considers the concatenation valid exactly when every part is valid.
  void expectCartesian(
    UrlValidator validator,
    List<List<(String, bool)>> parts,
  ) {
    final index = List<int>.filled(parts.length, 0);
    var checked = 0;
    while (true) {
      final buffer = StringBuffer();
      var expected = true;
      for (var i = 0; i < parts.length; i++) {
        final (value, ok) = parts[i][index[i]];
        buffer.write(value);
        expected &= ok;
      }
      final url = buffer.toString();
      expect(validator.isValid(url), expected, reason: url);
      checked++;

      // Odometer increment, least significant part first.
      var carry = true;
      for (var i = parts.length - 1; i >= 0 && carry; i--) {
        if (index[i] < parts[i].length - 1) {
          index[i]++;
          carry = false;
        } else {
          index[i] = 0;
        }
      }
      if (carry) break; // wrapped around, so every combination was seen
    }
    expect(checked, parts.fold<int>(1, (a, p) => a * p.length));
  }

  test('isValid over the full part product', () {
    // Upstream runs this with ALLOW_ALL_SCHEMES, which is why part tables
    // include schemes such as h3t:// and expect them to be valid.
    expectCartesian(
      UrlValidator(options: UrlValidator.allowAllSchemes),
      [urlScheme, urlAuthority, urlPort, urlPath, urlQuery],
    );
  });

  test('isValid over the path options', () {
    expectCartesian(
      UrlValidator(
        options: UrlValidator.allow2Slashes |
            UrlValidator.allowAllSchemes |
            UrlValidator.noFragments,
      ),
      [urlScheme, urlAuthority, urlPort, urlPathOptions, urlQuery],
    );
  });

  test('scheme validation', () {
    // Upstream's scheme list, including the deliberately invalid `not_valid`.
    final validator = UrlValidator(
      schemes: ['http', 'gopher', 'g0-To+.', 'not_valid'],
    );
    for (final (scheme, expected) in schemes) {
      expect(validator.isValidScheme(scheme), expected, reason: scheme);
    }
  });

  test('a custom scheme list is honoured', () {
    final validator = UrlValidator(schemes: ['http', 'gopher', 'g0-to+.']);
    expect(validator.isValidScheme('http'), isTrue);
    expect(validator.isValidScheme('gopher'), isTrue);
    expect(validator.isValidScheme('ftp'), isFalse);
    expect(validator.isValidScheme('HTTP'), isTrue, reason: 'case insensitive');
  });

  test('ALLOW_ALL_SCHEMES accepts anything well formed', () {
    final validator = UrlValidator(options: UrlValidator.allowAllSchemes);
    expect(validator.isValidScheme('telnet'), isTrue);
    expect(validator.isValidScheme('not_valid'), isFalse, reason: 'underscore');
  });

  test('NO_FRAGMENTS rejects a fragment', () {
    final withFragments = UrlValidator();
    final noFragments = UrlValidator(options: UrlValidator.noFragments);
    expect(
        withFragments.isValid('http://www.google.com/path#fragment'), isTrue);
    expect(noFragments.isValid('http://www.google.com/path#fragment'), isFalse);
    expect(noFragments.isValid('http://www.google.com/path'), isTrue);
  });

  test('null is rejected', () => expect(UrlValidator().isValid(null), isFalse));

  test('the file scheme may have an empty authority', () {
    final validator = UrlValidator(schemes: ['file']);
    expect(validator.isValid('file:///tmp/x'), isTrue);
    expect(validator.isValid('file:/tmp/x'), isTrue);
    // `localhost` is not a valid domain without ALLOW_LOCAL_URLS, so a file URL
    // naming it is rejected - verified against the JVM.
    expect(validator.isValid('file://localhost/tmp/x'), isFalse);
    // A colon in a file authority is rejected outright.
    expect(validator.isValid('file://host:1/tmp'), isFalse);
    expect(
      UrlValidator(schemes: ['file'], options: UrlValidator.allowLocalUrls)
          .isValid('file://localhost/tmp/x'),
      isTrue,
    );
  });

  test('ALLOW_LOCAL_URLS accepts localhost', () {
    expect(UrlValidator().isValid('http://localhost/x'), isFalse);
    expect(
      UrlValidator(options: UrlValidator.allowLocalUrls)
          .isValid('http://localhost/x'),
      isTrue,
    );
  });

  test('a huge port is rejected', () {
    // Java's Integer.parseInt throws here; Dart's int.tryParse would not, so the
    // digit count is checked explicitly.
    expect(UrlValidator().isValid('http://example.com:99999999999999999999/'),
        isFalse);
    expect(UrlValidator().isValid('http://example.com:65535/'), isTrue);
    expect(UrlValidator().isValid('http://example.com:65536/'), isFalse);
  });

  test('parent-directory traversal is rejected', () {
    final validator = UrlValidator();
    expect(validator.isValid('http://example.com/../x'), isFalse);
    expect(validator.isValid('http://example.com/..'), isFalse);
    expect(validator.isValid('http://example.com/a/../b'), isTrue);
  });

  test('an IPv6 literal authority', () {
    final validator = UrlValidator();
    expect(validator.isValid('http://[::1]/'), isTrue);
    expect(validator.isValid('http://[::1]:8080/'), isTrue);
    expect(validator.isValid('http://[not-an-address]/'), isFalse);
  });

  test('a DomainValidator disagreeing with ALLOW_LOCAL_URLS is rejected', () {
    expect(
      () => UrlValidator(
        options: UrlValidator.allowLocalUrls,
        domainValidator: DomainValidator.getInstance(),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => UrlValidator(
        options: UrlValidator.allowLocalUrls,
        domainValidator: DomainValidator.getInstance(allowLocal: true),
      ),
      returnsNormally,
    );
  });
}
