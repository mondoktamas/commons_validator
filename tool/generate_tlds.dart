// ignore_for_file: avoid_print
/// Regenerates `lib/src/routines/domain_tlds.dart` from the Java source.
///
/// Usage:
///   dart run tool/generate_tlds.dart [path/to/commons-validator]
///
/// The two large tables come from *different* IANA snapshots upstream - generic
/// TLDs from 2026-06-23, country codes from 2024-04-02 - so this reads whatever
/// the Java source currently holds rather than fetching from IANA. Refreshing
/// one table in isolation would silently diverge from upstream.
library;

import 'dart:io';

import 'generator_support.dart';

const _tables = <String, (String javaName, String doc)>{
  'infrastructureTlds': (
    'INFRASTRUCTURE_TLDS',
    'Infrastructure TLDs: just `arpa`.'
  ),
  'genericTlds': (
    'GENERIC_TLDS',
    'Generic TLDs, from IANA snapshot 2026-06-23.'
  ),
  'countryCodeTlds': (
    'COUNTRY_CODE_TLDS',
    'Country-code TLDs, from IANA snapshot 2024-04-02.'
  ),
  'localTlds': (
    'LOCAL_TLDS',
    'TLDs valid only on a local network, such as `localhost`.'
  ),
};

void main(List<String> args) {
  final upstream = resolveUpstream(args);
  final source = File(
    '$upstream/src/main/java/org/apache/commons/validator/routines/'
    'DomainValidator.java',
  ).readAsStringSync();

  final out = StringBuffer()
    ..writeln(generatedHeader('tool/generate_tlds.dart', '''
// Transcribed from the String[] tables in DomainValidator.java.
//
// The two large tables come from *different* IANA snapshots upstream, so do not
// "helpfully" refresh one of them in isolation.'''))
    ..writeln('/// The TLD tables backing `DomainValidator`.')
    ..writeln('///')
    ..writeln(
        '/// Each list is sorted, matching upstream\'s binary search, and')
    ..writeln('/// every entry is lower case.')
    ..writeln('library;')
    ..writeln();

  _tables.forEach((dartName, spec) {
    final (javaName, doc) = spec;
    final values = javaStringArray(source, javaName);
    checkSorted(values, javaName);
    for (final v in values) {
      if (v.isEmpty || v != v.toLowerCase()) {
        throw StateError('$javaName holds a non-lower-case entry: $v');
      }
    }
    out
      ..writeln('/// $doc')
      ..writeln('///')
      ..writeln('/// ${values.length} entries, sorted.')
      ..writeln('const List<String> $dartName = [')
      ..writeln(packStringList(values))
      ..writeln('];')
      ..writeln();
    print('$javaName: ${values.length} entries');
  });

  File('lib/src/routines/domain_tlds.dart').writeAsStringSync(out.toString());
  print('wrote lib/src/routines/domain_tlds.dart');
}
