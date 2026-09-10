import org.apache.commons.validator.routines.*;
import java.io.*;
import java.util.*;

/**
 * Reads "op<TAB>iso1<TAB>iso2[<TAB>extra]" and prints the comparison result.
 * Dates are ISO instants in UTC; comparisons run in UTC with US week rules.
 */
public class Diff6 {
    static final TimeZone UTC = TimeZone.getTimeZone("UTC");
    static final DateValidator DV = DateValidator.getInstance();
    static final CalendarValidator CV = CalendarValidator.getInstance();
    static final TimeValidator TV = TimeValidator.getInstance();

    static Date parseIso(String s) {
        // yyyy-MM-dd'T'HH:mm:ss.SSS
        String[] dt = s.split("T");
        String[] d = dt[0].split("-");
        String[] t = dt[1].split("[:.]");
        Calendar c = Calendar.getInstance(UTC);
        c.clear();
        c.set(Integer.parseInt(d[0]), Integer.parseInt(d[1]) - 1, Integer.parseInt(d[2]),
              Integer.parseInt(t[0]), Integer.parseInt(t[1]), Integer.parseInt(t[2]));
        c.set(Calendar.MILLISECOND, Integer.parseInt(t[3]));
        return c.getTime();
    }

    static Calendar cal(String s) {
        Calendar c = Calendar.getInstance(UTC, Locale.US);
        c.setTime(parseIso(s));
        return c;
    }

    static String eval(String op, String a, String b, String extra) {
        try {
            switch (op) {
                case "dates":     return String.valueOf(DV.compareDates(parseIso(a), parseIso(b), UTC));
                case "weeks":     return String.valueOf(DV.compareWeeks(parseIso(a), parseIso(b), UTC));
                case "months":    return String.valueOf(DV.compareMonths(parseIso(a), parseIso(b), UTC));
                case "years":     return String.valueOf(DV.compareYears(parseIso(a), parseIso(b), UTC));
                case "quarters":  return String.valueOf(DV.compareQuarters(parseIso(a), parseIso(b), UTC,
                                        Integer.parseInt(extra)));
                case "cal_dates": return String.valueOf(CV.compareDates(cal(a), cal(b)));
                case "cal_weeks": return String.valueOf(CV.compareWeeks(cal(a), cal(b)));
                case "cal_months":return String.valueOf(CV.compareMonths(cal(a), cal(b)));
                case "cal_years": return String.valueOf(CV.compareYears(cal(a), cal(b)));
                case "hours":     return String.valueOf(TV.compareHours(cal(a), cal(b)));
                case "minutes":   return String.valueOf(TV.compareMinutes(cal(a), cal(b)));
                case "seconds":   return String.valueOf(TV.compareSeconds(cal(a), cal(b)));
                case "times":     return String.valueOf(TV.compareTime(cal(a), cal(b)));
                default: throw new IllegalArgumentException(op);
            }
        } catch (Exception e) { return "!" + e.getClass().getSimpleName(); }
    }

    public static void main(String[] x) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            String[] p = line.split("\t");
            if (p.length < 3) continue;
            out.println(line + "\t" + eval(p[0], p[1], p[2], p.length > 3 ? p[3] : "1"));
        }
        out.flush();
    }
}
