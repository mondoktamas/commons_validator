import java.net.IDN;
import java.io.*;
/** Reads one Unicode label per line, prints "label<TAB>IDN.toASCII or !Exception". */
public class IdnGen {
    public static void main(String[] a) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
        String line;
        while ((line = in.readLine()) != null) {
            String r;
            try { r = IDN.toASCII(line); }
            catch (Exception e) { r = "!" + e.getClass().getSimpleName(); }
            out.println(line + "\t" + r);
        }
        out.flush();
    }
}
