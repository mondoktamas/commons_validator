import org.apache.commons.validator.routines.*;
import java.io.*;
import java.util.Locale;

/** Reads "which<TAB>value" lines, writes the validator's parse result. */
public class Diff5 {
    static final Locale US = Locale.US;
    static String s(Object o) { return o == null ? "null" : o.toString(); }

    static String eval(String which, String v) {
        try {
            switch (which) {
                case "byte":      return s(ByteValidator.getInstance().validate(v, (String) null, US));
                case "byte_lax":  return s(new ByteValidator(false, 0).validate(v, (String) null, US));
                case "short":     return s(ShortValidator.getInstance().validate(v, (String) null, US));
                case "int":       return s(IntegerValidator.getInstance().validate(v, (String) null, US));
                case "int_lax":   return s(new IntegerValidator(false, 0).validate(v, (String) null, US));
                case "long":      return s(LongValidator.getInstance().validate(v, (String) null, US));
                case "float":     return s(FloatValidator.getInstance().validate(v, (String) null, US));
                case "double":    return s(DoubleValidator.getInstance().validate(v, (String) null, US));
                case "bigdec":    return s(BigDecimalValidator.getInstance().validate(v, (String) null, US));
                case "bigint":    return s(BigIntegerValidator.getInstance().validate(v, (String) null, US));
                case "currency":  return s(CurrencyValidator.getInstance().validate(v, (String) null, US));
                case "percent":   return s(PercentValidator.getInstance().validate(v, (String) null, US));
                case "int_pat":   return s(IntegerValidator.getInstance().validate(v, "#,##0", US));
                case "bigdec_pat":return s(BigDecimalValidator.getInstance().validate(v, "#,##0.00", US));
                case "bigdec_sci":return s(BigDecimalValidator.getInstance().validate(v, "0.00E00", US));
                case "bigdec_sci2":return s(BigDecimalValidator.getInstance().validate(v, "0.###E0", US));
                case "double_sci": return s(DoubleValidator.getInstance().validate(v, "#0.#####E0", US));
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
