import 'package:commons_validator/src/generic_validator.dart';
import 'package:commons_validator/src/internal/ascii.dart';
import 'package:commons_validator/src/internal/java_compat.dart';
import 'package:test/test.dart';

/// These tests exist to pin the differences between Java and Dart string
/// semantics. They are not ported from upstream — upstream has no reason to test
/// the JDK — but every one of them guards a place where the obvious Dart
/// built-in gives a different answer than the Java the port is derived from.
void main() {
  final nbsp = String.fromCharCode(0xA0);
  final nnbsp = String.fromCharCode(0x202F);

  group('javaTrim', () {
    test('strips only code units <= U+0020', () {
      expect(javaTrim('  x  '), 'x');
      expect(javaTrim('\t\nx\r'), 'x');
      expect(javaTrim(''), '');
      expect(javaTrim('   '), '');
      expect(javaTrim('x'), 'x');
    });

    test('preserves NBSP and NNBSP, unlike Dart String.trim', () {
      expect(javaTrim('$nbsp x $nbsp'), '$nbsp x $nbsp');
      expect(javaTrim('${nnbsp}1'), '${nnbsp}1');
      // The divergence being guarded against:
      expect('$nbsp x $nbsp'.trim(), 'x');
    });
  });

  group('javaSplit', () {
    test('drops trailing empties with no limit, like Java', () {
      expect(javaSplit('1::', ':'), ['1']);
      expect(javaSplit('a/b/', '/'), ['a', 'b']);
      expect(javaSplit('::', ':'), <String>[]);
      expect(javaSplit('a::b', ':'), ['a', '', 'b']);
    });

    test('keeps trailing empties with limit -1, like split(re, -1)', () {
      expect(javaSplit('1::', ':', limit: -1), ['1', '', '']);
      expect(javaSplit('a/b/', '/', limit: -1), ['a', 'b', '']);
    });

    test('leading empties are always kept', () {
      expect(javaSplit('::1', ':'), ['', '', '1']);
    });
  });

  group('isSpaceChar', () {
    test('true for Zs/Zl/Zp', () {
      for (final c in [
        0x20,
        0xA0,
        0x1680,
        0x2000,
        0x200A,
        0x2028,
        0x2029,
        0x202F,
        0x205F,
        0x3000
      ]) {
        expect(isSpaceChar(c), isTrue, reason: 'U+${c.toRadixString(16)}');
      }
    });

    test('false for tab, newline and ZWSP', () {
      // Java's isSpaceChar excludes these even though they are "whitespace".
      for (final c in [0x09, 0x0A, 0x0D, 0x200B]) {
        expect(isSpaceChar(c), isFalse, reason: 'U+${c.toRadixString(16)}');
      }
    });
  });

  group('isFormatChar / isNameprepMappedToNothing', () {
    test('Cf category is detected', () {
      expect(isFormatChar(0xAD), isTrue, reason: 'SOFT HYPHEN');
      expect(isFormatChar(0x200D), isTrue, reason: 'ZWJ');
      expect(isFormatChar(0xFEFF), isTrue, reason: 'BOM');
      expect(isFormatChar(0x41), isFalse, reason: 'A');
    });

    test('the non-Cf nameprep set needs the separate check', () {
      // These are exactly why DomainValidator carries a second predicate.
      for (final c in [0x034F, 0x1806, 0x180B, 0x180D, 0xFE00, 0xFE0F]) {
        expect(isFormatChar(c), isFalse,
            reason: 'U+${c.toRadixString(16)} is not Cf');
        expect(isNameprepMappedToNothing(c), isTrue);
      }
      expect(isNameprepMappedToNothing(0x41), isFalse);
    });
  });

  group('ascii helpers', () {
    test('reject non-ASCII digits that Java Character.isDigit accepts', () {
      expect(isAsciiDigit(0x665), isFalse, reason: 'ARABIC-INDIC FIVE');
      expect(isAsciiDigit(0xFF15), isFalse, reason: 'FULLWIDTH FIVE');
      expect(asciiNumericValue(0x665), -1);
      expect(asciiNumericValue(0x2161), -1, reason: 'ROMAN NUMERAL TWO');
    });

    test('asciiNumericValue maps digits and letters', () {
      expect(asciiNumericValue(0x30), 0);
      expect(asciiNumericValue(0x39), 9);
      expect(asciiNumericValue(0x41), 10);
      expect(asciiNumericValue(0x5A), maxAlphanumericValue);
      expect(asciiNumericValue(0x61), 10, reason: 'case-insensitive');
      expect(asciiNumericValue(0x7A), 35);
      expect(asciiNumericValue(0x2D), -1, reason: 'hyphen');
    });

    test('isAsciiUpper rejects accented capitals Java accepts', () {
      expect(isAsciiUpper(0x41), isTrue);
      expect(isAsciiUpper(0xC0), isFalse, reason: 'LATIN CAPITAL A WITH GRAVE');
    });

    test('asciiToLowerCase leaves non-ASCII alone', () {
      expect(asciiToLowerCase('ABC'), 'abc');
      expect(asciiToLowerCase('AÀI'), 'aÀi');
      // Turkish dotless-i class of bug avoided: no locale involvement at all.
      expect(asciiToLowerCase('I'), 'i');
      expect(asciiToUpperCase('aài'), 'AàI');
    });

    test('isOnlyAscii', () {
      expect(isOnlyAscii('example.com'), isTrue);
      expect(isOnlyAscii('exámple.com'), isFalse);
      expect(isOnlyAscii(''), isTrue);
    });
  });

  group('GenericValidator.isBlankOrNull', () {
    test('null, empty and ASCII whitespace are blank', () {
      expect(GenericValidator.isBlankOrNull(null), isTrue);
      expect(GenericValidator.isBlankOrNull(''), isTrue);
      expect(GenericValidator.isBlankOrNull('   '), isTrue);
      expect(GenericValidator.isBlankOrNull('\t\n'), isTrue);
      expect(GenericValidator.isBlankOrNull('x'), isFalse);
    });

    test('an NBSP-only string is NOT blank, matching Java', () {
      expect(GenericValidator.isBlankOrNull(nbsp), isFalse);
      expect(GenericValidator.isBlankOrNull(nnbsp), isFalse);
    });
  });

  group('GenericValidator.matchRegexp', () {
    test('requires a full match', () {
      expect(GenericValidator.matchRegexp('abc', 'abc'), isTrue);
      expect(GenericValidator.matchRegexp('abcd', 'abc'), isFalse);
      expect(GenericValidator.matchRegexp('xabc', 'abc'), isFalse);
    });

    test('empty or null pattern is always false', () {
      expect(GenericValidator.matchRegexp('abc', ''), isFalse);
      expect(GenericValidator.matchRegexp('abc', null), isFalse);
    });
  });
}
