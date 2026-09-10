/// Helpers shared by the `tool/generate_*.dart` scripts.
library;

import 'dart:io';

/// The default location of the Java checkout these tables are derived from.
const defaultUpstream = '../commons-validator';

/// Resolves the upstream Java checkout from [args], falling back to
/// [defaultUpstream], and fails loudly if it is not there.
String resolveUpstream(List<String> args) {
  final path = args.isNotEmpty ? args.first : defaultUpstream;
  if (!Directory('$path/src/main/java').existsSync()) {
    stderr.writeln(
      'Cannot find a Commons Validator checkout at "$path".\n'
      'Pass its path as the first argument.',
    );
    exit(2);
  }
  return path;
}

/// The banner every generated file carries.
String generatedHeader(String script, [String extra = '']) => '''
// GENERATED FILE - do not edit by hand.
//
// Regenerate with $script.
${extra.isEmpty ? '' : '//\n$extra'}
''';

/// The string literals of a `private static final String[] NAME = { ... };`
/// declaration in [source].
///
/// Line comments are stripped first, because upstream keeps commented-out
/// entries that must not be collected.
List<String> javaStringArray(String source, String name) {
  // GENERIC_TLDS closes with an unindented `};` while the others are indented,
  // so accept any indentation.
  final match = RegExp(
    r'private static final String\[\]\s+' + name + r'\s*=\s*\{(.*?)\n[ \t]*\};',
    dotAll: true,
  ).firstMatch(source);
  if (match == null) throw StateError('Cannot find $name in the Java source');
  final body = match.group(1)!.split('\n').map((line) {
    final comment = line.indexOf('//');
    return comment >= 0 ? line.substring(0, comment) : line;
  }).join('\n');
  return RegExp('"([^"]*)"').allMatches(body).map((m) => m.group(1)!).toList();
}

/// Throws if [values] is not in ascending order, which binary search requires.
void checkSorted(List<String> values, String name) {
  for (var i = 1; i < values.length; i++) {
    if (values[i].compareTo(values[i - 1]) <= 0) {
      throw StateError(
        '$name is not sorted: "${values[i]}" follows "${values[i - 1]}"',
      );
    }
  }
}

/// Formats [values] as indented Dart list entries, wrapping on item boundaries.
///
/// Wrapping by column would split a string literal in half, which is exactly the
/// bug an earlier version of these generators had.
String packStringList(List<String> values,
    {int width = 76, String indent = '  '}) {
  final lines = <String>[];
  var current = indent;
  for (final value in values) {
    final item = "'$value',";
    if (current != indent && current.length + 1 + item.length > width) {
      lines.add(current);
      current = '$indent$item';
    } else {
      current = current == indent ? '$indent$item' : '$current $item';
    }
  }
  if (current.trim().isNotEmpty) lines.add(current);
  return lines.join('\n');
}
