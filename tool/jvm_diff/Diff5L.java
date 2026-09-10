import org.apache.commons.validator.routines.*;
import java.io.*;
import java.util.Locale;

public class Diff5L {
    static String s(Object o) { return o == null ? "null" : o.toString(); }
    static Locale loc(String tag) { String[] p = tag.split("_"); return new Locale(p[0], p[1]); }
    static String eval(String which, String tag, String v) {
        Locale l = loc(tag);
        try {
            switch (which) {
                case "bigdec":   return s(BigDecimalValidator.getInstance().validate(v, (String) null, l));
                case "int":      return s(IntegerValidator.getInstance().validate(v, (String) null, l));
                case "currency": return s(CurrencyValidator.getInstance().validate(v, (String) null, l));
                case "percent":  return s(PercentValidator.getInstance().validate(v, (String) null, l));
                case "double":   return s(DoubleValidator.getInstance().validate(v, (String) null, l));
                default: throw new IllegalArgumentException(which);
            }
        } catch (Exception e) { return "!" + e.getClass().getSimpleName(); }
    }
    public static void main(String[] a) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            String[] p = line.split("\t", 3);
            if (p.length < 3) continue;
            out.println(line + "\t" + eval(p[0], p[1], p[2]));
        }
        out.flush();
    }
}
