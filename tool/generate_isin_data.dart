// ignore_for_file: avoid_print
/// Regenerates `lib/src/routines/isin_data.dart`.
///
/// Usage:
///   dart run tool/generate_isin_data.dart [path/to/commons-validator]
///
/// The country list cannot come from Dart: upstream reads it from
/// `Locale.getISOCountries()`, live JDK data. It is therefore extracted by
/// running a small Java program against the JDK on PATH, and the JDK version is
/// recorded in the output so the provenance is visible.
library;

import 'dart:io';

import 'generator_support.dart';

const _countriesJava = '''
import java.util.*;
public class IsoCountries {
    public static void main(String[] a) {
        String[] c = Locale.getISOCountries();
        Arrays.sort(c);
        System.out.println(String.join(",", c));
        System.out.println(System.getProperty("java.version"));
    }
}
''';

void main(List<String> args) {
  final upstream = resolveUpstream(args);
  final temp = Directory.systemTemp.createTempSync('isin_gen');
  try {
    // --- country codes, straight from the JDK ---
    File('${temp.path}/IsoCountries.java').writeAsStringSync(_countriesJava);
    final compile = Process.runSync('javac', ['IsoCountries.java'],
        workingDirectory: temp.path);
    if (compile.exitCode != 0) {
      stderr.writeln('javac failed. Is a JDK on PATH?\n${compile.stderr}');
      exit(2);
    }
    final run =
        Process.runSync('java', ['IsoCountries'], workingDirectory: temp.path);
    if (run.exitCode != 0) {
      stderr.writeln('java failed:\n${run.stderr}');
      exit(2);
    }
    final lines = (run.stdout as String).trim().split('\n');
    final countries = lines[0].split(',')..sort();
    final jdk = lines[1].trim();

    // --- the non-ISO prefixes, from the Java source ---
    final source = File(
      '$upstream/src/main/java/org/apache/commons/validator/routines/'
      'ISINValidator.java',
    ).readAsStringSync();
    final specials = javaStringArray(source, 'SPECIALS')..sort();

    final out = StringBuffer()
      ..writeln(generatedHeader('tool/generate_isin_data.dart'))
      ..writeln('/// Reference data for `ISINValidator`.')
      ..writeln('///')
      ..writeln(
          '/// Upstream reads its country list from `Locale.getISOCountries()`,')
      ..writeln(
          '/// which is live JDK/CLDR data that Dart has no equivalent for. This')
      ..writeln(
          '/// list is therefore pinned: it was extracted from OpenJDK $jdk. A')
      ..writeln(
          '/// newer JDK may know more codes, so ISIN country validation can differ')
      ..writeln('/// from a JVM running a different release - see README.md.')
      ..writeln('library;')
      ..writeln()
      ..writeln('/// ISO 3166-1 alpha-2 country codes, sorted.')
      ..writeln('/// Extracted from OpenJDK $jdk.')
      ..writeln('const List<String> isinCountryCodes = [')
      ..writeln(packStringList(countries))
      ..writeln('];')
      ..writeln()
      ..writeln('/// Non-ISO prefixes ISIN also allows, sorted.')
      ..writeln('///')
      ..writeln('/// Transcribed from `ISINValidator.SPECIALS`.')
      ..writeln('const List<String> isinSpecialCodes = [')
      ..writeln(packStringList(specials))
      ..writeln('];');

    File('lib/src/routines/isin_data.dart').writeAsStringSync(out.toString());
    print(
        'wrote ${countries.length} countries (JDK $jdk) + ${specials.length} specials');
  } finally {
    temp.deleteSync(recursive: true);
  }
}
