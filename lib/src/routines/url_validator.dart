import '../generic_validator.dart';
import '../internal/ascii.dart';
import '../internal/java_compat.dart';
import '../internal/uri_parts.dart';
import 'domain_validator.dart';
import 'inet_address_validator.dart';
import 'regex_validator.dart';

/// Validates URLs by scheme, authority, path, query and fragment.
///
/// Ported from `org.apache.commons.validator.routines.UrlValidator`.
///
/// Options are a bitmask of [allowAllSchemes], [allow2Slashes], [noFragments]
/// and [allowLocalUrls], combined with `|`. Note this class carries its own
/// bitmask rather than using `Flags`, and its `isOn` test is `(options & flag) > 0`
/// - upstream does the same, and the two differ for multi-bit masks.
class UrlValidator {
  /// Creates a validator.
  ///
  /// [schemes] defaults to http, https and ftp. Pass an [authorityValidator] to
  /// accept authorities that would otherwise fail, and a [domainValidator] whose
  /// `allowLocal` agrees with the [allowLocalUrls] bit.
  UrlValidator({
    List<String>? schemes,
    this.authorityValidator,
    this.options = 0,
    DomainValidator? domainValidator,
  })  : domainValidator = domainValidator ??
            DomainValidator.getInstance(
              allowLocal: (options & allowLocalUrls) > 0,
            ),
        allowedSchemes = (options & allowAllSchemes) > 0
            ? const <String>{}
            : {
                for (final scheme in schemes ?? _defaultSchemes)
                  asciiToLowerCase(scheme),
              } {
    if (this.domainValidator.allowLocal != ((options & allowLocalUrls) > 0)) {
      throw ArgumentError.value(
        domainValidator,
        'domainValidator',
        'DomainValidator disagrees with ALLOW_LOCAL_URLS setting',
      );
    }
  }

  static const int _maxUnsigned16BitInt = 0xFFFF;

  /// Accept any scheme, not just the configured list.
  static const int allowAllSchemes = 1 << 0;

  /// Allow `//` to appear inside the path.
  static const int allow2Slashes = 1 << 1;

  /// Reject any URL carrying a fragment.
  static const int noFragments = 1 << 2;

  /// Allow local host names such as `localhost`.
  static const int allowLocalUrls = 1 << 3;

  // Java's \p{Alpha} and \p{Alnum} are ASCII-only POSIX classes; Dart has no
  // equivalent property name, and the Unicode properties that look similar are
  // wider. Expanded explicitly here for that reason.
  static const String _schemeRegex = r'^[A-Za-z][A-Za-z0-9\+\-\.]*';
  static const String _authorityCharsRegex = r'A-Za-z0-9\-\.';
  static const String _ipv6Regex = '[0-9a-fA-F:.]+';
  static const String _userinfoCharsRegex = r"[a-zA-Z0-9%-._~!$&'()*+,;=]";
  static const String _userinfoFieldRegex =
      '$_userinfoCharsRegex+(?::$_userinfoCharsRegex*)?@';
  static const String _authorityRegex =
      '(?:$_userinfoFieldRegex)?(?:\\[($_ipv6Regex)\\]|'
      '([$_authorityCharsRegex]*))(?::(\\d*))?(.*)?';
  static const String _pathRegex = r"^(/[-\w:@&?=+,.!/~*'%$_;\(\)]*)?$";
  // Java's \S is ASCII-only; Dart's excludes Unicode spaces too.
  static const String _queryRegex = r'^([^ \t\n\x0B\f\r]*)$';

  static final RegExp _schemePattern = RegExp(_schemeRegex);
  static final RegExp _authorityPattern = RegExp(_authorityRegex);
  static final RegExp _pathPattern = RegExp(_pathRegex);
  static final RegExp _queryPattern = RegExp(_queryRegex);

  static const int _parseAuthorityIpv6 = 1;
  static const int _parseAuthorityHostIp = 2; // excludes userinfo if present
  static const int _parseAuthorityPort = 3; // excludes the leading colon
  static const int _parseAuthorityExtra = 4;

  static const List<String> _defaultSchemes = ['http', 'https', 'ftp'];

  static final UrlValidator _instance = UrlValidator();

  /// The shared instance, accepting http, https and ftp with no options set.
  static UrlValidator getInstance() => _instance;

  /// The option bitmask.
  final int options;

  /// The accepted schemes, lower-cased, or empty when [allowAllSchemes] is set.
  final Set<String> allowedSchemes;

  /// An optional extra check that can accept an authority outright.
  final RegexValidator? authorityValidator;

  /// The validator applied to the host part of the authority.
  final DomainValidator domainValidator;

  bool _isOff(int flag) => (options & flag) == 0;

  /// Whether [value] is a valid URL.
  bool isValid(String? value) {
    if (value == null) return false;

    // A syntax gate first, exactly as upstream uses `new URI(value)`.
    final uri = parseUri(value);
    if (uri == null) return false;

    final scheme = uri.scheme;
    if (!isValidScheme(scheme)) return false;

    final authority = uri.rawAuthority;
    final fileScheme = scheme != null && asciiToLowerCase(scheme) == 'file';
    final emptyFileAuthority =
        fileScheme && GenericValidator.isBlankOrNull(authority);
    if (!emptyFileAuthority &&
        ((fileScheme && authority != null && authority.contains(':')) ||
            !isValidAuthority(authority))) {
      return false;
    }

    return isValidPath(uri.rawPath) &&
        isValidQuery(uri.rawQuery) &&
        isValidFragment(uri.rawFragment);
  }

