// ignore_for_file: avoid_print
/// Regenerates `lib/src/internal/idna_data.dart`.
///
/// Usage:
///   dart run tool/generate_idna_data.dart
///
/// Every table here is derived from the JDK on PATH, because the JDK *is* the
/// parity target: `DomainValidator` is defined in terms of `java.net.IDN`, and
/// guessing at RFC 3454's tables from the spec produced 319 disagreements before
/// this approach replaced it.
///
/// - the case folds come from round-tripping each code point through
///   `IDN.toASCII` and `IDN.toUnicode`, which reveals exactly what nameprep maps
///   it to;
/// - the rejected ranges come from asking which code points `IDN.toASCII`
///   refuses;
/// - the bidirectional classes come from `Character.getDirectionality`.
library;

import 'dart:convert';
import 'dart:io';

import 'generator_support.dart';

const _java = r'''
import java.net.IDN;
public class IdnaTables {
    static boolean fails(String label) {
        try { IDN.toASCII(label); return false; } catch (RuntimeException e) { return true; }
    }
    /** A code point counts as rejected only when it fails alone AND embedded.
     *  Requiring both avoids false positives for right-to-left scripts, where the
     *  embedded form fails on the bidi rules because of the Latin letters around it. */
    static boolean rejects(int cp) {
        String ch = new String(Character.toChars(cp));
        return fails(ch) && fails("a" + ch + "b");
    }
    /** An inert non-ASCII anchor: CJK, so it has no case, no combining
     *  behaviour, and no NFKC decomposition to interact with the code point
     *  under test. It also forces IDN to run nameprep at all - toASCII
     *  short-circuits a pure-ASCII label, so an "a...b" anchor would reveal
     *  nothing about ASCII code points. */
    static final String ANCHOR = "\u4E00";
    /** What nameprep maps cp to, read back out of the JDK, or null if unknown. */
    static String fold(int cp) {
        String ch = new String(Character.toChars(cp));
        String label = ANCHOR + ch + ANCHOR;
        try {
            String back = IDN.toUnicode(IDN.toASCII(label));
            if (!back.startsWith(ANCHOR) || !back.endsWith(ANCHOR)) return null;
            return back.substring(ANCHOR.length(), back.length() - ANCHOR.length());
        } catch (RuntimeException e) { return null; }
    }
    public static void main(String[] a) {
        StringBuilder out = new StringBuilder();
        out.append("VERSION\t").append(System.getProperty("java.version")).append('\n');
        int rejectStart = -1;
        for (int cp = 0; cp <= 0x10FFFF; cp++) {
            if (cp >= 0xD800 && cp <= 0xDFFF) continue;
            boolean bad = rejects(cp);
            if (bad && rejectStart < 0) rejectStart = cp;
            if (!bad && rejectStart >= 0) {
                out.append("REJECT\t").append(rejectStart).append('\t').append(cp - 1).append('\n');
                rejectStart = -1;
            }
            if (!bad) {
                String f = fold(cp);
                String self = new String(Character.toChars(cp));
                if (f != null && !f.equals(self)) {
                    out.append("FOLD\t").append(cp);
                    for (int i = 0; i < f.length(); ) {
                        int c = f.codePointAt(i);
                        out.append('\t').append(c);
                        i += Character.charCount(c);
                    }
                    out.append('\n');
                }
            }
            byte dir = Character.getDirectionality(cp);
            String cls = null;
            if (dir == Character.DIRECTIONALITY_RIGHT_TO_LEFT
             || dir == Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC) cls = "RANDAL";
            else if (dir == Character.DIRECTIONALITY_LEFT_TO_RIGHT) cls = "LCAT";
            if (cls != null) out.append("BIDI\t").append(cp).append('\t').append(cls).append('\n');
        }
        if (rejectStart >= 0) {
            out.append("REJECT\t").append(rejectStart).append('\t').append(0x10FFFF).append('\n');
        }
        System.out.print(out);
    }
}
''';

