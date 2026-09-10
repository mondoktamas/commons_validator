import java.util.*;
import java.io.*;
/** Reads "yyyy-MM-dd<TAB>firstDayOfWeek<TAB>minimalDays", prints Java's fields. */
public class WeekDump {
    public static void main(String[] a) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            String[] p = line.split("\t");
            String[] d = p[0].split("-");
            Calendar c = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
            c.clear();
            c.setFirstDayOfWeek(Integer.parseInt(p[1]));
            c.setMinimalDaysInFirstWeek(Integer.parseInt(p[2]));
            c.set(Integer.parseInt(d[0]), Integer.parseInt(d[1]) - 1, Integer.parseInt(d[2]));
            out.println(line + "\t" + c.get(Calendar.DAY_OF_YEAR) + "\t" + c.get(Calendar.DAY_OF_WEEK)
                + "\t" + c.get(Calendar.WEEK_OF_YEAR) + "\t" + c.get(Calendar.WEEK_OF_MONTH));
        }
        out.flush();
    }
}
