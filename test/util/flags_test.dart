import 'package:commons_validator/src/util/flags.dart';
import 'package:test/test.dart';

/// Ported from `org.apache.commons.validator.util.FlagsTest`.
///
/// Upstream's `testClone`, `testEqualsObject`, `testTurnOff` and `testTurnOnOff`
/// are empty stubs; they are given real bodies here.
void main() {
  const longFlag = 1;
  const longFlag2 = 2;
  const intFlag = 4;

  test('clear', () {
    final f = Flags(98432)..clear();
    expect(f.flags, 0);
  });

  test('copy replaces clone', () {
    final f = Flags(98432);
    final c = f.copy();
    expect(c, f);
    c.turnOn(1);
    expect(c, isNot(f), reason: 'copy must not alias the original');
  });

  test('equality and hashCode', () {
    expect(Flags(45), Flags(45));
    expect(Flags(45), isNot(Flags(46)));
    expect(Flags(45).hashCode, 45, reason: "Java's (int) flags truncation");
  });

  test('flags getter', () => expect(Flags(45).flags, 45));

  test('isOn is false when not all bits of the argument are on', () {
    expect(Flags(1).isOn(3), isFalse);
  });

  test('isOn is true when the high order bit is set and queried', () {
    // 0x8000000000000000 as a Dart int is the minimum signed 64-bit value.
    // Parsed rather than written as a literal, which would not compile for web.
    expect(Flags(~0).isOn(int.parse('-9223372036854775808')), isTrue);
  }, testOn: 'vm');

  test('turnOn / isOn / isOff', () {
    final f = Flags()
      ..turnOn(longFlag)
      ..turnOn(intFlag);
    expect(f.isOn(longFlag), isTrue);
    expect(f.isOff(longFlag), isFalse);
    expect(f.isOn(intFlag), isTrue);
    expect(f.isOff(intFlag), isFalse);
    expect(f.isOff(longFlag2), isTrue);
  });

  test('turnOff clears only the given bits', () {
    final f = Flags(longFlag | longFlag2 | intFlag)..turnOff(longFlag2);
    expect(f.isOn(longFlag), isTrue);
    expect(f.isOff(longFlag2), isTrue);
    expect(f.isOn(intFlag), isTrue);
  });

  test('toString is always 64 binary digits', () {
    final f = Flags();
    expect(f.toString().length, 64);
    f.turnOn(intFlag);
    expect(f.toString().length, 64);
    expect(
      f.toString(),
      '0000000000000000000000000000000000000000000000000000000000000100',
    );
  });

  test('turnOffAll', () {
    final f = Flags(98432)..turnOffAll();
    expect(f.flags, 0);
  });

  test('turnOnAll', () {
    final f = Flags()..turnOnAll();
    expect(f.flags, ~0);
  });
}
