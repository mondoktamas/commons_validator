import org.apache.commons.validator.routines.*;
import java.io.*;
import java.util.*;
import java.text.SimpleDateFormat;

/** Reads "which<TAB>pattern<TAB>value", prints the parsed value or null. */
public class Diff6P {
    static final TimeZone UTC = TimeZone.getTimeZone("UTC");
    static final SimpleDateFormat OUT = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");
    static { OUT.setTimeZone(UTC); }

    static String eval(String which, String pattern, String v) {
        try {
            switch (which) {
                case "date": {
                    Date d = DateValidator.getInstance().validate(v, pattern, UTC);
                    return d == null ? "null" : OUT.format(d);
                }
                case "date_lax": {
                    Date d = new DateValidator(false, java.text.DateFormat.SHORT).validate(v, pattern, UTC);
                    return d == null ? "null" : OUT.format(d);
                }
                case "cal": {
                    Calendar c = CalendarValidator.getInstance().validate(v, pattern, UTC);
                    return c == null ? "null" : OUT.format(c.getTime());
                }
                case "time": {
                    Calendar c = TimeValidator.getInstance().validate(v, pattern, UTC);
                    return c == null ? "null" : OUT.format(c.getTime());
                }
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
