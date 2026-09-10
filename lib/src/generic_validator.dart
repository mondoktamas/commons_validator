import 'internal/java_compat.dart';

/// The parts of `org.apache.commons.validator.GenericValidator` that the
/// `routines` package actually depends on.
///
/// Upstream's class is much larger, but the rest of it pulls in `Constants`,
/// `DateValidator` and `GenericTypeValidator`, none of which any `routines`
/// class uses. Only [isBlankOrNull] is referenced from `routines`;
/// [matchRegexp] is included because it is trivially portable and useful.
abstract final class GenericValidator {
  /// Whether [value] is null, empty, or contains only whitespace.
  ///
  /// Uses [javaTrim], not [String.trim], so a string consisting only of NBSP is
  /// *not* blank — matching Java. `GenericValidator.isBlankOrNull` is on the
  /// hot path of `InetAddressValidator` and both abstract format validators, so
  /// the distinction propagates widely.
  static bool isBlankOrNull(String? value) =>
      value == null || value.isEmpty || javaTrim(value).isEmpty;

  /// Whether [value] matches [regexp] in full.
  ///
  /// An empty or null pattern is always false, matching upstream. The match is
  /// anchored because Java's `Pattern.matches` requires the whole region to
  /// match, whereas Dart's [RegExp.hasMatch] is a substring search.
  static bool matchRegexp(String value, String? regexp) {
    if (regexp == null || regexp.isEmpty) return false;
    final match = RegExp(regexp).matchAsPrefix(value);
    return match != null && match.end == value.length;
  }
}
