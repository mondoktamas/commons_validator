/// RFC 3492 Punycode, the bootstring encoding used by IDNA.
///
/// Implemented here rather than taken from pub: the `punycode` package is at
/// 1.0.0, long unmaintained, and does no nameprep, which IDNA also needs.
library;

const int _base = 36;
const int _tMin = 1;
const int _tMax = 26;
const int _skew = 38;
const int _damp = 700;
const int _initialBias = 72;
const int _initialN = 0x80;
const int _delimiter = 0x2D; // '-'

/// The maximum code point, so overflow can be detected the way RFC 3492 does.
const int _maxInt = 0x7FFFFFFF;

/// Thrown when a string cannot be punycode-encoded or decoded.
class PunycodeException implements Exception {
  /// Creates an exception with [message].
  const PunycodeException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'PunycodeException: $message';
}

int _adapt(int delta, int numPoints, bool firstTime) {
  var d = firstTime ? delta ~/ _damp : delta ~/ 2;
  d += d ~/ numPoints;
  var k = 0;
  while (d > ((_base - _tMin) * _tMax) ~/ 2) {
    d ~/= _base - _tMin;
    k += _base;
  }
  return k + ((_base - _tMin + 1) * d) ~/ (d + _skew);
}

/// The basic code point for digit [d], lower-case.
int _encodeDigit(int d) => d + 22 + (d < 26 ? 75 : 0);

/// The digit value of basic code point [cp], or -1 if it is not a digit.
///
/// RFC 3492's reference decoder writes these as `cp - 48 < 10`, which is only
/// correct because its arithmetic is *unsigned*: for `cp` below `'0'` the
/// subtraction wraps to a huge value and the test fails. Dart's ints are signed,
/// so the same expression is true for everything below `'9'` - it would accept
/// space, `!`, `+`, `,`, `-`, `.` and `/` as digits and decode silent garbage
/// instead of throwing. Hence the explicit ranges.
int _decodeDigit(int cp) {
  if (cp >= 0x30 && cp <= 0x39) return cp - 0x16; // '0'-'9' -> 26-35
  if (cp >= 0x41 && cp <= 0x5A) return cp - 0x41; // 'A'-'Z' -> 0-25
  if (cp >= 0x61 && cp <= 0x7A) return cp - 0x61; // 'a'-'z' -> 0-25
  return -1;
}

/// Encodes a single label's Unicode [input] as punycode, without the `xn--`
/// prefix.
String punycodeEncode(String input) {
  final codePoints = input.runes.toList();
  final output = <int>[];

  // Copy the basic (ASCII) code points through unchanged.
  for (final cp in codePoints) {
    if (cp < _initialN) output.add(cp);
  }
  final basicLength = output.length;
  var handled = basicLength;
  if (basicLength > 0) output.add(_delimiter);

  var n = _initialN;
  var delta = 0;
  var bias = _initialBias;

  while (handled < codePoints.length) {
    // Find the next code point to encode.
    var m = _maxInt;
    for (final cp in codePoints) {
      if (cp >= n && cp < m) m = cp;
    }
    if (m - n > (_maxInt - delta) ~/ (handled + 1)) {
      throw const PunycodeException('overflow');
    }
    delta += (m - n) * (handled + 1);
    n = m;

    for (final cp in codePoints) {
      if (cp < n) {
        if (++delta > _maxInt) throw const PunycodeException('overflow');
      } else if (cp == n) {
        var q = delta;
        for (var k = _base;; k += _base) {
          final t = k <= bias ? _tMin : (k >= bias + _tMax ? _tMax : k - bias);
          if (q < t) break;
          output.add(_encodeDigit(t + (q - t) % (_base - t)));
          q = (q - t) ~/ (_base - t);
        }
        output.add(_encodeDigit(q));
        bias = _adapt(delta, handled + 1, handled == basicLength);
        delta = 0;
        handled++;
      }
    }
    delta++;
    n++;
  }
  return String.fromCharCodes(output);
}

/// Decodes a punycode label [input] (without the `xn--` prefix) back to Unicode.
String punycodeDecode(String input) {
  final output = <int>[];
  final units = input.codeUnits;

  // Everything before the last delimiter is literal ASCII.
  final lastDelimiter = units.lastIndexOf(_delimiter);
  if (lastDelimiter > 0) {
    for (var i = 0; i < lastDelimiter; i++) {
      final cp = units[i];
      if (cp >= _initialN) throw const PunycodeException('not basic');
      output.add(cp);
    }
  }

  var n = _initialN;
  var i = 0;
  var bias = _initialBias;
  var index = lastDelimiter > 0 ? lastDelimiter + 1 : 0;

  while (index < units.length) {
    final oldI = i;
    var w = 1;
    for (var k = _base;; k += _base) {
      if (index >= units.length) throw const PunycodeException('bad input');
      final digit = _decodeDigit(units[index++]);
      if (digit < 0) throw const PunycodeException('bad input');
      if (digit > (_maxInt - i) ~/ w) throw const PunycodeException('overflow');
      i += digit * w;
      final t = k <= bias ? _tMin : (k >= bias + _tMax ? _tMax : k - bias);
      if (digit < t) break;
      if (w > _maxInt ~/ (_base - t)) throw const PunycodeException('overflow');
      w *= _base - t;
    }
    final outLength = output.length + 1;
    bias = _adapt(i - oldI, outLength, oldI == 0);
    if (i ~/ outLength > _maxInt - n) throw const PunycodeException('overflow');
    n += i ~/ outLength;
    i %= outLength;
    output.insert(i, n);
    i++;
  }
  return String.fromCharCodes(output);
}
