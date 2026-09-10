/// A minimal RFC 2396 URI splitter, standing in for `java.net.URI`.
///
/// `UrlValidator` uses `new URI(value)` purely as a syntax gate and then reads
/// the *raw* (still percent-encoded) components. Dart's [Uri] cannot serve:
/// it implements RFC 3986, which accepts and rejects a different set of strings,
/// and it exposes no raw authority. So the split is done here, and its agreement
/// with the JDK is measured in `tool/jvm_diff`.
library;

import 'ascii.dart';
import 'java_compat.dart';

/// The raw components of a parsed URI, as `java.net.URI` reports them.
class UriParts {
  /// Creates a component set.
  const UriParts({
    this.scheme,
    this.rawAuthority,
    this.rawPath,
    this.rawQuery,
    this.rawFragment,
  });

  /// The scheme, or null if the reference is relative.
  final String? scheme;

  /// The authority as written, or null when there is none.
  ///
  /// An explicitly empty authority, as in `file:///tmp`, is reported as null,
  /// matching `URI.getRawAuthority`.
  final String? rawAuthority;

  /// The path as written, or null for an opaque URI such as `mailto:a@b`.
  final String? rawPath;

  /// The query as written, without the `?`, or null when absent.
  final String? rawQuery;

  /// The fragment as written, without the `#`, or null when absent.
  final String? rawFragment;
}

/// Parses [value] into its raw components, or returns null where
/// `new URI(value)` would throw `URISyntaxException`.
UriParts? parseUri(String value) {
  if (!_isLegalUriString(value)) return null;

  var rest = value;

  // Only one '#' is allowed: Java rejects a fragment containing another.
  String? fragment;
  final hash = rest.indexOf('#');
  if (hash >= 0) {
    fragment = rest.substring(hash + 1);
    if (fragment.contains('#')) return null;
    rest = rest.substring(0, hash);
  }

  // A scheme is a ':' before any '/', '?' or '#', preceded by a valid name.
  String? scheme;
  final colon = _schemeColon(rest);
  if (colon > 0) {
    scheme = rest.substring(0, colon);
    rest = rest.substring(colon + 1);
  }

  String? authority;
  String? path;
  String? query;

  if (rest.startsWith('//')) {
    final afterSlashes = rest.substring(2);
    var end = afterSlashes.length;
    for (var i = 0; i < afterSlashes.length; i++) {
      final c = afterSlashes[i];
      if (c == '/' || c == '?') {
        end = i;
        break;
      }
    }
    final rawAuthority = afterSlashes.substring(0, end);
    // `http://` with nothing at all after it is rejected, while `http:///`
    // (empty authority, then a path), `http://?q` and `http://#f` are accepted -
    // so a fragment or query is enough to make the form legal.
    if (rawAuthority.isEmpty && afterSlashes.isEmpty && fragment == null) {
      return null;
    }
    if (!_isLegalAuthority(rawAuthority)) return null;
    // An empty authority is reported as null, as in file:///tmp/x.
    authority = rawAuthority.isEmpty ? null : rawAuthority;
    rest = afterSlashes.substring(end);
    final q = rest.indexOf('?');
    if (q >= 0) {
      path = rest.substring(0, q);
      query = rest.substring(q + 1);
    } else {
      path = rest;
    }
  } else if (scheme != null && !rest.startsWith('/')) {
    // Opaque: mailto:a@b.com has neither authority nor path.
    if (rest.isEmpty) return null; // a scheme with no scheme-specific part
    path = null;
  } else {
    final q = rest.indexOf('?');
    if (q >= 0) {
      path = rest.substring(0, q);
      query = rest.substring(q + 1);
    } else {
      path = rest;
    }
    // RFC 2396: the first segment of a relative reference may not contain a
    // colon, which is what makes `3http://x/` and `htt!p://x/` invalid rather
    // than relative paths.
    if (scheme == null) {
      final firstSlash = path.indexOf('/');
      final firstSegment =
          firstSlash < 0 ? path : path.substring(0, firstSlash);
      if (firstSegment.contains(':')) return null;
    }
  }

  // Brackets are legal in an authority (as an IPv6 literal), and Java also
  // tolerates them in a query or fragment - but not in a path.
  if (_containsBracket(path)) return null;

  return UriParts(
    scheme: scheme,
    rawAuthority: authority,
    rawPath: path,
    rawQuery: query,
    rawFragment: fragment,
  );
}

