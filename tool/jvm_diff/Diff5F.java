import org.apache.commons.validator.routines.*;
import java.io.*;
import java.math.BigDecimal;
import java.util.Locale;

/** Reads "which<TAB>locale<TAB>value", prints the formatted result. */
public class Diff5F {
    static Locale loc(String t) { String[] p = t.split("_"); return p.length > 1 ? new Locale(p[0], p[1]) : new Locale(p[0]); }
    static String eval(String which, String tag, String v) {
        Locale l = loc(tag);
        try {
            BigDecimal d = new BigDecimal(v);
            switch (which) {
                case "bigdec":   return BigDecimalValidator.getInstance().format(d, (String) null, l);
                case "int":      return IntegerValidator.getInstance().format(d.intValue(), (String) null, l);
                case "long":     return LongValidator.getInstance().format(d.longValue(), (String) null, l);
                case "currency": return CurrencyValidator.getInstance().format(d, (String) null, l);
                case "percent":  return PercentValidator.getInstance().format(d, (String) null, l);
                case "bigdec_p": return BigDecimalValidator.getInstance().format(d, "#,##0.00", l);
                case "int_p":    return IntegerValidator.getInstance().format(d.intValue(), "#,##0", l);
                default: throw new IllegalArgumentException(which);
            }
        } catch (Exception e) { return "!" + e.getClass().getSimpleName(); }
    }
    public static void main(String[] a) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            String[] p = line.split("\t");
            if (p.length < 3) continue;
            out.println(line + "\t" + eval(p[0], p[1], p[2]));
        }
        out.flush();
    }
}
