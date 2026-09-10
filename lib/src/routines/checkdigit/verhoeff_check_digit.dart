import '../../generic_validator.dart';
import '../../internal/ascii.dart';
import 'check_digit.dart';
import 'check_digit_exception.dart';

/// Verhoeff (dihedral group D5) check digit.
///
/// Ported from `VerhoeffCheckDigit`.
final class VerhoeffCheckDigit implements CheckDigit {
  /// Creates the routine.
  const VerhoeffCheckDigit();

  /// The singleton instance.
  static const VerhoeffCheckDigit verhoeffCheckDigit = VerhoeffCheckDigit();

  static const List<List<int>> _dTable = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];

  static const List<List<int>> _pTable = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  static const List<int> _invTable = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9];

  @override
  String calculate(String? code) {
    if (GenericValidator.isBlankOrNull(code)) {
      throw const CheckDigitException.missingCode();
    }
    return _invTable[_calculateChecksum(code!, false)].toString();
  }

  @override
  bool isValid(String? code) {
    if (GenericValidator.isBlankOrNull(code)) return false;
    try {
      return _calculateChecksum(code!, true) == 0;
    } on CheckDigitException {
      return false;
    }
  }

  /// Walks the code right to left, per the Verhoeff definition.
  int _calculateChecksum(String code, bool includesCheckDigit) {
    var checksum = 0;
    for (var i = 0; i < code.length; i++) {
      final c = code.codeUnitAt(code.length - (i + 1));
      if (!isAsciiDigit(c)) {
        throw CheckDigitException("Invalid Character[$i] = '$c'");
      }
      final pos = includesCheckDigit ? i : i + 1;
      checksum = _dTable[checksum][_pTable[pos % 8][c - 0x30]];
    }
    return checksum;
  }
}
