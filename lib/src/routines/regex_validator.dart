/// Validates a string against one or more regular expressions.
///
/// Ported from `org.apache.commons.validator.routines.RegexValidator`.
///
/// Every method matches the *whole* input, because upstream uses Java's
/// `Matcher.matches()`. Dart has no equivalent, so patterns are matched as a
/// prefix and the end offset is checked — that way a caller-supplied pattern
/// without anchors still behaves as Java would.
class RegexValidator {
  /// Creates a validator for a single [regex].
  ///
  /// Set [caseSensitive] to false to fold case. Note Java folds ASCII only
  /// here, whereas Dart's [RegExp] folds Unicode, so the two differ for
  /// non-ASCII input.
  RegexValidator(String regex, {bool caseSensitive = true})
      : this.fromList([regex], caseSensitive: caseSensitive);

  /// Creates a validator that accepts a value matching any of [regexs].
  RegexValidator.fromList(List<String> regexs, {bool caseSensitive = true})
      : patterns = List<RegExp>.unmodifiable(
          _compile(regexs, caseSensitive: caseSensitive),
        );

  static List<RegExp> _compile(
    List<String> regexs, {
    required bool caseSensitive,
  }) {
    if (regexs.isEmpty) {
      throw ArgumentError.value(
          regexs, 'regexs', 'Regular expressions are missing');
    }
    return [
      for (var i = 0; i < regexs.length; i++)
        if (regexs[i].isEmpty)
          throw ArgumentError.value(
            regexs[i],
            'regexs',
            'Regular expression[$i] is missing',
          )
        else
          RegExp(regexs[i], caseSensitive: caseSensitive),
    ];
  }

  /// The compiled patterns, in the order they are tried.
  final List<RegExp> patterns;

  /// The first pattern that matches [value] in full, or null.
  Match? _firstFullMatch(String value) {
    for (final pattern in patterns) {
      final match = pattern.matchAsPrefix(value);
      if (match != null && match.end == value.length) return match;
    }
    return null;
  }

  /// Whether [value] matches any pattern in full.
  bool isValid(String? value) =>
      value != null && _firstFullMatch(value) != null;

  /// The capture groups of the first matching pattern, or null if none matched.
  ///
  /// Groups are numbered from 1, so group 0 (the whole match) is *not*
  /// included, matching upstream.
  List<String?>? match(String? value) {
    if (value == null) return null;
    final match = _firstFullMatch(value);
    if (match == null) return null;
    return [for (var i = 1; i <= match.groupCount; i++) match.group(i)];
  }

  /// The matched value with every capture group concatenated, or null.
  ///
  /// This is how the code validators strip separators: a pattern that captures
  /// the digit runs either side of a hyphen returns the digits joined, with the
  /// hyphen dropped. Null groups are skipped.
  String? validate(String? value) {
    if (value == null) return null;
    final match = _firstFullMatch(value);
    if (match == null) return null;
    if (match.groupCount == 1) return match.group(1) ?? '';
    final buffer = StringBuffer();
    for (var i = 1; i <= match.groupCount; i++) {
      final component = match.group(i);
      if (component != null) buffer.write(component);
    }
    return buffer.toString();
  }

  @override
  String toString() =>
      'RegexValidator{${patterns.map((p) => p.pattern).join(',')}}';
}
