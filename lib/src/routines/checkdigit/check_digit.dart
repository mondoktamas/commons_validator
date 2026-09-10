/// Calculates and validates a check digit for a code.
///
/// Ported from `org.apache.commons.validator.routines.checkdigit.CheckDigit`.
abstract interface class CheckDigit {
  /// Calculates the check digit for [code], which must *not* already include
  /// one.
  ///
  /// Throws [CheckDigitException] if the check digit cannot be calculated.
  String calculate(String? code);

  /// Whether [code], including its check digit, is valid.
  ///
  /// Never throws: an invalid code returns false. Upstream implements this by
  /// catching [CheckDigitException], and the port keeps that structure because
  /// the exception is genuinely used as control flow.
  bool isValid(String? code);
}