/// The index of the scheme's ':', or -1 if [s] has no scheme.
int _schemeColon(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c == 0x3A) {
      // ':' - a scheme must be at least one character and start with a letter.
      if (i == 0) return -1;
      if (!isAsciiAlpha(s.codeUnitAt(0))) return -1;
      for (var j = 1; j < i; j++) {
        if (!_isSchemeChar(s.codeUnitAt(j))) return -1;
      }
      return i;
    }
    if (c == 0x2F || c == 0x3F || c == 0x23) return -1; // '/', '?', '#'
  }
  return -1;
}

bool _isSchemeChar(int c) =>
    isAsciiAlphaNum(c) ||
    c == 0x2B || // '+'
    c == 0x2D || // '-'
    c == 0x2E; // '.'

/// Whether every character of [value] is legal in a URI, and every `%` escape is
/// well formed.
///
/// Java's `URI` accepts unreserved and reserved characters, `[` and `]` for IPv6
/// literals, correct `%XX` escapes, and any non-ASCII character (its "other"
/// category). It rejects controls, space, and `"`, `<`, `>`, backslash, `^`,
/// backtick, `{`, `|` and `}`.
bool _isLegalUriString(String value) {
  for (var i = 0; i < value.length; i++) {
    final c = value.codeUnitAt(i);
    if (c == 0x25) {
      // '%' must be followed by two hex digits.
      if (i + 2 >= value.length) return false;
      if (!_isHex(value.codeUnitAt(i + 1)) ||
          !_isHex(value.codeUnitAt(i + 2))) {
        return false;
      }
      i += 2;
      continue;
    }
    if (!_isLegalUriChar(c)) return false;
  }
  return true;
}

bool _isHex(int c) =>
    isAsciiDigit(c) || (c >= 0x41 && c <= 0x46) || (c >= 0x61 && c <= 0x66);

bool _isLegalUriChar(int c) {
  // Java's "other" category is `c > 127 && !isSpaceChar(c) && !isISOControl(c)`,
  // so NBSP and the other Unicode spaces are rejected just like a plain space.
  if (c > 0x7F) return !isSpaceChar(c) && !_isIsoControl(c);
  if (c <= 0x20 || c == 0x7F) return false; // controls and space
  switch (c) {
    case 0x22: // "
    case 0x3C: // <
    case 0x3E: // >
    case 0x5C: // backslash
    case 0x5E: // ^
    case 0x60: // backtick
    case 0x7B: // {
    case 0x7C: // |
    case 0x7D: // }
      return false;
    default:
      return true;
  }
}

bool _containsBracket(String? s) =>
    s != null && (s.contains('[') || s.contains(']'));

/// Whether [authority] is legal.
///
/// Brackets are permitted only as a leading IPv6 literal, optionally followed by
/// `:port`; Java rejects them anywhere else. The literal's *contents* are not
/// checked here, because `UrlValidator` re-validates the host with
/// `InetAddressValidator` regardless.
bool _isLegalAuthority(String authority) {
  final open = authority.indexOf('[');
  final close = authority.indexOf(']');
  if (open < 0 && close < 0) return true;
  if (open < 0 || close < 0) return false;
  // The literal must start the host portion, i.e. follow any userinfo directly.
  final at = authority.lastIndexOf('@');
  if (open != at + 1) return false;
  if (close < open) return false;
  // Nothing but a port may follow the closing bracket.
  final after = authority.substring(close + 1);
  if (after.isNotEmpty && !after.startsWith(':')) return false;
  // No further brackets.
  if (authority.indexOf('[', open + 1) >= 0) return false;
  if (authority.indexOf(']', close + 1) >= 0) return false;
  return true;
}

/// Java's `Character.isISOControl`: the C0 and C1 control ranges.
bool _isIsoControl(int c) => c <= 0x1F || (c >= 0x7F && c <= 0x9F);
