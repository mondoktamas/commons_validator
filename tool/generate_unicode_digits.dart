// ignore_for_file: avoid_print
/// Regenerates `lib/src/internal/unicode_digits.dart`.
///
/// Usage:
///   dart run tool/generate_unicode_digits.dart
///
/// Finds every run of ten consecutive Unicode decimal digits by asking the JDK,
/// which is also the authority the port is matched against: `DecimalFormat` falls
/// back to `Character.digit(ch, 10)`, so it parses Arabic-Indic and fullwidth
/// digits and the port has to as well.
library;

import 'dart:io';

import 'generator_support.dart';

const _java = '''
public class DigitRuns {
    public static void main(String[] a) {
        StringBuilder sb = new StringBuilder();
        for (int cp = 0; cp <= 0x10FFFF; cp++) {
            if (Character.digit(cp, 10) != 0) continue;
            boolean run = true;
            for (int i = 0; i < 10 && run; i++) {
                if (Character.digit(cp + i, 10) != i) run = false;
            }
            if (run) { sb.append(cp).append('\\n'); cp += 9; }
        }
        System.out.print(sb);
        System.out.println(System.getProperty("java.version"));
    }
}
''';

void main(List<String> args) {
  final temp = Directory.systemTemp.createTempSync('digits_gen');
  try {
    File('${temp.path}/DigitRuns.java').writeAsStringSync(_java);
    final compile = Process.runSync('javac', ['DigitRuns.java'],
        workingDirectory: temp.path);
    if (compile.exitCode != 0) {
      stderr.writeln('javac failed. Is a JDK on PATH?\n${compile.stderr}');
      exit(2);
    }
    final run =
        Process.runSync('java', ['DigitRuns'], workingDirectory: temp.path);
    final lines = (run.stdout as String).trim().split('\n');
    final jdk = lines.removeLast().trim();
    final zeros = lines.map(int.parse).toList()..sort();

    final body = zeros
        .map((z) => '  0x${z.toRadixString(16).toUpperCase().padLeft(4, '0')},')
        .join('\n');

    File('lib/src/internal/unicode_digits.dart').writeAsStringSync('''
${generatedHeader('tool/generate_unicode_digits.dart')}
/// The starting code point of each contiguous run of ten Unicode decimal digits.
///
/// `java.text.DecimalFormat` falls back to `Character.digit(ch, 10)` when a
/// character is not the locale's own zero digit, so it happily parses
/// Arabic-Indic and fullwidth digits. Without this table the port would be
/// stricter than Java.
///
/// Note this is the opposite of the check-digit routines, which reject non-ASCII
/// digits - there the guard is explicit in the Java source.
///
/// Extracted from OpenJDK $jdk, ${zeros.length} runs.
const List<int> unicodeDigitZeros = [
$body
];

/// The decimal value of [codePoint], or -1 if it is not a decimal digit.
int unicodeDigitValue(int codePoint) {
  if (codePoint >= 0x30 && codePoint <= 0x39) return codePoint - 0x30;
  for (final zero in unicodeDigitZeros) {
    if (codePoint >= zero && codePoint <= zero + 9) return codePoint - zero;
  }
  return -1;
}
''');
    print('wrote ${zeros.length} digit runs (JDK $jdk)');
  } finally {
    temp.deleteSync(recursive: true);
  }
}
