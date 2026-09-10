import org.apache.commons.validator.routines.*;
import java.io.*;
import java.util.*;

/** Reads "which<TAB>value" lines, writes "which<TAB>value<TAB>result". */
public class Diff3 {
    static final CreditCardValidator CC_DEFAULT = new CreditCardValidator();
    static final CreditCardValidator CC_GENERIC = CreditCardValidator.genericCreditCardValidator();
    static final CreditCardValidator CC_AMEX = new CreditCardValidator(CreditCardValidator.AMEX);
    static final CreditCardValidator CC_VISA = new CreditCardValidator(CreditCardValidator.VISA);
    static final CreditCardValidator CC_MC = new CreditCardValidator(CreditCardValidator.MASTERCARD);
    static final CreditCardValidator CC_DISC = new CreditCardValidator(CreditCardValidator.DISCOVER);
    static final CreditCardValidator CC_DINERS = new CreditCardValidator(CreditCardValidator.DINERS);
    static final CreditCardValidator CC_VPAY = new CreditCardValidator(CreditCardValidator.VPAY);
    static final ISBNValidator ISBN = ISBNValidator.getInstance();
    static final ISBNValidator ISBN_NC = ISBNValidator.getInstance(false);
    static final ISSNValidator ISSN = ISSNValidator.getInstance();
    static final ISINValidator ISIN_T = ISINValidator.getInstance(true);
    static final ISINValidator ISIN_F = ISINValidator.getInstance(false);
    static final IBANValidator IBAN = IBANValidator.getInstance();

    static String s(Object o) { return o == null ? "null" : o.toString(); }

    static String eval(String which, String v) {
        try {
            switch (which) {
                case "cc_default":  return String.valueOf(CC_DEFAULT.isValid(v)) + "|" + s(CC_DEFAULT.validate(v));
                case "cc_generic":  return String.valueOf(CC_GENERIC.isValid(v)) + "|" + s(CC_GENERIC.validate(v));
                case "cc_amex":     return String.valueOf(CC_AMEX.isValid(v)) + "|" + s(CC_AMEX.validate(v));
                case "cc_visa":     return String.valueOf(CC_VISA.isValid(v)) + "|" + s(CC_VISA.validate(v));
                case "cc_mc":       return String.valueOf(CC_MC.isValid(v)) + "|" + s(CC_MC.validate(v));
                case "cc_disc":     return String.valueOf(CC_DISC.isValid(v)) + "|" + s(CC_DISC.validate(v));
                case "cc_diners":   return String.valueOf(CC_DINERS.isValid(v)) + "|" + s(CC_DINERS.validate(v));
                case "cc_vpay":     return String.valueOf(CC_VPAY.isValid(v)) + "|" + s(CC_VPAY.validate(v));
                case "isbn":        return String.valueOf(ISBN.isValid(v)) + "|" + s(ISBN.validate(v));
                case "isbn_nc":     return String.valueOf(ISBN_NC.isValid(v)) + "|" + s(ISBN_NC.validate(v));
                case "isbn10":      return String.valueOf(ISBN.isValidISBN10(v)) + "|" + s(ISBN.validateISBN10(v));
                case "isbn13":      return String.valueOf(ISBN.isValidISBN13(v)) + "|" + s(ISBN.validateISBN13(v));
                case "issn":        return String.valueOf(ISSN.isValid(v)) + "|" + s(ISSN.validate(v));
                case "issn_ean":    return "-|" + s(ISSN.validateEan(v));
                case "isin_t":      return String.valueOf(ISIN_T.isValid(v)) + "|" + s(ISIN_T.validate(v));
                case "isin_f":      return String.valueOf(ISIN_F.isValid(v)) + "|" + s(ISIN_F.validate(v));
                case "iban":        return String.valueOf(IBAN.isValid(v)) + "|" + IBAN.validate(v);
                default: throw new IllegalArgumentException(which);
            }
        } catch (Exception e) {
            return "!" + e.getClass().getSimpleName();
        }
    }

    public static void main(String[] args) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            int tab = line.indexOf('\t');
            if (tab < 0) continue;
            String which = line.substring(0, tab), v = line.substring(tab + 1);
            out.println(which + "\t" + v + "\t" + eval(which, v));
        }
        out.flush();
    }
}
