/// A mutable 64-bit flag set, ported from
/// `org.apache.commons.validator.util.Flags`.
///
/// Nothing in the ported `routines` package uses this class — `UrlValidator`
/// carries its own `int options` field with subtly different semantics
/// ((`options & flag) > 0` rather than `(flags & flag) == flag`, which differ
/// for multi-bit masks). It is provided for parity with upstream.
///
/// On the Dart VM `int` is 64-bit, so this behaves exactly as the Java `long`
/// does. **On the web `int` is a JavaScript double**, so [turnOnAll] and
/// [toString] are not accurate above bit 52.
class Flags {
  /// Creates a flag set with the given initial bits, defaulting to none set.
  Flags([this._flags = 0]);

  int _flags;

  /// The current bit field.
  int get flags => _flags;

  /// Clears all bits. Equivalent to [turnOffAll].
  void clear() => _flags = 0;

  /// Whether every bit of [flag] is set.
  bool isOn(int flag) => (_flags & flag) == flag;

  /// Whether no bit of [flag] is set.
  bool isOff(int flag) => (_flags & flag) == 0;

  /// Sets every bit of [flag].
  void turnOn(int flag) => _flags |= flag;

  /// Clears every bit of [flag].
  void turnOff(int flag) => _flags &= ~flag;

  /// Sets all 64 bits.
  void turnOnAll() => _flags = -1;

  /// Clears all bits.
  void turnOffAll() => _flags = 0;

  /// A copy of this flag set, replacing Java's `Cloneable` implementation.
  Flags copy() => Flags(_flags);

  @override
  bool operator ==(Object other) => other is Flags && other._flags == _flags;

  /// Mirrors Java's `(int) flags` truncation so a flag set of 45 hashes to 45.
  @override
  int get hashCode => _flags.toSigned(32);

  /// The bit field as 64 binary digits, most significant first.
  @override
  String toString() => _flags.toUnsigned(64).toRadixString(2).padLeft(64, '0');
}
