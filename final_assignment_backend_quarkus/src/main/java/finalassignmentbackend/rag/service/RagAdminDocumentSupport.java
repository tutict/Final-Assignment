package finalassignmentbackend.rag.service;

import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;

import java.util.List;
import java.util.Locale;
import java.util.Set;

public final class RagAdminDocumentSupport {

    private static final Set<String> KNOWLEDGE_SOURCE_TYPES = Set.of("MANUAL", "UPLOAD");
    private static final Set<String> PREVIEW_ROLES = Set.of("USER", "ADMIN", "SUPER_ADMIN");

    private RagAdminDocumentSupport() {
    }

    public static String stitchContent(List<RagChunk> chunks) {
        if (chunks == null || chunks.isEmpty()) {
            return "";
        }
        StringBuilder text = new StringBuilder();
        for (RagChunk chunk : chunks) {
            String content = chunk.getContent() == null ? "" : chunk.getContent();
            if (text.isEmpty()) {
                text.append(content);
                continue;
            }
            int overlap = longestOverlap(text.toString(), content);
            text.append(content.substring(overlap));
        }
        return text.toString();
    }

    public static String normalizePreviewRole(String asRole) {
        String normalized = asRole == null ? "" : asRole.trim().toUpperCase(Locale.ROOT);
        if ("DRIVER".equals(normalized)) {
            return "USER";
        }
        return PREVIEW_ROLES.contains(normalized) ? normalized : "USER";
    }

    public static boolean isKnowledgeDocument(RagDocument document) {
        if (document == null) {
            return false;
        }
        String sourceType = document.getSourceType() == null ? "" : document.getSourceType().trim().toUpperCase(Locale.ROOT);
        return KNOWLEDGE_SOURCE_TYPES.contains(sourceType);
    }

    public static boolean previewAllows(String asRole, String aclScope) {
        String role = normalizePreviewRole(asRole);
        String scope = aclScope == null || aclScope.isBlank() ? "PUBLIC" : aclScope.trim().toUpperCase(Locale.ROOT);
        return switch (scope) {
            case "PUBLIC" -> true;
            case "ROLE", "DEPARTMENT" -> "ADMIN".equals(role) || "SUPER_ADMIN".equals(role);
            case "USER" -> "USER".equals(role) || "SUPER_ADMIN".equals(role);
            default -> "SUPER_ADMIN".equals(role);
        };
    }

    public static double keywordScore(String query, String title, String content) {
        String needle = query == null ? "" : query.trim().toLowerCase(Locale.ROOT);
        if (needle.isBlank()) {
            return 0;
        }
        String titleText = title == null ? "" : title.toLowerCase(Locale.ROOT);
        String body = content == null ? "" : content.toLowerCase(Locale.ROOT);
        double score = 0;
        if (titleText.contains(needle)) {
            score += 2.0;
        }
        int from = 0;
        int hits = 0;
        while (hits < 20) {
            int index = body.indexOf(needle, from);
            if (index < 0) {
                break;
            }
            hits++;
            from = index + needle.length();
        }
        score += Math.min(3.0, hits * 0.5);
        return score;
    }

    public static String snippet(String content, int maxChars) {
        if (content == null) {
            return "";
        }
        String normalized = content.replaceAll("\\s+", " ").trim();
        int limit = Math.max(40, maxChars);
        return normalized.length() <= limit ? normalized : normalized.substring(0, limit) + "...";
    }

    static int longestOverlap(String left, String right) {
        if (left == null || right == null || left.isEmpty() || right.isEmpty()) {
            return 0;
        }
        int max = Math.min(left.length(), right.length());
        for (int size = max; size > 0; size--) {
            if (left.regionMatches(left.length() - size, right, 0, size)) {
                return size;
            }
        }
        return 0;
    }
}
