import '../internal/decimal_parser.dart';
import '../internal/number_spec.dart';
import 'abstract_number_validator.dart';

/// Shared implementation for the fixed-width integer validators.
///
/// Byte, Short, Integer and Long differ only in their bounds. Java models them
/// as four classes that each reject by checking `value instanceof Long` and then
/// a range; the check is factored out here.
///
/// Note the `instanceof Long` test is load-bearing upstream, not incidental: an
/// input too large for a `long` arrives as a `Double` and is rejected on *type*.
/// [fitsInJavaLong] reproduces that.
abstract class _IntegralValidator extends AbstractNumberValidator<int> {
  const _IntegralValidator({required super.strict})
      : super(formatType: NumberFormatType.standard, allowFractions: false);

  /// The lowest value this validator accepts.
  ///
  /// A [BigInt] rather than an `int` because `Long.MIN_VALUE` cannot be written
  /// as an `int` literal at all when compiling to JavaScript - it is a compile
  /// error, not merely imprecise.
  BigInt get minimum;

  /// The highest value this validator accepts.
  BigInt get maximum;

  @override
  int? processParsedValue(NumberParseResult result, NumberSpec spec) {
    // An exponent beyond maxDecimalScale cannot fit any integer type.
    if (result.magnitude != NumberMagnitude.normal) return null;
    if (!fitsInJavaLong(result.value)) return null;
    final value = result.value.toBigInt();
    if (value < minimum || value > maximum) return null;
    return value.toInt();
  }

  /// Whether [value] is between [min] and [max] inclusive.
  bool isInRange(int value, int min, int max) =>
      minValue(value, min) && maxValue(value, max);

  /// Whether [value] is at least [min].
  bool minValue(int value, int min) => value >= min;

  /// Whether [value] is at most [max].
  bool maxValue(int value, int max) => value <= max;
}

/// Validates that a string is a valid Java `byte`, i.e. -128 to 127.
///
/// Ported from `org.apache.commons.validator.routines.ByteValidator`.
class ByteValidator extends _IntegralValidator {
  /// Creates a validator. [strict] requires the whole input to be consumed.
  const ByteValidator({super.strict = true});

  /// `Byte.MIN_VALUE`.
  static const int minByte = -128;

  /// `Byte.MAX_VALUE`.
  static const int maxByte = 127;

  @override
  BigInt get minimum => _min;

  @override
  BigInt get maximum => _max;

  static final BigInt _min = BigInt.from(minByte);
  static final BigInt _max = BigInt.from(maxByte);

  static const ByteValidator _instance = ByteValidator();

  /// The shared strict instance.
  static ByteValidator getInstance() => _instance;
}

/// Validates that a string is a valid Java `short`, i.e. -32768 to 32767.
///
/// Ported from `org.apache.commons.validator.routines.ShortValidator`.
class ShortValidator extends _IntegralValidator {
  /// Creates a validator. [strict] requires the whole input to be consumed.
  const ShortValidator({super.strict = true});

  /// `Short.MIN_VALUE`.
  static const int minShort = -32768;

  /// `Short.MAX_VALUE`.
  static const int maxShort = 32767;

  @override
  BigInt get minimum => _min;

  @override
  BigInt get maximum => _max;

  static final BigInt _min = BigInt.from(minShort);
  static final BigInt _max = BigInt.from(maxShort);

  static const ShortValidator _instance = ShortValidator();

  /// The shared strict instance.
  static ShortValidator getInstance() => _instance;
}

/// Validates that a string is a valid Java `int`.
///
/// Ported from `org.apache.commons.validator.routines.IntegerValidator`.
class IntegerValidator extends _IntegralValidator {
  /// Creates a validator. [strict] requires the whole input to be consumed.
  const IntegerValidator({super.strict = true});

  /// `Integer.MIN_VALUE`.
  static const int minInt = -2147483648;

  /// `Integer.MAX_VALUE`.
  static const int maxInt = 2147483647;

  @override
  BigInt get minimum => _min;

  @override
  BigInt get maximum => _max;

  static final BigInt _min = BigInt.from(minInt);
  static final BigInt _max = BigInt.from(maxInt);

  static const IntegerValidator _instance = IntegerValidator();

  /// The shared strict instance.
  static IntegerValidator getInstance() => _instance;
}

/// Validates that a string is a valid Java `long`.
///
/// Ported from `org.apache.commons.validator.routines.LongValidator`.
///
/// Upstream accepts any value that `NumberFormat` returned as a `Long` without a
/// further bounds check, so `9223372036854775808` is rejected only because it
/// came back as a `Double`. The effect is the same 64-bit range, which is what
/// this class checks explicitly.
class LongValidator extends _IntegralValidator {
  /// Creates a validator. [strict] requires the whole input to be consumed.
  const LongValidator({super.strict = true});

  /// `Long.MIN_VALUE`.
  ///
  /// Written as a parsed string, not a literal: `-9223372036854775808` as an
  /// `int` literal fails to *compile* for the web, which would make the whole
  /// package unusable in a Flutter web app.
  static final BigInt minLong = BigInt.parse('-9223372036854775808');

  /// `Long.MAX_VALUE`, for the same reason a parsed string.
  static final BigInt maxLong = BigInt.parse('9223372036854775807');

  @override
  BigInt get minimum => minLong;

  @override
  BigInt get maximum => maxLong;

  static const LongValidator _instance = LongValidator();

  /// The shared strict instance.
  static LongValidator getInstance() => _instance;
}
