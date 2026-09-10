import '../internal/ascii.dart';
import '../internal/idna.dart';
import 'domain_tlds.dart';
import 'regex_validator.dart';

/// Which TLD table an override applies to.
///
/// Ported from `DomainValidator.ArrayType`. The `*Ro` values name the read-only
/// built-in tables; passing one to [DomainValidator.updateTLDOverride] is an
/// error, as it is upstream.
enum ArrayType {
  /// Additions to the generic TLD table.
  genericPlus,

  /// Removals from the generic TLD table.
  genericMinus,

  /// The built-in generic TLD table, read only.
  genericRo,

  /// Additions to the country-code TLD table.
  countryCodePlus,

  /// Removals from the country-code TLD table.
  countryCodeMinus,

  /// The built-in country-code TLD table, read only.
  countryCodeRo,

  /// The built-in infrastructure TLD table, read only.
  infrastructureRo,

  /// The built-in local TLD table, read only.
  localRo,

  /// Additions to the local TLD table.
  localPlus,

  /// Removals from the local TLD table.
  localMinus;

  /// Whether this table is read only.
  bool get isReadOnly => switch (this) {
        genericRo || countryCodeRo || infrastructureRo || localRo => true,
        _ => false,
      };
}

/// A per-instance TLD table override, for
/// [DomainValidator.getInstanceWithOverrides].
///
/// Ported from `DomainValidator.Item`.
class Item {
  /// Creates an override of [type] holding [values].
  const Item(this.type, this.values);

  /// Which table to override.
  final ArrayType type;

  /// The TLDs, which need not be sorted or lower-cased.
  final List<String> values;
}

/// Validates domain names against RFC 1034/1123 syntax and the IANA TLD lists.
///
/// Ported from `org.apache.commons.validator.routines.DomainValidator`.
///
/// Unicode domains are converted with [toAscii] first, so `exämple.com` and
/// `xn--exmple-cua.com` validate alike.
class DomainValidator {
  DomainValidator._(this.allowLocal)
      : _myCountryCodeTldsMinus = _countryCodeTldsMinus,
        _myCountryCodeTldsPlus = _countryCodeTldsPlus,
        _myGenericTldsMinus = _genericTldsMinus,
        _myGenericTldsPlus = _genericTldsPlus,
        _myLocalTldsMinus = _localTldsMinus,
        _myLocalTldsPlus = _localTldsPlus;

  DomainValidator._withItems(this.allowLocal, List<Item> items)
      : _myCountryCodeTldsMinus =
            _pick(items, ArrayType.countryCodeMinus, _countryCodeTldsMinus),
        _myCountryCodeTldsPlus =
            _pick(items, ArrayType.countryCodePlus, _countryCodeTldsPlus),
        _myGenericTldsMinus =
            _pick(items, ArrayType.genericMinus, _genericTldsMinus),
        _myGenericTldsPlus =
            _pick(items, ArrayType.genericPlus, _genericTldsPlus),
        _myLocalTldsMinus = _pick(items, ArrayType.localMinus, _localTldsMinus),
        _myLocalTldsPlus = _pick(items, ArrayType.localPlus, _localTldsPlus);

  static const int _maxDomainLength = 253;

  // Java's \p{Alnum} and \p{Alpha} are the ASCII-only POSIX classes, not Unicode
  // properties: no UNICODE_CHARACTER_CLASS flag is set upstream. Expanding them
  // to explicit ASCII ranges is what keeps the port from silently accepting
  // accented and other non-ASCII letters here.
  //
  // The atomic group `(?>...)` upstream uses is not supported by Dart's RegExp.
  // A plain `(?:...)` is equivalent for match/no-match, since the group is
  // bounded and followed by a mandatory character; only backtracking cost
  // differs, and a hostile 100-character label still resolves instantly.
  static const String _domainLabelRegex =
      r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?';
  static const String _topLabelRegex =
      r'[A-Za-z](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?';
  static const String _domainNameRegex =
      '^(?:$_domainLabelRegex\\.)+($_topLabelRegex)\\.?\$';

