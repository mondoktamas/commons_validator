import java.net.URI;
import java.io.*;
/** Reads one URI per line, prints its raw components or !Exception. */
public class UriDump {
    static final String SEP = "<|>";
    static String n(String s) { return s == null ? "<null>" : s; }
    public static void main(String[] a) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            String r;
            try {
                URI u = new URI(line);
                r = String.join(SEP, n(u.getScheme()), n(u.getRawAuthority()),
                        n(u.getRawPath()), n(u.getRawQuery()), n(u.getRawFragment()));
            } catch (Exception e) { r = "!" + e.getClass().getSimpleName(); }
            out.println(line + "\t" + r);
        }
        out.flush();
    }
}
