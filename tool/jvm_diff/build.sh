#!/bin/sh
# Compiles the upstream Java classes the differential harnesses need.
#
# GenericValidator pulls in the whole legacy package (commons-digester,
# commons-beanutils, commons-logging), but the routines only ever call
# isBlankOrNull - so compile against a stub of just that method, copied verbatim
# from GenericValidator.java:69-72.
set -e
UP=${1:-../../../commons-validator}
OUT=${2:-/tmp/cvdiff}

if [ ! -d "$UP/src/main/java" ]; then
  echo "No Commons Validator checkout at '$UP'." >&2
  echo "Usage: ./build.sh [path/to/commons-validator] [output-dir]" >&2
  exit 2
fi

HERE=$(cd "$(dirname "$0")" && pwd)
R="$UP/src/main/java/org/apache/commons/validator/routines"
mkdir -p "$OUT/classes" "$OUT/stub/org/apache/commons/validator"

cat > "$OUT/stub/org/apache/commons/validator/GenericValidator.java" <<'JAVA'
package org.apache.commons.validator;

public class GenericValidator {
    public static boolean isBlankOrNull(final String value) {
        return value == null || value.isEmpty() || value.trim().isEmpty();
    }
}
JAVA

# ISBNValidator is in the set only because CheckDigit.java imports it for a
# javadoc link.
javac -d "$OUT/classes" -nowarn \
  "$OUT/stub/org/apache/commons/validator/GenericValidator.java" \
  "$R"/checkdigit/*.java \
  "$R"/CodeValidator.java "$R"/RegexValidator.java "$R"/ISBNValidator.java \
  "$R"/ISSNValidator.java "$R"/ISINValidator.java \
  "$R"/IBANValidator.java "$R"/IBANValidatorStatus.java \
  "$R"/CreditCardValidator.java \
  "$R"/DomainValidator.java "$R"/InetAddressValidator.java \
  "$R"/EmailValidator.java "$R"/UrlValidator.java \
  "$R"/AbstractFormatValidator.java "$R"/AbstractNumberValidator.java \
  "$R"/ByteValidator.java "$R"/ShortValidator.java "$R"/IntegerValidator.java \
  "$R"/LongValidator.java "$R"/FloatValidator.java "$R"/DoubleValidator.java \
  "$R"/BigDecimalValidator.java "$R"/BigIntegerValidator.java \
  "$R"/CurrencyValidator.java "$R"/PercentValidator.java \
  "$R"/AbstractCalendarValidator.java "$R"/DateValidator.java \
  "$R"/CalendarValidator.java "$R"/TimeValidator.java

javac -cp "$OUT/classes" -d "$OUT/classes" "$HERE"/*.java

echo "Compiled upstream classes and harnesses into $OUT/classes"
echo "Run e.g.: java -cp $OUT/classes Diff4 < corpus.tsv"
