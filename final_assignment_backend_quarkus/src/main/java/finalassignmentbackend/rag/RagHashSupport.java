package finalassignmentbackend.rag;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/**
 * RAG 主键的稳定生成。
 *
 * <p>Spring / Go / Quarkus 三个后端共用同一套 {@code rag_document} / {@code rag_chunk} 表，
 * 主键算法必须完全一致，否则同一个文档会在不同后端上产生不同的行。
 */
public final class RagHashSupport {

    private static final String DELIMITER = "\u001F";

    private RagHashSupport() {
    }

    public static String stableId(String prefix, String... parts) {
        return prefix + "_" + sha256Hex(String.join(DELIMITER, parts)).substring(0, 32);
    }

    private static String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 is not available", error);
        }
    }
}
