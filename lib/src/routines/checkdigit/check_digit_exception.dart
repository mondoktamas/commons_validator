/// Thrown when a check digit cannot be calculated or a code is malformed.
///
/// Ported from
/// `org.apache.commons.validator.routines.checkdigit.CheckDigitException`.
/// Upstream's varargs constructor formats via `String.format`, which Dart has
/// no equivalent of; callers here build the message themselves. Messages are
/// therefore close to but not byte-identical with the Java ones, and no test
/// asserts on their text.
class CheckDigitException implements Exception {
  /// Creates an exception with an optional [message].
  const CheckDigitException([this.message]);

  /// Reports a character that is not valid at the given position.
  ///
  /// Mirrors `"Invalid Character[%d,%d] = '%c'"`.
  CheckDigitException.invalidCharacter(int leftPos, int rightPos, String char)
      : message = "Invalid Character[$leftPos,$rightPos] = '$char'";

  /// Reports a check digit value that cannot be rendered.
  ///
  /// Mirrors `"Invalid Check Digit Value =%d"`.
  CheckDigitException.invalidCheckDigitValue(int charValue)
      : message = 'Invalid Check Digit Value =$charValue';

  /// Reports a code whose length is not acceptable.
  CheckDigitException.invalidLength(int length)
      : message = 'Invalid Code length=$length';

  /// The missing-code case, `"Code is missing"`.
  const CheckDigitException.missingCode() : message = 'Code is missing';

  /// A human-readable description, or null.
  final String? message;

  @override
  String toString() =>
      message == null ? 'CheckDigitException' : 'CheckDigitException: $message';
}
