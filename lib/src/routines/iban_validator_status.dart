/// The outcome of an IBAN validation.
///
/// Ported from `org.apache.commons.validator.routines.IBANValidatorStatus`.
enum IBANValidatorStatus {
  /// The IBAN is well-formed and its check digits are correct.
  valid,

  /// No format definition is known for the IBAN's country code.
  unknownCountry,

  /// The length does not match the country's definition.
  invalidLength,

  /// The characters do not match the country's pattern.
  invalidPattern,

  /// The shape is right but the mod-97 check digits are wrong.
  invalidChecksum,
}