  // Process-global override state, as upstream. It can only be changed before
  // the first getInstance call.
  static bool _inUse = false;
  static List<String> _countryCodeTldsPlus = const [];
  static List<String> _countryCodeTldsMinus = const [];
  static List<String> _genericTldsPlus = const [];
  static List<String> _genericTldsMinus = const [];
  static List<String> _localTldsPlus = const [];
  static List<String> _localTldsMinus = const [];

  static DomainValidator? _instance;
  static DomainValidator? _instanceWithLocal;

  /// The shared instance.
  ///
  /// Calling this freezes [updateTLDOverride]; any overrides must be installed
  /// first, at startup.
  static DomainValidator getInstance({bool allowLocal = false}) {
    _inUse = true;
    if (allowLocal) {
      return _instanceWithLocal ??= DomainValidator._(true);
    }
    return _instance ??= DomainValidator._(false);
  }

  /// A fresh instance carrying [items] as its overrides.
  ///
  /// Prefer this to [updateTLDOverride]: the overrides are scoped to the
  /// instance rather than to the process.
  static DomainValidator getInstanceWithOverrides(
    List<Item> items, {
    bool allowLocal = false,
  }) {
    _inUse = true;
    return DomainValidator._withItems(allowLocal, items);
  }

  /// Replaces one of the mutable override tables, process-wide.
  ///
  /// Throws [StateError] once [getInstance] has been called - upstream throws
  /// `IllegalStateException` - and [ArgumentError] for a read-only table. Pass an
  /// empty list to clear an override.
  static void updateTLDOverride(ArrayType table, List<String> tlds) {
    if (_inUse) {
      throw StateError(
          'Can only invoke this method before calling getInstance');
    }
    if (table.isReadOnly) {
      throw ArgumentError.value(table, 'table', 'Cannot update the table');
    }
    final copy = _normalize(tlds);
    switch (table) {
      case ArrayType.countryCodeMinus:
        _countryCodeTldsMinus = copy;
      case ArrayType.countryCodePlus:
        _countryCodeTldsPlus = copy;
      case ArrayType.genericMinus:
        _genericTldsMinus = copy;
      case ArrayType.genericPlus:
        _genericTldsPlus = copy;
      case ArrayType.localMinus:
        _localTldsMinus = copy;
      case ArrayType.localPlus:
        _localTldsPlus = copy;
      // ignore: no_default_cases
      default:
        throw ArgumentError.value(table, 'table', 'Unexpected enum value');
    }
  }

  /// The current contents of an override table.
  static List<String> getTLDEntries(ArrayType table) => switch (table) {
        ArrayType.countryCodeMinus => List.of(_countryCodeTldsMinus),
        ArrayType.countryCodePlus => List.of(_countryCodeTldsPlus),
        ArrayType.genericMinus => List.of(_genericTldsMinus),
        ArrayType.genericPlus => List.of(_genericTldsPlus),
        ArrayType.localMinus => List.of(_localTldsMinus),
        ArrayType.localPlus => List.of(_localTldsPlus),
        ArrayType.genericRo => List.of(genericTlds),
        ArrayType.countryCodeRo => List.of(countryCodeTlds),
        ArrayType.infrastructureRo => List.of(infrastructureTlds),
        ArrayType.localRo => List.of(localTlds),
      };

  /// Clears every process-wide override and unfreezes [updateTLDOverride].
  ///
  /// Not part of the Java API: upstream relies on a fresh classloader per test
  /// (`DomainValidatorStartupTest`), which has no Dart equivalent. Intended for
  /// tests only.
  static void resetOverridesForTesting() {
    _inUse = false;
    _countryCodeTldsPlus = const [];
    _countryCodeTldsMinus = const [];
    _genericTldsPlus = const [];
    _genericTldsMinus = const [];
    _localTldsPlus = const [];
    _localTldsMinus = const [];
    _instance = null;
    _instanceWithLocal = null;
  }

