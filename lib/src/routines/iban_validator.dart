import '../internal/ascii.dart';
import 'checkdigit/iban_check_digit.dart';
import 'iban_validator_status.dart';
import 'iban_validators.dart';
import 'regex_validator.dart';

export 'iban_validator_status.dart';

/// The IBAN format definition for one country, and any countries sharing it.
///
/// Ported from `IBANValidator.Validator`.
class IBANCountryValidator {
  /// Creates a definition whose [regexWithCountryCode] *includes* the country
  /// code prefix, which is then stripped to form the shared body.
  IBANCountryValidator(
      String countryCode, int ibanLength, String regexWithCountryCode)
      : this.withoutCountryCodePrefix(
          countryCode,
          ibanLength,
          regexWithCountryCode.substring(countryCode.length),
        );

  /// Creates a definition whose [regexWithoutCountryCode] omits the prefix, so
  /// that [otherCountryCodes] can share the same body.
  IBANCountryValidator.withoutCountryCodePrefix(
    this.countryCode,
    this.ibanLength,
    String regexWithoutCountryCode, {
    List<String> otherCountryCodes = const [],
  })  : otherCountryCodes = List<String>.unmodifiable(otherCountryCodes),
        regexValidator = RegexValidator.fromList([
          countryCode + regexWithoutCountryCode,
          for (final cc in otherCountryCodes) cc + regexWithoutCountryCode,
        ]) {
    if (countryCode.length != 2 ||
        !isAsciiUpper(countryCode.codeUnitAt(0)) ||
        !isAsciiUpper(countryCode.codeUnitAt(1))) {
      throw ArgumentError.value(
        countryCode,
        'countryCode',
        'Invalid country Code; must be exactly 2 upper-case characters',
      );
    }
    if (ibanLength > _maxLen || ibanLength < _minLen) {
      throw ArgumentError.value(
        ibanLength,
        'ibanLength',
        'Invalid length parameter, must be in range '
            '$_minLen to $_maxLen inclusive',
      );
    }
  }

  static const int _minLen = 8;
  static const int _maxLen = 34;

  /// The primary two-letter country code.
  final String countryCode;

  /// Other country codes sharing this definition.
  final List<String> otherCountryCodes;

  /// The total IBAN length for this country.
  final int ibanLength;

  /// The pattern, including one alternative per country code.
  final RegexValidator regexValidator;
}

/// Validates IBANs by country format, length and mod-97 check digits.
///
/// Ported from `org.apache.commons.validator.routines.IBANValidator`.
class IBANValidator {
  /// Creates a validator from [validators], defaulting to the shipped set.
  IBANValidator([List<IBANCountryValidator>? validators])
      : _isDefault = false,
        _validatorMap = _createValidators(validators ?? defaultIBANValidators);

  IBANValidator._default()
      : _isDefault = true,
        _validatorMap = _createValidators(defaultIBANValidators);

  static const int _shortCodeLen = 2;

  /// The shared, immutable instance.
  ///
  /// Attempting to mutate this instance throws [StateError], matching upstream's
  /// `IllegalStateException`. Construct an [IBANValidator] for a mutable one.
  static final IBANValidator defaultIBANValidator = IBANValidator._default();

  /// The shared instance.
  static IBANValidator getInstance() => defaultIBANValidator;

  final bool _isDefault;
  final Map<String, IBANCountryValidator> _validatorMap;

  static Map<String, IBANCountryValidator> _createValidators(
    List<IBANCountryValidator> validators,
  ) {
    final map = <String, IBANCountryValidator>{};
    for (final validator in validators) {
      map[validator.countryCode] = validator;
      for (final otherCc in validator.otherCountryCodes) {
        map[otherCc] = validator;
      }
    }
    return map;
  }

  /// The definitions shipped with the library.
  List<IBANCountryValidator> get defaultValidators =>
      List<IBANCountryValidator>.unmodifiable(defaultIBANValidators);

  /// The definition covering [code]'s country, or null if there is none.
  ///
  /// Note the country code is *not* upper-cased first, so a lower-case IBAN has
  /// no known validator — matching upstream.
  IBANCountryValidator? getValidator(String? code) {
    if (code == null || code.length < _shortCodeLen) return null;
    return _validatorMap[code.substring(0, _shortCodeLen)];
  }

  /// Whether a definition is known for [code]'s country.
  bool hasValidator(String? code) => getValidator(code) != null;

  /// Whether [code] is a valid IBAN.
  bool isValid(String? code) => validate(code) == IBANValidatorStatus.valid;

  /// The detailed validation outcome for [code].
  ///
  /// Checks run in a fixed order: unknown country, then length, then pattern,
  /// then check digits.
  IBANValidatorStatus validate(String? code) {
    final formatValidator = getValidator(code);
    if (formatValidator == null) return IBANValidatorStatus.unknownCountry;
    if (code!.length != formatValidator.ibanLength) {
      return IBANValidatorStatus.invalidLength;
    }
    if (!formatValidator.regexValidator.isValid(code)) {
      return IBANValidatorStatus.invalidPattern;
    }
    return IBANCheckDigit.ibanCheckDigit.isValid(code)
        ? IBANValidatorStatus.valid
        : IBANValidatorStatus.invalidChecksum;
  }

  /// Installs a definition for [countryCode], returning the one replaced.
  ///
  /// A negative [length] removes the definition instead. Throws [StateError] on
  /// [defaultIBANValidator].
  IBANCountryValidator? setValidator(
    String countryCode,
    int length,
    String format,
  ) {
    _checkMutable();
    if (length < 0) {
      final prev = _validatorMap.remove(countryCode);
      if (prev != null) {
        for (final otherCc in prev.otherCountryCodes) {
          _validatorMap.remove(otherCc);
        }
      }
      return prev;
    }
    return setValidatorObject(
        IBANCountryValidator(countryCode, length, format));
  }

  /// Installs [validator], returning the definition it replaced.
  ///
  /// Throws [StateError] on [defaultIBANValidator].
  IBANCountryValidator? setValidatorObject(IBANCountryValidator validator) {
    _checkMutable();
    final prev = _validatorMap[validator.countryCode];
    _validatorMap[validator.countryCode] = validator;
    if (prev != null) {
      for (final otherCc in prev.otherCountryCodes) {
        _validatorMap.remove(otherCc);
      }
    }
    for (final otherCc in validator.otherCountryCodes) {
      _validatorMap[otherCc] = validator;
    }
    return prev;
  }

  void _checkMutable() {
    if (_isDefault) {
      throw StateError('The singleton validator cannot be modified');
    }
  }
}
