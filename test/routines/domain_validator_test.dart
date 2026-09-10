import 'package:commons_validator/src/routines/domain_tlds.dart';
import 'package:commons_validator/src/routines/domain_validator.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.routines.DomainValidatorTest`.
///
/// Upstream's `main` method downloads the current IANA lists to regenerate the
/// tables; that is a maintenance utility rather than a test, and is not ported.
void main() {
  final validator = DomainValidator.getInstance();
  final validatorWithLocal = DomainValidator.getInstance(allowLocal: true);

  test('valid domains', () {
    for (final domain in [
      'apache.org',
      'www.google.com',
      'test-domain.com',
      'test---domain.com',
      'test-d-o-m-a-i-n.com',
      'as.uk',
      'ApAchE.Org',
      'z.com',
      'i.have.an-example.domain.name',
    ]) {
      expect(validator.isValid(domain), isTrue, reason: domain);
    }
  });

  test('invalid domains', () {
    for (final domain in [
      '.org',
      ' apache.org ',
      'apa che.org',
      '-testdomain.name',
      'testdomain-.name',
      '---c.com',
      'c--.com',
      'apache.rog',
      'http://www.apache.org',
      '',
    ]) {
      expect(validator.isValid(domain), isFalse, reason: domain);
    }
    expect(validator.isValid(null), isFalse);
  });

  test('top level domains', () {
    expect(validator.isValidInfrastructureTld('.arpa'), isTrue);
    expect(validator.isValidInfrastructureTld('.com'), isFalse);
    expect(validator.isValidGenericTld('.name'), isTrue);
    expect(validator.isValidGenericTld('.us'), isFalse);
    expect(validator.isValidCountryCodeTld('.uk'), isTrue);
    expect(validator.isValidCountryCodeTld('.org'), isFalse);
    expect(validator.isValidTld('.co.uk'), isFalse);
    expect(validator.isValidTld('.org'), isTrue);
  });

  test('allowLocal accepts local names', () {
    expect(validator.isValid('localhost'), isFalse);
    expect(validator.isValid('localhost.localdomain'), isFalse);
    expect(validator.isValid('hostname'), isFalse);
    expect(validator.isValid('machinename'), isFalse);

    expect(validatorWithLocal.isValid('localhost'), isTrue);
    expect(validatorWithLocal.isValid('localhost.localdomain'), isTrue);
    expect(validatorWithLocal.isValid('hostname'), isTrue);
    expect(validatorWithLocal.isValid('machinename'), isTrue);

    // Ordinary domains keep working either way.
    expect(validatorWithLocal.isValid('apache.org'), isTrue);
    expect(validatorWithLocal.isValid(' apache.org '), isFalse);
  });

  test('domain syntax, independent of the TLD lists', () {
    expect(validator.isValidDomainSyntax('a'), isTrue);
    expect(validator.isValidDomainSyntax('9'), isTrue);
    expect(validator.isValidDomainSyntax('c-z'), isTrue);
    expect(validator.isValidDomainSyntax('c-'), isFalse);
    expect(validator.isValidDomainSyntax('-c'), isFalse);
    expect(validator.isValidDomainSyntax('-'), isFalse);
  });

  test('IDN domains', () {
    expect(validator.isValid('www.xn--bcher-kva.ch'), isTrue);
    // The same host spelled in Unicode.
    expect(
      validator.isValid('www.${String.fromCharCodes([
            0x62,
            0xFC,
            0x63,
            0x68,
            0x65,
            0x72,
          ])}.ch'),
      isTrue,
    );
  });

  test('a soft hyphen cannot be smuggled into a host', () {
    // IDN.toASCII would silently delete it, turning this into a different,
    // clean host - so DomainValidator rejects it instead.
    final soft = String.fromCharCode(0xAD);
    expect(validator.isValid('exam${soft}ple.com'), isFalse);
  });

  test('VALIDATOR-501: a hyphen at a label boundary is rejected even with IDN',
      () {
    final eacute = String.fromCharCode(0xE9);
    expect(validator.isValid('-t${eacute}st.com'), isFalse);
    expect(validator.isValid('t${eacute}st-.com'), isFalse);
  });

  test('an over-long name is rejected', () {
    final label = 'a' * 63;
    // 4 x 63 chars plus dots plus a TLD comfortably exceeds 253.
    expect(validator.isValid('$label.$label.$label.$label.com'), isFalse);
  });

  group('overrides', () {
    tearDown(DomainValidator.resetOverridesForTesting);

    test('instance-scoped overrides add and remove TLDs', () {
      final v = DomainValidator.getInstanceWithOverrides([
        const Item(ArrayType.genericPlus, ['ourtld']),
        const Item(ArrayType.countryCodeMinus, ['uk']),
      ]);
      expect(v.isValid('example.ourtld'), isTrue);
      expect(v.isValidGenericTld('ourtld'), isTrue);
      expect(v.isValid('example.uk'), isFalse, reason: 'uk was removed');
      // The shared instance is untouched.
      expect(DomainValidator.getInstance().isValid('example.ourtld'), isFalse);
      expect(DomainValidator.getInstance().isValid('example.uk'), isTrue);
    });

    test('overrides are lower-cased and reported back', () {
      final v = DomainValidator.getInstanceWithOverrides([
        const Item(ArrayType.genericPlus, ['OurTld', 'another']),
      ]);
      expect(v.getOverrides(ArrayType.genericPlus), ['another', 'ourtld']);
      expect(v.isValid('example.OURTLD'), isTrue);
    });

    test('the process-wide override must be set before getInstance', () {
      DomainValidator.resetOverridesForTesting();
      DomainValidator.updateTLDOverride(ArrayType.genericPlus, ['globaltld']);
      expect(
        DomainValidator.getTLDEntries(ArrayType.genericPlus),
        ['globaltld'],
      );
      expect(
          DomainValidator.getInstance().isValid('example.globaltld'), isTrue);
      // Once an instance exists the tables are frozen. Upstream gets this
      // isolation from a fresh classloader per test; the Dart port exposes a
      // reset hook instead.
      expect(
        () => DomainValidator.updateTLDOverride(
            ArrayType.genericPlus, ['toolate']),
        throwsA(isA<StateError>()),
      );
    });

    test('a read-only table cannot be overridden', () {
      DomainValidator.resetOverridesForTesting();
      for (final table in [
        ArrayType.genericRo,
        ArrayType.countryCodeRo,
        ArrayType.infrastructureRo,
        ArrayType.localRo,
      ]) {
        expect(
          () => DomainValidator.updateTLDOverride(table, ['x']),
          throwsA(isA<ArgumentError>()),
          reason: table.name,
        );
      }
    });
  });

  group('the generated tables', () {
    test('sizes match the Java source', () {
      expect(infrastructureTlds.length, 1);
      expect(genericTlds.length, 1127);
      expect(countryCodeTlds.length, 309);
      expect(localTlds.length, 2);
    });

    test('every table is sorted and lower case, as binary search requires', () {
      for (final table in [
        infrastructureTlds,
        genericTlds,
        countryCodeTlds,
        localTlds,
      ]) {
        for (var i = 0; i < table.length; i++) {
          expect(table[i], table[i].toLowerCase());
          if (i > 0) {
            expect(table[i].compareTo(table[i - 1]), greaterThan(0));
          }
        }
      }
    });
  });
}