void main(List<String> args) {
  final temp = Directory.systemTemp.createTempSync('idna_gen');
  try {
    File('${temp.path}/IdnaTables.java').writeAsStringSync(_java);
    print('compiling the extractor...');
    final compile = Process.runSync('javac', ['IdnaTables.java'],
        workingDirectory: temp.path);
    if (compile.exitCode != 0) {
      stderr.writeln('javac failed. Is a JDK on PATH?\n${compile.stderr}');
      exit(2);
    }
    print(
        'walking all 1.1M code points through the JDK (this takes a minute)...');
    final run = Process.runSync(
      'java',
      ['-Xmx2g', 'IdnaTables'],
      workingDirectory: temp.path,
      stdoutEncoding: utf8,
    );
    if (run.exitCode != 0) {
      stderr.writeln('java failed:\n${run.stderr}');
      exit(2);
    }

    var jdk = 'unknown';
    final rejects = <(int, int)>[];
    final foldSingle = <int, int>{};
    final foldMulti = <int, List<int>>{};
    final randAl = <int>[];
    final lcat = <int>[];

    for (final line in const LineSplitter().convert(run.stdout as String)) {
      final p = line.split('\t');
      switch (p.first) {
        case 'VERSION':
          jdk = p[1];
        case 'REJECT':
          rejects.add((int.parse(p[1]), int.parse(p[2])));
        case 'FOLD':
          final cp = int.parse(p[1]);
          final to = p.skip(2).map(int.parse).toList();
          if (to.length == 1) {
            foldSingle[cp] = to.single;
          } else {
            foldMulti[cp] = to;
          }
        case 'BIDI':
          (p[2] == 'RANDAL' ? randAl : lcat).add(int.parse(p[1]));
      }
    }

    String hex(int v) =>
        '0x${v.toRadixString(16).toUpperCase().padLeft(4, '0')}';
    String ranges(List<int> points) {
      final out = <String>[];
      var i = 0;
      while (i < points.length) {
        final start = points[i];
        var end = start;
        while (i + 1 < points.length && points[i + 1] == end + 1) {
          end = points[++i];
        }
        out.add('  ${hex(start)}, ${hex(end)},');
        i++;
      }
      return out.join('\n');
    }

    String pairs(Map<int, int> map, {int perLine = 6}) {
      final keys = map.keys.toList()..sort();
      final lines = <String>[];
      var current = <String>[];
      for (final k in keys) {
        current.add('${hex(k)}: ${hex(map[k]!)},');
        if (current.length == perLine) {
          lines.add('  ${current.join(' ')}');
          current = [];
        }
      }
      if (current.isNotEmpty) lines.add('  ${current.join(' ')}');
      return lines.join('\n');
    }

    final rejectRanges =
        rejects.map((r) => '  ${hex(r.$1)}, ${hex(r.$2)},').join('\n');

    final multiLines = (foldMulti.keys.toList()..sort())
        .map((k) => '  ${hex(k)}: [${foldMulti[k]!.map(hex).join(', ')}],')
        .join('\n');

    File('lib/src/internal/idna_data.dart').writeAsStringSync('''
${generatedHeader('tool/generate_idna_data.dart')}
/// Reference data for the IDNA-2003 implementation in `idna.dart`.
///
/// Every table is derived from OpenJDK $jdk, because the JDK is the parity
/// target: `DomainValidator` is defined in terms of `java.net.IDN`. Rebuilding
/// against a different JDK would legitimately shift these, since a newer Unicode
/// version assigns more code points.
library;

/// Nameprep case folds that map to a single code point.
///
/// RFC 3454 Table B.2 applies *full* case folding, which Dart's
/// [String.toLowerCase] does not implement. ${foldSingle.length} entries.
const Map<int, int> caseFoldingSingle = {
${pairs(foldSingle)}
};

/// Nameprep case folds that map to more than one code point.
///
/// ${foldMulti.length} entries, the best known of which is U+00DF -> `ss`.
const Map<int, List<int>> caseFoldingMulti = {
$multiLines
};

/// Code point ranges `java.net.IDN.toASCII` rejects, as flat `[low, high, ...]`
/// pairs.
///
/// Covers RFC 3454 Table A.1 (unassigned in the Unicode version nameprep is
/// specified against) together with the C.* prohibited-output tables, exactly as
/// the reference JDK sees them - measured rather than assumed.
///
/// A code point counts as rejected only when it fails both alone and embedded in
/// `a<cp>b`. Requiring both avoids false positives for right-to-left scripts,
/// where the embedded form fails the RFC 3454 section 6 bidi rules because of the
/// surrounding Latin letters rather than because of the code point.
const List<int> idnRejectedRanges = [
$rejectRanges
];

/// Code point ranges with bidirectional class `R` or `AL`, RFC 3454's
/// `RandALCat`, as flat `[low, high, ...]` pairs.
const List<int> bidiRandALCatRanges = [
${ranges(randAl)}
];

/// Code point ranges with bidirectional class `L`, RFC 3454's `LCat`, as flat
/// `[low, high, ...]` pairs.
const List<int> bidiLCatRanges = [
${ranges(lcat)}
];
''');
    print(
        'wrote ${foldSingle.length} single + ${foldMulti.length} multi folds, '
        '${rejects.length} reject ranges, '
        '${randAl.length} RandALCat / ${lcat.length} LCat code points (JDK $jdk)');
  } finally {
    temp.deleteSync(recursive: true);
  }
}
