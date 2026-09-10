import '../generic_validator.dart';
import '../internal/ascii.dart';
import '../internal/java_compat.dart';
import 'regex_validator.dart';

/// Validates IPv4 and IPv6 addresses.
///
/// Ported from `org.apache.commons.validator.routines.InetAddressValidator`.
class InetAddressValidator {
  /// Creates a validator.
  InetAddressValidator();

  static const int _maxPrefixBits = 128;
  static const int _ipv4MaxOctetValue = 255;
  static const int _maxUnsignedShort = 0xFFFF;
  static const int _ipv6MaxHexGroups = 8;
  static const int _ipv6MaxHexDigitsPerGroup = 4;

  static const String _ipv4Regex =
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$';

  static final RegExp _digitsPattern = RegExp(r'^\d{1,3}$');
  // Java's \s is ASCII-only, so a zone id containing NBSP is legal there;
  // Dart's \s would reject it.
  static final RegExp _idCheckPattern = RegExp(r'^[^ \t\n\x0B\f\r/%]+$');
  static final RegexValidator _ipv4Validator = RegexValidator(_ipv4Regex);

  static final InetAddressValidator _instance = InetAddressValidator();

  /// The shared instance.
  static InetAddressValidator getInstance() => _instance;

  /// Whether [inetAddress] is a valid IPv4 or IPv6 address.
  bool isValid(String? inetAddress) =>
      isValidInet4Address(inetAddress) || isValidInet6Address(inetAddress);

  /// Whether [inet4Address] is a valid dotted-quad IPv4 address.
  ///
  /// Leading zeros are rejected, so `010.1.1.1` is not valid.
  bool isValidInet4Address(String? inet4Address) {
    final groups = _ipv4Validator.match(inet4Address);
    if (groups == null) return false;
    for (final segment in groups) {
      if (GenericValidator.isBlankOrNull(segment)) return false;
      final value = int.tryParse(segment!);
      if (value == null) return false;
      if (value > _ipv4MaxOctetValue ||
          (segment.length > 1 && segment.startsWith('0'))) {
        return false;
      }
    }
    return true;
  }

  /// Whether [inet6Address] is a valid IPv6 address, optionally with a `/prefix`
  /// or a `%zone-id`.
  bool isValidInet6Address(String? inet6Address) {
    if (inet6Address == null) return false;
    var address = inet6Address;

    // Java's split(re, -1) keeps trailing empty strings, which is what makes the
    // "at most one prefix" check work.
    var parts = javaSplit(address, '/', limit: -1);
    if (parts.length > 2) return false; // only one prefix specifier allowed
    if (parts.length == 2) {
      if (!_digitsPattern.hasMatch(parts[1])) return false;
      final bits = int.parse(parts[1]);
      if (bits < 0 || bits > _maxPrefixBits) return false;
    }

    parts = javaSplit(parts[0], '%', limit: -1);
    if (parts.length > 2 ||
        (parts.length == 2 && !_idCheckPattern.hasMatch(parts[1]))) {
      return false; // invalid zone id
    }
    address = parts[0];

    final containsCompressedZeroes = address.contains('::');
    if (containsCompressedZeroes &&
        address.indexOf('::') != address.lastIndexOf('::')) {
      return false;
    }
    final startsWithCompressed = address.startsWith('::');
    final endsWithCompressed = address.endsWith('::');
    final endsWithSep = address.endsWith(':');
    if ((address.startsWith(':') && !startsWithCompressed) ||
        (endsWithSep && !endsWithCompressed)) {
      return false;
    }

    // No limit here, so Java drops trailing empty strings: "1::" splits to
    // ["1"], not ["1", "", ""]. Dart's own split would keep them and break the
    // group count, which is why javaSplit exists.
    var octets = javaSplit(address, ':');
    if (containsCompressedZeroes) {
      final octetList = List<String>.of(octets);
      if (endsWithCompressed) {
        octetList.add('');
      } else if (startsWithCompressed && octetList.isNotEmpty) {
        octetList.removeAt(0);
      }
      octets = octetList;
    }
    if (octets.length > _ipv6MaxHexGroups) return false;

    var validOctets = 0;
    var emptyOctets = 0; // consecutive empty chunks
    for (var index = 0; index < octets.length; index++) {
      final octet = octets[index];
      if (GenericValidator.isBlankOrNull(octet)) {
        emptyOctets++;
        if (emptyOctets > 1) return false;
      } else {
        emptyOctets = 0;
        // A trailing IPv4 part, as in ::ffff:192.0.2.1, counts as two groups.
        if (index == octets.length - 1 && octet.contains('.')) {
          if (!isValidInet4Address(octet)) return false;
          validOctets += 2;
          continue;
        }
        if (octet.length > _ipv6MaxHexDigitsPerGroup) return false;
        for (var n = 0; n < octet.length; n++) {
          if (!_isHexDigit(octet.codeUnitAt(n))) return false;
        }
        final octetInt = int.tryParse(octet, radix: 16);
        if (octetInt == null || octetInt < 0 || octetInt > _maxUnsignedShort) {
          return false;
        }
      }
      validOctets++;
    }
    if (validOctets > _ipv6MaxHexGroups ||
        (validOctets < _ipv6MaxHexGroups && !containsCompressedZeroes)) {
      return false;
    }
    return true;
  }

  static bool _isHexDigit(int c) =>
      isAsciiDigit(c) ||
      (c >= 0x41 && c <= 0x46) || // A-F
      (c >= 0x61 && c <= 0x66); // a-f
}
