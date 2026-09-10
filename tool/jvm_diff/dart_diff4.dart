import 'dart:convert';
import 'dart:io';

import 'package:commons_validator/src/routines/domain_validator.dart';
import 'package:commons_validator/src/routines/email_validator.dart';
import 'package:commons_validator/src/routines/inet_address_validator.dart';
import 'package:commons_validator/src/routines/url_validator.dart';

final dom = DomainValidator.getInstance();
final domLocal = DomainValidator.getInstance(allowLocal: true);
final ip = InetAddressValidator.getInstance();
final email = EmailValidator.getInstance();
final emailLocal = EmailValidator.getInstance(allowLocal: true);
final emailTld = EmailValidator.getInstance(allowTld: true);
final url = UrlValidator.getInstance();
final urlAll = UrlValidator(options: UrlValidator.allowAllSchemes);
final urlLocal = UrlValidator(options: UrlValidator.allowLocalUrls);
final urlNofrag = UrlValidator(options: UrlValidator.noFragments);
final url2slash = UrlValidator(options: UrlValidator.allow2Slashes);

String eval(String which, String v) {
  try {
    return switch (which) {
      'domain' => '${dom.isValid(v)}',
      'domain_local' => '${domLocal.isValid(v)}',
      'tld' => '${dom.isValidTld(v)}',
      'tld_generic' => '${dom.isValidGenericTld(v)}',
      'tld_cc' => '${dom.isValidCountryCodeTld(v)}',
      'tld_infra' => '${dom.isValidInfrastructureTld(v)}',
      'tld_local' => '${domLocal.isValidLocalTld(v)}',
      'ip' => '${ip.isValid(v)}',
      'ip4' => '${ip.isValidInet4Address(v)}',
      'ip6' => '${ip.isValidInet6Address(v)}',
      'email' => '${email.isValid(v)}',
      'email_local' => '${emailLocal.isValid(v)}',
      'email_tld' => '${emailTld.isValid(v)}',
      'url' => '${url.isValid(v)}',
      'url_all' => '${urlAll.isValid(v)}',
      'url_local' => '${urlLocal.isValid(v)}',
      'url_nofrag' => '${urlNofrag.isValid(v)}',
      'url_2slash' => '${url2slash.isValid(v)}',
      _ => throw ArgumentError(which),
    };
  } catch (e) {
    return '!${e.runtimeType}';
  }
}

void main(List<String> args) {
  final out = StringBuffer();
  for (final line in const LineSplitter()
      .convert(File(args[0]).readAsStringSync(encoding: utf8))) {
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    final which = line.substring(0, tab);
    final v = line.substring(tab + 1);
    out.writeln('$which\t$v\t${eval(which, v)}');
  }
  File(args[1]).writeAsStringSync(out.toString(), encoding: utf8);
}
