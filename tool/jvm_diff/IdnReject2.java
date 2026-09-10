import java.net.IDN;
/**
 * Prints ranges of code points this JDK's IDN.toASCII rejects.
 *
 * A code point counts as rejected only if it fails BOTH on its own and embedded
 * in "a<cp>b". The embedded form alone produces false positives for right-to-left
 * scripts, where the failure comes from RFC 3454 section 6 bidi rules being
 * violated by the surrounding Latin letters, not from the code point itself.
 */
public class IdnReject2 {
    static boolean fails(String label) {
        try { IDN.toASCII(label); return false; }
        catch (RuntimeException e) { return true; }
    }
    static boolean rejects(int cp) {
        String ch = new String(Character.toChars(cp));
        return fails(ch) && fails("a" + ch + "b");
    }
    public static void main(String[] a) {
        int start = -1;
        StringBuilder sb = new StringBuilder();
        for (int cp = 0; cp <= 0x10FFFF; cp++) {
            if (cp >= 0xD800 && cp <= 0xDFFF) continue;
            boolean bad = rejects(cp);
            if (bad && start < 0) start = cp;
            if (!bad && start >= 0) { sb.append(start).append(',').append(cp - 1).append('\n'); start = -1; }
        }
        if (start >= 0) sb.append(start).append(',').append(0x10FFFF).append('\n');
        System.out.print(sb);
    }
}