  static List<String> _normalize(List<String> tlds) =>
      List<String>.unmodifiable(tlds.map(asciiToLowerCase).toList()..sort());

  static List<String> _pick(
    List<Item> items,
    ArrayType type,
    List<String> fallback,
  ) {
    for (final item in items) {
      if (item.type == type) return _normalize(item.values);
    }
    return fallback;
  }

  /// Whether TLDs such as `localhost` are accepted.
  final bool allowLocal;

  final RegexValidator _domainRegex = RegexValidator(_domainNameRegex);
  final RegexValidator _hostnameRegex = RegexValidator(_domainLabelRegex);

  final List<String> _myCountryCodeTldsMinus;
  final List<String> _myCountryCodeTldsPlus;
  final List<String> _myGenericTldsMinus;
  final List<String> _myGenericTldsPlus;
  final List<String> _myLocalTldsMinus;
  final List<String> _myLocalTldsPlus;

  /// Whether [domain] is a valid domain name.
  bool isValid(String? domain) {
    if (domain == null) return false;
    final ascii = unicodeToAscii(domain);
    if (ascii.length > _maxDomainLength) return false;
    final groups = _domainRegex.match(ascii);
    if (groups != null && groups.isNotEmpty) {
      return isValidTld(groups[0]);
    }
    return allowLocal && _hostnameRegex.isValid(ascii);
  }

  /// Whether [domain] has valid domain *syntax*, ignoring the TLD lists.
  bool isValidDomainSyntax(String? domain) {
    if (domain == null) return false;
    final ascii = unicodeToAscii(domain);
    if (ascii.length > _maxDomainLength) return false;
    final groups = _domainRegex.match(ascii);
    return (groups != null && groups.isNotEmpty) ||
        _hostnameRegex.isValid(ascii);
  }

  /// Whether [tld] is a valid TLD of any kind this instance accepts.
  bool isValidTld(String? tld) {
    if (allowLocal && isValidLocalTld(tld)) return true;
    return isValidInfrastructureTld(tld) ||
        isValidGenericTld(tld) ||
        isValidCountryCodeTld(tld);
  }

  /// Whether [iTld] is an infrastructure TLD, i.e. `arpa`.
  bool isValidInfrastructureTld(String? iTld) =>
      _contains(infrastructureTlds, _key(iTld));

  /// Whether [gTld] is a generic TLD, honouring this instance's overrides.
  bool isValidGenericTld(String? gTld) {
    final key = _key(gTld);
    return (_contains(genericTlds, key) ||
            _contains(_myGenericTldsPlus, key)) &&
        !_contains(_myGenericTldsMinus, key);
  }

  /// Whether [ccTld] is a country-code TLD, honouring this instance's overrides.
  bool isValidCountryCodeTld(String? ccTld) {
    final key = _key(ccTld);
    return (_contains(countryCodeTlds, key) ||
            _contains(_myCountryCodeTldsPlus, key)) &&
        !_contains(_myCountryCodeTldsMinus, key);
  }

  /// Whether [lTld] is a local TLD, honouring this instance's overrides.
  bool isValidLocalTld(String? lTld) {
    final key = _key(lTld);
    return (_contains(localTlds, key) || _contains(_myLocalTldsPlus, key)) &&
        !_contains(_myLocalTldsMinus, key);
  }

  /// This instance's overrides for [table].
  List<String> getOverrides(ArrayType table) => switch (table) {
        ArrayType.countryCodeMinus => List.of(_myCountryCodeTldsMinus),
        ArrayType.countryCodePlus => List.of(_myCountryCodeTldsPlus),
        ArrayType.genericMinus => List.of(_myGenericTldsMinus),
        ArrayType.genericPlus => List.of(_myGenericTldsPlus),
        ArrayType.localMinus => List.of(_myLocalTldsMinus),
        ArrayType.localPlus => List.of(_myLocalTldsPlus),
        _ => throw ArgumentError.value(table, 'table', 'Unexpected enum value'),
      };

