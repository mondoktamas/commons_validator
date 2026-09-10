import 'domain_validator.dart';
import 'inet_address_validator.dart';

/// Validates email addresses against RFC 822 as interpreted by upstream.
///
/// Ported from `org.apache.commons.validator.routines.EmailValidator`.
class EmailValidator {
  EmailValidator._(this.allowLocal, this.allowTld)
      : domainValidator = DomainValidator.getInstance(allowLocal: allowLocal);

  /// Creates a validator using a caller-supplied [domainValidator].
  ///
  /// [domainValidator]'s `allowLocal` must agree with [allowLocal], as upstream
  /// requires.
  EmailValidator.withDomainValidator({
    required this.allowLocal,
    required this.allowTld,
    required this.domainValidator,
  }) {
    if (domainValidator.allowLocal != allowLocal) {
      throw ArgumentError.value(
        domainValidator,
        'domainValidator',
        'DomainValidator must agree with allowLocal setting',
      );
    }
  }

  // Two Java-vs-Dart regex differences are handled here.
  //
  // Java's \p{Cc} is U+0000-001F plus U+007F-009F. Dart's \p{Cc} is the same
  // set, but it needs the `unicode: true` flag, and that flag also turns on
  // ECMAScript u-mode, which rejects the `\"` escape this pattern contains. So
  // the class is expanded literally instead - and it must include the C1 range,
  // or control characters would be accepted in a local part.
  //
  // Java's \s is ASCII-only ([ \t\n\x0B\f\r]) whereas Dart's also matches
  // NBSP and the other Unicode spaces, so it is expanded too.
  static const String _cc = r'\x00-\x1F\x7F-\x9F';
  static const String _asciiSpace = r' \t\n\x0B\f\r';

  static const String _specialChars = '$_cc' r'\(\)<>@,;:' "'" r'\\".\[\]';
  static const String _validChars =
      '(\\\\[^$_cc])|[^$_asciiSpace$_specialChars]';
  static const String _quotedUser = '("(\\\\"|[^"$_cc])*")';
  static const String _word = "(($_validChars|')+|$_quotedUser)";

  static const String _emailRegex = '^(.+)@([^$_asciiSpace]+)\$';

  // Upstream writes this as `^\[((?i)IPv6:)?(.*)\]$`, using a Java inline flag
  // that Dart's RegExp does not support at all. Spelling the case-insensitivity
  // into the character classes keeps group 1 as group 1, which matters because
  // isValidDomain branches on whether it matched.
  static const String _ipDomainRegex = r'^\[([Ii][Pp][Vv]6:)?(.*)\]$';
  static const String _userRegex = '^$_word(\\.$_word)*\$';

  static final RegExp _emailPattern = RegExp(_emailRegex);
  static final RegExp _ipDomainPattern = RegExp(_ipDomainRegex);
  static final RegExp _userPattern = RegExp(_userRegex);

  static const int _maxUsernameLength = 64;

  static final EmailValidator _validator = EmailValidator._(false, false);
  static final EmailValidator _validatorWithTld = EmailValidator._(false, true);
  static final EmailValidator _validatorWithLocal =
      EmailValidator._(true, false);
  static final EmailValidator _validatorWithLocalWithTld =
      EmailValidator._(true, true);

  /// The shared instance for the given options.
  static EmailValidator getInstance({
    bool allowLocal = false,
    bool allowTld = false,
  }) {
    if (allowLocal) {
      return allowTld ? _validatorWithLocalWithTld : _validatorWithLocal;
    }
    return allowTld ? _validatorWithTld : _validator;
  }

  /// Whether local addresses such as `user@localhost` are accepted.
  final bool allowLocal;

  /// Whether a bare TLD is accepted as the domain, as in `user@com`.
  final bool allowTld;

  /// The domain validator applied to the part after the `@`.
  final DomainValidator domainValidator;

  /// Whether [email] is a valid email address.
  bool isValid(String? email) {
    // The trailing-dot check is first because it is cheap, as upstream notes.
    if (email == null || email.endsWith('.')) return false;
    final match = _fullMatch(_emailPattern, email);
    if (match == null) return false;
    return isValidUser(match.group(1)) && isValidDomain(match.group(2));
  }

  /// Whether [domain] is a valid domain part, including bracketed IP literals.
  bool isValidDomain(String? domain) {
    if (domain == null) return false;
    final ipMatch = _fullMatch(_ipDomainPattern, domain);
    if (ipMatch != null) {
      final inet = InetAddressValidator.getInstance();
      // Group 1 present means the literal was tagged IPv6:.
      if (ipMatch.group(1) != null) {
        return inet.isValidInet6Address(ipMatch.group(2));
      }
      return inet.isValidInet4Address(ipMatch.group(2));
    }
    if (allowTld) {
      return domainValidator.isValid(domain) ||
          (!domain.startsWith('.') && domainValidator.isValidTld(domain));
    }
    return domainValidator.isValid(domain);
  }

  /// Whether [user] is a valid local part.
  bool isValidUser(String? user) {
    if (user == null || user.length > _maxUsernameLength) return false;
    return _fullMatch(_userPattern, user) != null;
  }

  /// Java's `Matcher.matches()`, which Dart has no direct equivalent for.
  static Match? _fullMatch(RegExp pattern, String value) {
    final match = pattern.matchAsPrefix(value);
    return match != null && match.end == value.length ? match : null;
  }
}
