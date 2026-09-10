// GENERATED FILE - do not edit by hand.
//
// Regenerate with tool/generate_iban.dart.
//
// Transcribed from `IBANValidator.DEFAULT_VALIDATORS`.

import 'iban_validator.dart';

/// The IBAN format definitions shipped with the library, one per country.
///
/// A handful of entries carry alias country codes and supply their pattern
/// *without* the country-code prefix, so the same body can be shared: FI covers
/// AX, FR covers twelve overseas territories, and GB covers IM, JE and GG.
final List<IBANCountryValidator> defaultIBANValidators = [
  // Andorra
  IBANCountryValidator('AD', 24, r'AD\d{10}[A-Z0-9]{12}'),
  // United Arab Emirates (The)
  IBANCountryValidator('AE', 23, r'AE\d{21}'),
  // Albania
  IBANCountryValidator('AL', 28, r'AL\d{10}[A-Z0-9]{16}'),
  // Austria
  IBANCountryValidator('AT', 20, r'AT\d{18}'),
  // Azerbaijan
  IBANCountryValidator('AZ', 28, r'AZ\d{2}[A-Z]{4}[A-Z0-9]{20}'),
  // Bosnia and Herzegovina
  IBANCountryValidator('BA', 20, r'BA\d{18}'),
  // Belgium
  IBANCountryValidator('BE', 16, r'BE\d{14}'),
  // Bulgaria
  IBANCountryValidator('BG', 22, r'BG\d{2}[A-Z]{4}\d{6}[A-Z0-9]{8}'),
  // Bahrain
  IBANCountryValidator('BH', 22, r'BH\d{2}[A-Z]{4}[A-Z0-9]{14}'),
  // Burundi
  IBANCountryValidator('BI', 27, r'BI\d{25}'),
  // Brazil
  IBANCountryValidator('BR', 29, r'BR\d{25}[A-Z]{1}[A-Z0-9]{1}'),
  // Republic of Belarus
  IBANCountryValidator('BY', 28, r'BY\d{2}[A-Z0-9]{4}\d{4}[A-Z0-9]{16}'),
  // Switzerland
  IBANCountryValidator('CH', 21, r'CH\d{7}[A-Z0-9]{12}'),
  // Costa Rica
  IBANCountryValidator('CR', 22, r'CR\d{20}'),
  // Cyprus
  IBANCountryValidator('CY', 28, r'CY\d{10}[A-Z0-9]{16}'),
  // Czechia
  IBANCountryValidator('CZ', 24, r'CZ\d{22}'),
  // Germany
  IBANCountryValidator('DE', 22, r'DE\d{20}'),
  // Djibouti
  IBANCountryValidator('DJ', 27, r'DJ\d{25}'),
  // Denmark
  IBANCountryValidator('DK', 18, r'DK\d{16}'),
  // Dominican Republic
  IBANCountryValidator('DO', 28, r'DO\d{2}[A-Z0-9]{4}\d{20}'),
  // Estonia
  IBANCountryValidator('EE', 20, r'EE\d{18}'),
  // Egypt
  IBANCountryValidator('EG', 29, r'EG\d{27}'),
  // Spain
  IBANCountryValidator('ES', 24, r'ES\d{22}'),
  // Finland
  IBANCountryValidator.withoutCountryCodePrefix('FI', 18, r'\d{16}',
      otherCountryCodes: ['AX']),
  // Falkland Islands, since Jul-23
  IBANCountryValidator('FK', 18, r'FK\d{2}[A-Z]{2}\d{12}'),
  // Faroe Islands
  IBANCountryValidator('FO', 18, r'FO\d{16}'),
  // France
  IBANCountryValidator.withoutCountryCodePrefix(
      'FR', 27, r'\d{12}[A-Z0-9]{11}\d{2}', otherCountryCodes: [
    'GF',
    'GP',
    'MQ',
    'RE',
    'PF',
    'TF',
    'YT',
    'NC',
    'BL',
    'MF',
    'PM',
    'WF'
  ]),
  // United Kingdom
  IBANCountryValidator.withoutCountryCodePrefix(
      'GB', 22, r'\d{2}[A-Z]{4}\d{14}',
      otherCountryCodes: ['IM', 'JE', 'GG']),
  // Georgia
  IBANCountryValidator('GE', 22, r'GE\d{2}[A-Z]{2}\d{16}'),
  // Gibraltar
  IBANCountryValidator('GI', 23, r'GI\d{2}[A-Z]{4}[A-Z0-9]{15}'),
  // Greenland
  IBANCountryValidator('GL', 18, r'GL\d{16}'),
  // Greece
  IBANCountryValidator('GR', 27, r'GR\d{9}[A-Z0-9]{16}'),
  // Guatemala
  IBANCountryValidator('GT', 28, r'GT\d{2}[A-Z0-9]{24}'),
  // Honduras, since Dec-24
  IBANCountryValidator('HN', 28, r'HN\d{2}[A-Z]{4}\d{20}'),
  // Croatia
  IBANCountryValidator('HR', 21, r'HR\d{19}'),
  // Hungary
  IBANCountryValidator('HU', 28, r'HU\d{26}'),
  // Ireland
  IBANCountryValidator('IE', 22, r'IE\d{2}[A-Z]{4}\d{14}'),
  // Israel
  IBANCountryValidator('IL', 23, r'IL\d{21}'),
  // Iraq
  IBANCountryValidator('IQ', 23, r'IQ\d{2}[A-Z]{4}\d{15}'),
  // Iceland
  IBANCountryValidator('IS', 26, r'IS\d{24}'),
  // Italy
  IBANCountryValidator('IT', 27, r'IT\d{2}[A-Z]{1}\d{10}[A-Z0-9]{12}'),
  // Jordan
  IBANCountryValidator('JO', 30, r'JO\d{2}[A-Z]{4}\d{4}[A-Z0-9]{18}'),
  // Kuwait
  IBANCountryValidator('KW', 30, r'KW\d{2}[A-Z]{4}[A-Z0-9]{22}'),
  // Kazakhstan
  IBANCountryValidator('KZ', 20, r'KZ\d{5}[A-Z0-9]{13}'),
  // Lebanon
  IBANCountryValidator('LB', 28, r'LB\d{6}[A-Z0-9]{20}'),
  // Saint Lucia
  IBANCountryValidator('LC', 32, r'LC\d{2}[A-Z]{4}[A-Z0-9]{24}'),
  // Liechtenstein
  IBANCountryValidator('LI', 21, r'LI\d{7}[A-Z0-9]{12}'),
  // Lithuania
  IBANCountryValidator('LT', 20, r'LT\d{18}'),
  // Luxembourg
  IBANCountryValidator('LU', 20, r'LU\d{5}[A-Z0-9]{13}'),
  // Latvia
  IBANCountryValidator('LV', 21, r'LV\d{2}[A-Z]{4}[A-Z0-9]{13}'),
  // Libya
  IBANCountryValidator('LY', 25, r'LY\d{23}'),
  // Monaco
  IBANCountryValidator('MC', 27, r'MC\d{12}[A-Z0-9]{11}\d{2}'),
  // Moldova
  IBANCountryValidator('MD', 24, r'MD\d{2}[A-Z0-9]{20}'),
  // Montenegro
  IBANCountryValidator('ME', 22, r'ME\d{20}'),
  // Macedonia
  IBANCountryValidator('MK', 19, r'MK\d{5}[A-Z0-9]{10}\d{2}'),
  // Mongolia, since Apr-23
  IBANCountryValidator('MN', 20, r'MN\d{18}'),
  // Mauritania
  IBANCountryValidator('MR', 27, r'MR\d{25}'),
  // Malta
  IBANCountryValidator('MT', 31, r'MT\d{2}[A-Z]{4}\d{5}[A-Z0-9]{18}'),
  // Mauritius
  IBANCountryValidator('MU', 30, r'MU\d{2}[A-Z]{4}\d{19}[A-Z]{3}'),
  // Nicaragua, since Apr-23
  IBANCountryValidator('NI', 28, r'NI\d{2}[A-Z]{4}\d{20}'),
  // Netherlands (The)
  IBANCountryValidator('NL', 18, r'NL\d{2}[A-Z]{4}\d{10}'),
  // Norway
  IBANCountryValidator('NO', 15, r'NO\d{13}'),
  // Oman, since Mar-24
  IBANCountryValidator('OM', 23, r'OM\d{5}[A-Z0-9]{16}'),
  // Pakistan
  IBANCountryValidator('PK', 24, r'PK\d{2}[A-Z]{4}[A-Z0-9]{16}'),
  // Poland
  IBANCountryValidator('PL', 28, r'PL\d{26}'),
  // Palestine, State of
  IBANCountryValidator('PS', 29, r'PS\d{2}[A-Z]{4}[A-Z0-9]{21}'),
  // Portugal
  IBANCountryValidator('PT', 25, r'PT\d{23}'),
  // Qatar
  IBANCountryValidator('QA', 29, r'QA\d{2}[A-Z]{4}[A-Z0-9]{21}'),
  // Romania
  IBANCountryValidator('RO', 24, r'RO\d{2}[A-Z]{4}[A-Z0-9]{16}'),
  // Serbia
  IBANCountryValidator('RS', 22, r'RS\d{20}'),
  // Russia
  IBANCountryValidator('RU', 33, r'RU\d{16}[A-Z0-9]{15}'),
  // Saudi Arabia
  IBANCountryValidator('SA', 24, r'SA\d{4}[A-Z0-9]{18}'),
  // Seychelles
  IBANCountryValidator('SC', 31, r'SC\d{2}[A-Z]{4}\d{20}[A-Z]{3}'),
  // Sudan
  IBANCountryValidator('SD', 18, r'SD\d{16}'),
  // Sweden
  IBANCountryValidator('SE', 24, r'SE\d{22}'),
  // Slovenia
  IBANCountryValidator('SI', 19, r'SI\d{17}'),
  // Slovakia
  IBANCountryValidator('SK', 24, r'SK\d{22}'),
  // San Marino
  IBANCountryValidator('SM', 27, r'SM\d{2}[A-Z]{1}\d{10}[A-Z0-9]{12}'),
  // Somalia, since Feb-23
  IBANCountryValidator('SO', 23, r'SO\d{21}'),
  // Sao Tome and Principe
  IBANCountryValidator('ST', 25, r'ST\d{23}'),
  // El Salvador
  IBANCountryValidator('SV', 28, r'SV\d{2}[A-Z]{4}\d{20}'),
  // Timor-Leste
  IBANCountryValidator('TL', 23, r'TL\d{21}'),
  // Tunisia
  IBANCountryValidator('TN', 24, r'TN\d{22}'),
  // Turkey
  IBANCountryValidator('TR', 26, r'TR\d{8}[A-Z0-9]{16}'),
  // Ukraine
  IBANCountryValidator('UA', 29, r'UA\d{8}[A-Z0-9]{19}'),
  // Vatican City State
  IBANCountryValidator('VA', 22, r'VA\d{20}'),
  // Virgin Islands
  IBANCountryValidator('VG', 24, r'VG\d{2}[A-Z]{4}\d{16}'),
  // Kosovo
  IBANCountryValidator('XK', 20, r'XK\d{18}'),
  // Yemen
  IBANCountryValidator('YE', 30, r'YE\d{2}[A-Z]{4}\d{4}[A-Z0-9]{18}'),
];
