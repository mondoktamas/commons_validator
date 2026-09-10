import org.apache.commons.validator.routines.checkdigit.*;
import java.io.*;
import java.util.*;

/** Reads "routine<TAB>code" lines on stdin, writes "routine<TAB>code<TAB>isValid" out. */
public class Diff {
    static CheckDigit routine(String name) {
        switch (name) {
            case "luhn": return LuhnCheckDigit.LUHN_CHECK_DIGIT;
            case "aban": return ABANumberCheckDigit.ABAN_CHECK_DIGIT;
            case "ean13": return EAN13CheckDigit.EAN13_CHECK_DIGIT;
            case "isbn10": return ISBN10CheckDigit.ISBN10_CHECK_DIGIT;
            case "isbn": return ISBNCheckDigit.ISBN_CHECK_DIGIT;
            case "issn": return ISSNCheckDigit.ISSN_CHECK_DIGIT;
            case "cusip": return CUSIPCheckDigit.CUSIP_CHECK_DIGIT;
            case "sedol": return SedolCheckDigit.SEDOL_CHECK_DIGIT;
            case "isin": return ISINCheckDigit.ISIN_CHECK_DIGIT;
            case "verhoeff": return VerhoeffCheckDigit.VERHOEFF_CHECK_DIGIT;
            case "iban": return IBANCheckDigit.IBAN_CHECK_DIGIT;
            case "cas": return CASNumberCheckDigit.getInstance();
            case "ec": return ECNumberCheckDigit.getInstance();
            case "mod10luhn": return new ModulusTenCheckDigit(new int[]{1,2}, true, true);
            case "mod10aban": return new ModulusTenCheckDigit(new int[]{1,7,3}, true);
            case "mod10ean13": return new ModulusTenCheckDigit(new int[]{1,3}, true);
            default: throw new IllegalArgumentException(name);
        }
    }

    public static void main(String[] args) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        Map<String, CheckDigit> cache = new HashMap<>();
        String line;
        while ((line = in.readLine()) != null) {
            int tab = line.indexOf('\t');
            if (tab < 0) continue;
            String name = line.substring(0, tab);
            String code = line.substring(tab + 1);
            CheckDigit r = cache.computeIfAbsent(name, Diff::routine);
            boolean valid;
            try { valid = r.isValid(code); } catch (RuntimeException e) { valid = false; }
            String calc;
            try { calc = r.calculate(code); }
            catch (Exception e) { calc = "!" + e.getClass().getSimpleName(); }
            out.println(name + "\t" + code + "\t" + valid + "\t" + calc);
        }
        out.flush();
    }
}