  /// Normalises a TLD for lookup: ASCII-converted, lower-cased, leading dot
  /// removed.
  static String _key(String? tld) {
    if (tld == null) return '';
    final ascii = asciiToLowerCase(unicodeToAscii(tld));
    return ascii.startsWith('.') ? ascii.substring(1) : ascii;
  }

  /// Binary search, matching upstream's `Arrays.binarySearch` on sorted tables.
  static bool _contains(List<String> sorted, String key) {
    var low = 0;
    var high = sorted.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final cmp = sorted[mid].compareTo(key);
      if (cmp < 0) {
        low = mid + 1;
      } else if (cmp > 0) {
        high = mid - 1;
      } else {
        return true;
      }
    }
    return false;
  }
}

/// Converts a possibly-Unicode domain to punycode, returning [input] unchanged
/// if it cannot be converted.
///
/// Ported from `DomainValidator.unicodeToASCII`. The order of the guards matters
/// and is preserved:
///
/// 1. Pure ASCII short-circuits, which is also what leaves an `xn--` label alone.
/// 2. Format characters and the nameprep "map to nothing" set are rejected by
///    returning the input untouched, because [toAscii] would silently *delete*
///    them - so `exam{soft hyphen}ple.com` would otherwise punycode down to a
///    clean and quite different host.
/// 3. A label starting or ending with a hyphen is likewise returned untouched.
///    This has to happen before conversion: `-t{e-acute}st` encodes to
///    `xn---tst-cpa`, which then satisfies the label regex, so the hyphen would
///    slip through on a non-ASCII label although the all-ASCII form is rejected
///    (VALIDATOR-501).
/// 4. Only then is the conversion attempted, with failure falling back to the
///    original input.
String unicodeToAscii(String input) {
  if (isOnlyAscii(input)) return input;

  for (final cp in input.runes) {
    if (_isFormatChar(cp) || _isNameprepMappedToNothing(cp)) return input;
  }
  if (_hasLabelBoundaryHyphen(input)) return input;

  try {
    return toAscii(input);
  } on IdnaException {
    return input;
  }
}

final RegExp _formatCharPattern = RegExp(r'\p{Cf}', unicode: true);

/// Whether [cp] is in Unicode general category `Cf`, standing in for Java's
/// `Character.getType(cp) == Character.FORMAT`.
bool _isFormatChar(int cp) =>
    _formatCharPattern.hasMatch(String.fromCharCode(cp));

/// The code points nameprep maps to nothing that are *not* category `Cf`, and so
/// are missed by [_isFormatChar].
bool _isNameprepMappedToNothing(int cp) =>
    cp == 0x034F || // COMBINING GRAPHEME JOINER
    cp == 0x1806 || // MONGOLIAN TODO SOFT HYPHEN
    (cp >= 0x180B && cp <= 0x180D) || // MONGOLIAN FREE VARIATION SELECTORs
    (cp >= 0xFE00 && cp <= 0xFE0F); // VARIATION SELECTOR-1..16

/// Whether any label of [input] begins or ends with an ASCII hyphen.
bool _hasLabelBoundaryHyphen(String input) {
  var labelStart = true;
  for (var i = 0; i < input.length; i++) {
    final ch = input.codeUnitAt(i);
    if (isLabelSeparator(ch)) {
      if (i > 0 && input.codeUnitAt(i - 1) == 0x2D) return true;
      labelStart = true;
    } else {
      if (labelStart && ch == 0x2D) return true;
      labelStart = false;
    }
  }
  final last = input.length - 1;
  return last >= 0 && input.codeUnitAt(last) == 0x2D;
}
