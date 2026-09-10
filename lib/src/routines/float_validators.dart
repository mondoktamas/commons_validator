import 'dart:typed_data';

import '../internal/decimal_parser.dart';
import '../internal/number_spec.dart';
import 'abstract_number_validator.dart';

/// Validates that a string is a valid Java `float`.
///
/// Ported from `org.apache.commons.validator.routines.FloatValidator`.
///
/// Dart has no 32-bit floating-point type, so without the explicit bounds below
/// this class and [DoubleValidator] would be identical. Upstream rejects any
/// magnitude below [minFloat] - the smallest positive *subnormal* float, so
/// `1e-46` is rejected rather than flushed to zero - or above [maxFloat], while
/// mapping an infinite double to an infinite float.
class FloatValidator extends AbstractNumberValidator<double> {
  /// Creates a validator. [strict] requires the whole input to be consumed.
  const FloatValidator({super.strict = true})
      : super(
          formatType: NumberFormatType.standard,
          allowFractions: true,
        );

  /// `Float.MIN_VALUE`, the smallest positive subnormal float, widened to a
  /// double.
  ///
  /// This must be the *exact* widened value, not the `1.4E-45` that Java prints:
  /// upstream compares the parsed double against it, so an input of `1.4E-45`
  /// parses to a double slightly below the real minimum and is rejected. Using
  /// the printed form here would accept it.
  static const double minFloat = 1.401298464324817e-45;

  /// `Float.MAX_VALUE`, widened to a double.
  ///
  /// Likewise exact rather than the printed `3.4028235E38`, which as a double is
  /// slightly *larger* than the real maximum - so Java rejects that input too.
  static const double maxFloat = 3.4028234663852886e38;

  static const FloatValidator _instance = FloatValidator();

  /// The shared strict instance.
  static FloatValidator getInstance() => _instance;

  /// Scratch buffer used to round a double to 32-bit precision.
  static final Float32List _float32 = Float32List(1);

  /// Rounds [value] to 32-bit floating point, standing in for Java's
  /// `(float) doubleValue` cast.
  ///
  /// Dart has no `float` type, but a one-element [Float32List] performs exactly
  /// the same narrowing - without it, `FloatValidator` would return more
  /// precision than Java does, so `2147483647` would come back unchanged rather
  /// than as 2147483648.
  static double toFloat(double value) {
    _float32[0] = value;
    return _float32[0];
  }

  @override
  double? processParsedValue(NumberParseResult result, NumberSpec spec) {
    final value = result.value.toDouble();
    if (value > 0) {
      if (value == double.infinity) return double.infinity;
      if (value < minFloat || value > maxFloat) return null;
    } else if (value < 0) {
      if (value == double.negativeInfinity) return double.negativeInfinity;
      final magnitude = -value;
      if (magnitude < minFloat || magnitude > maxFloat) return null;
    }
    return toFloat(value);
  }

  /// Whether [value] is between [min] and [max] inclusive.
  bool isInRange(double value, double min, double max) =>
      minValue(value, min) && maxValue(value, max);

  /// Whether [value] is at least [min].
  bool minValue(double value, double min) => value >= min;

  /// Whether [value] is at most [max].
  bool maxValue(double value, double max) => value <= max;
}

/// Validates that a string is a valid Java `double`.
///
/// Ported from `org.apache.commons.validator.routines.DoubleValidator`.
///
/// Unlike [FloatValidator] this applies **no** range check at all, so an
/// overflowing literal is accepted as infinity. The asymmetry is upstream's and
/// is preserved deliberately.
class DoubleValidator extends AbstractNumberValidator<double> {
  /// Creates a validator. [strict] requires the whole input to be consumed.
  const DoubleValidator({super.strict = true})
      : super(
          formatType: NumberFormatType.standard,
          allowFractions: true,
        );

  static const DoubleValidator _instance = DoubleValidator();

  /// The shared strict instance.
  static DoubleValidator getInstance() => _instance;

  @override
  double? processParsedValue(NumberParseResult result, NumberSpec spec) =>
      result.value.toDouble();

  /// Whether [value] is between [min] and [max] inclusive.
  bool isInRange(double value, double min, double max) =>
      minValue(value, min) && maxValue(value, max);

  /// Whether [value] is at least [min].
  bool minValue(double value, double min) => value >= min;

  /// Whether [value] is at most [max].
  bool maxValue(double value, double max) => value <= max;
}
