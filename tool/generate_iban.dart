// ignore_for_file: avoid_print
/// Regenerates `lib/src/routines/iban_validators.dart` from the Java source.
///
/// Usage:
///   dart run tool/generate_iban.dart [path/to/commons-validator]
library;

import 'dart:io';

import 'generator_support.dart';

void main(List<String> args) {
  final upstream = resolveUpstream(args);
  final source = File(
    '$upstream/src/main/java/org/apache/commons/validator/routines/'
    'IBANValidator.java',
  ).readAsStringSync();

  final block = RegExp(
    r'private static final Validator\[\] DEFAULT_VALIDATORS = \{(.*?)\n    \};',
    dotAll: true,
  ).firstMatch(source);
  if (block == null) throw StateError('Cannot find DEFAULT_VALIDATORS');

  // Country names appear as trailing line comments; keep them as documentation.
  final comments = <String, String>{};
  for (final line in block.group(1)!.split('\n')) {
    final m =
        RegExp(r'new Validator\(\s*"([A-Z]{2})".*?//\s*(.*)$').firstMatch(line);
    if (m != null) comments[m.group(1)!] = m.group(2)!.trim();
  }

  final entries = <String>[];
  var aliasCount = 0;
  for (final m in RegExp(r'new Validator\(\s*(.*?)\s*\)\s*,', dotAll: true)
      .allMatches(block.group(1)!)) {
    final parts = m.group(1)!.split(',').map((p) => p.trim()).toList();
    final cc = parts[0].replaceAll('"', '');
    final length = int.parse(parts[1]);
    // Java writes `\\d` in its source string; reading the file gives two
    // characters, and a Dart raw string needs the single backslash.
    final regex =
        parts[2].substring(1, parts[2].length - 1).replaceAll(r'\\', '\\');
    final aliases = parts
        .skip(3)
        .where((p) => p.isNotEmpty)
        .map((p) => p.replaceAll('"', ''));
    if (regex.contains("'") || regex.contains(r'$')) {
      throw StateError('Regex needs escaping in a raw Dart string: $regex');
    }
    // Entries with aliases supply the pattern *without* the country prefix so
    // the body can be shared; the others include it.
    final note = comments[cc];
    final buffer = StringBuffer();
    if (note != null && note.isNotEmpty) buffer.writeln('  // $note');
    if (aliases.isEmpty) {
      buffer.write("  IBANCountryValidator('$cc', $length, r'$regex'),");
    } else {
      aliasCount++;
      final list = aliases.map((a) => "'$a'").join(', ');
      buffer.write(
        "  IBANCountryValidator.withoutCountryCodePrefix('$cc', $length, "
        "r'$regex', otherCountryCodes: [$list]),",
      );
    }
    entries.add(buffer.toString());
  }

  final out = StringBuffer()
    ..writeln(generatedHeader('tool/generate_iban.dart',
        '// Transcribed from `IBANValidator.DEFAULT_VALIDATORS`.'))
    ..writeln("import 'iban_validator.dart';")
    ..writeln()
    ..writeln(
        '/// The IBAN format definitions shipped with the library, one per country.')
    ..writeln('///')
    ..writeln(
        '/// A handful of entries carry alias country codes and supply their pattern')
    ..writeln(
        '/// *without* the country-code prefix, so the same body can be shared: FI covers')
    ..writeln(
        '/// AX, FR covers twelve overseas territories, and GB covers IM, JE and GG.')
    ..writeln('final List<IBANCountryValidator> defaultIBANValidators = [')
    ..writeln(entries.join('\n'))
    ..writeln('];');

  File('lib/src/routines/iban_validators.dart')
      .writeAsStringSync(out.toString());
  print('wrote ${entries.length} entries ($aliasCount with aliases)');
}
