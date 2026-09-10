import '../internal/java_compat.dart';
import 'checkdigit/check_digit.dart';
import 'regex_validator.dart';

/// Validates a code: shape by regular expression, then length, then check digit.
///
/// Ported from `org.apache.commons.validator.routines.CodeValidator`.
///
/// Note [isValid] is defined as `validate(input) != null`, and [validate]
/// returns the *reformatted* code — separators removed by the regular
/// expression's capture groups. So a code can be valid here while its raw text
/// would fail the check digit, which is the intended behaviour.
class CodeValidator {
  /// Creates a validator from a [regex], with optional length bounds.
  ///
  /// Pass -1 (the default) for either bound to leave it unchecked. A blank
  /// [regex] means no shape check at all.
  CodeValidator(
    String? regex, {
    this.minLength = -1,
    this.maxLength = -1,
    this.checkDigit,
  }) : regexValidator = (regex == null || javaTrim(regex).isEmpty)
            ? null
            : RegexValidator(regex);

  /// Creates a validator from a prebuilt [regexValidator].
  CodeValidator.fromRegexValidator(
    this.regexValidator, {
    this.minLength = -1,
    this.maxLength = -1,
    this.checkDigit,
  });

  /// Creates a validator requiring an exact [length].
  CodeValidator.withLength(
    String? regex,
    int length, {
    CheckDigit? checkDigit,
  }) : this(regex,
            minLength: length, maxLength: length, checkDigit: checkDigit);

  /// The shape check, or null if there is none.
  final RegexValidator? regexValidator;

  /// The minimum acceptable length, or -1 for unchecked.
  final int minLength;

  /// The maximum acceptable length, or -1 for unchecked.
  final int maxLength;

  /// The check-digit routine, or null if there is none.
  final CheckDigit? checkDigit;

  /// Whether [input] is a valid code.
  bool isValid(String? input) => validate(input) != null;

  /// The reformatted code, or null if [input] is not valid.
  String? validate(String? input) {
    if (input == null) return null;
    var code = javaTrim(input);
    if (code.isEmpty) return null;
    final regex = regexValidator;
    if (regex != null) {
      final reformatted = regex.validate(code);
      if (reformatted == null) return null;
      code = reformatted;
    }
    if ((minLength >= 0 && code.length < minLength) ||
        (maxLength >= 0 && code.length > maxLength)) {
      return null;
    }
    if (checkDigit != null && !checkDigit!.isValid(code)) return null;
    return code;
  }
}
