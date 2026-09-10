import org.apache.commons.validator.routines.*;
import java.io.*;

/** Reads "which<TAB>value" lines, writes "which<TAB>value<TAB>result". */
public class Diff4 {
    static final DomainValidator DOM = DomainValidator.getInstance();
    static final DomainValidator DOM_LOCAL = DomainValidator.getInstance(true);
    static final InetAddressValidator IP = InetAddressValidator.getInstance();
    static final EmailValidator EMAIL = EmailValidator.getInstance();
    static final EmailValidator EMAIL_LOCAL = EmailValidator.getInstance(true);
    static final EmailValidator EMAIL_TLD = EmailValidator.getInstance(false, true);
    static final UrlValidator URL = UrlValidator.getInstance();
    static final UrlValidator URL_ALL = new UrlValidator(UrlValidator.ALLOW_ALL_SCHEMES);
    static final UrlValidator URL_LOCAL = new UrlValidator(UrlValidator.ALLOW_LOCAL_URLS);
    static final UrlValidator URL_NOFRAG = new UrlValidator(UrlValidator.NO_FRAGMENTS);
    static final UrlValidator URL_2SLASH = new UrlValidator(UrlValidator.ALLOW_2_SLASHES);

    static String eval(String which, String v) {
        try {
            switch (which) {
                case "domain":        return String.valueOf(DOM.isValid(v));
                case "domain_local":  return String.valueOf(DOM_LOCAL.isValid(v));
                case "tld":           return String.valueOf(DOM.isValidTld(v));
                case "tld_generic":   return String.valueOf(DOM.isValidGenericTld(v));
                case "tld_cc":        return String.valueOf(DOM.isValidCountryCodeTld(v));
                case "tld_infra":     return String.valueOf(DOM.isValidInfrastructureTld(v));
                case "tld_local":     return String.valueOf(DOM_LOCAL.isValidLocalTld(v));
                case "ip":            return String.valueOf(IP.isValid(v));
                case "ip4":           return String.valueOf(IP.isValidInet4Address(v));
                case "ip6":           return String.valueOf(IP.isValidInet6Address(v));
                case "email":         return String.valueOf(EMAIL.isValid(v));
                case "email_local":   return String.valueOf(EMAIL_LOCAL.isValid(v));
                case "email_tld":     return String.valueOf(EMAIL_TLD.isValid(v));
                case "url":           return String.valueOf(URL.isValid(v));
                case "url_all":       return String.valueOf(URL_ALL.isValid(v));
                case "url_local":     return String.valueOf(URL_LOCAL.isValid(v));
                case "url_nofrag":    return String.valueOf(URL_NOFRAG.isValid(v));
                case "url_2slash":    return String.valueOf(URL_2SLASH.isValid(v));
                default: throw new IllegalArgumentException(which);
            }
        } catch (Exception e) { return "!" + e.getClass().getSimpleName(); }
    }

    public static void main(String[] a) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            int tab = line.indexOf('\t');
            if (tab < 0) continue;
            out.println(line + "\t" + eval(line.substring(0, tab), line.substring(tab + 1)));
        }
        out.flush();
    }
}