  /// Whether [scheme] is a well-formed and permitted scheme.
  bool isValidScheme(String? scheme) {
    if (scheme == null || !_fullMatch(_schemePattern, scheme)) return false;
    if (_isOff(allowAllSchemes) &&
        !allowedSchemes.contains(asciiToLowerCase(scheme))) {
      return false;
    }
    return true;
  }

  /// Whether [authority] is a valid host, optional userinfo and optional port.
  bool isValidAuthority(String? authority) {
    if (authority == null) return false;
    final extra = authorityValidator;
    if (extra != null && extra.isValid(authority)) return true;

    final authorityAscii = unicodeToAscii(authority);
    final match = _authorityPattern.matchAsPrefix(authorityAscii);
    if (match == null || match.end != authorityAscii.length) return false;

    final ipv6 = match.group(_parseAuthorityIpv6);
    if (ipv6 != null) {
      if (!InetAddressValidator.getInstance().isValidInet6Address(ipv6)) {
        return false;
      }
    } else {
      final hostLocation = match.group(_parseAuthorityHostIp);
      if (!domainValidator.isValid(hostLocation) &&
          !InetAddressValidator.getInstance()
              .isValidInet4Address(hostLocation)) {
        return false;
      }
    }

    final port = match.group(_parseAuthorityPort);
    if (!GenericValidator.isBlankOrNull(port)) {
      // Java's Integer.parseInt throws for a huge port; Dart's int.tryParse
      // would happily accept it, so the digit count has to be checked too or
      // `http://h:99999999999999999999/` slips through.
      if (port!.length > 5) return false;
      final portValue = int.tryParse(port);
      if (portValue == null ||
          portValue < 0 ||
          portValue > _maxUnsigned16BitInt) {
        return false;
      }
    }

    final trailing = match.group(_parseAuthorityExtra);
    if (trailing != null && javaTrim(trailing).isNotEmpty) return false;
    return true;
  }

  /// Whether [path] is a valid path.
  bool isValidPath(String? path) {
    if (path == null || !_fullMatch(_pathPattern, path)) return false;
    final decoded = _decodeFormPath(path);
    if (decoded == null) return false;
    final normalized = _normalizePath(decoded);
    // Trying to escape above the root.
    if (normalized.startsWith('/../') || normalized == '/..') return false;
    if (_isOff(allow2Slashes) && countToken('//', decoded) > 0) return false;
    return true;
  }

  /// Whether [query] is a valid query string. A null query is valid.
  bool isValidQuery(String? query) =>
      query == null || _fullMatch(_queryPattern, query);

  /// Whether a fragment is permitted. The content is never inspected.
  bool isValidFragment(String? fragment) =>
      fragment == null || _isOff(noFragments);

  /// How many times [token] occurs in [target], counting overlaps as upstream
  /// does.
  int countToken(String token, String target) {
    var index = 0;
    var count = 0;
    while (index != -1) {
      index = target.indexOf(token, index);
      if (index > -1) {
        index++;
        count++;
      }
    }
    return count;
  }

  /// `java.net.URLDecoder.decode(path, "UTF-8")`, returning null where that
  /// would throw.
  ///
  /// This is the *form* decoder, so `+` becomes a space and a malformed `%`
  /// escape is an error - neither of which [Uri.decodeComponent] does the same
  /// way.
  static String? _decodeFormPath(String path) {
    final bytes = <int>[];
    for (var i = 0; i < path.length; i++) {
      final c = path.codeUnitAt(i);
      if (c == 0x2B) {
        bytes.add(0x20); // '+' decodes to a space
      } else if (c == 0x25) {
        if (i + 2 >= path.length) return null;
        final hex = path.substring(i + 1, i + 3);
        final value = int.tryParse(hex, radix: 16);
        if (value == null) return null;
        bytes.add(value);
        i += 2;
      } else {
        bytes.add(c);
      }
    }
    try {
      return String.fromCharCodes(bytes);
    } on ArgumentError {
      return null;
    }
  }

  /// Resolves `.` and `..` segments the way `URI.normalize` does.
  ///
  /// Java deliberately *keeps* a leading `..` that would escape the root rather
  /// than discarding it, which is the whole point of the check in [isValidPath]:
  /// `/../x` normalizes to `/../x`, not to `/x`.
  static String _normalizePath(String path) {
    final absolute = path.startsWith('/');
    final segments = <String>[];
    // Java's normalize also collapses empty segments, so `//a/../b` becomes
    // `/b` and `/a//b` becomes `/a/b`.
    for (final segment in path.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      } else if (segment == '..') {
        // Only a real named segment can be cancelled, so a `..` that would
        // escape the root survives - which is exactly what [isValidPath] looks
        // for.
        if (segments.isNotEmpty && segments.last != '..') {
          segments.removeLast();
        } else {
          segments.add(segment);
        }
      } else {
        segments.add(segment);
      }
    }
    final joined = segments.join('/');
    return absolute ? '/$joined' : joined;
  }

  /// Java's `Matcher.matches()`.
  static bool _fullMatch(RegExp pattern, String value) {
    final match = pattern.matchAsPrefix(value);
    return match != null && match.end == value.length;
  }
}
