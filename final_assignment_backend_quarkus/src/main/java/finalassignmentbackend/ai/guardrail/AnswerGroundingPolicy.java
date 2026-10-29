package finalassignmentbackend.ai.guardrail;

import finalassignmentbackend.rag.service.RagQueryService;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 输出护栏：无引用不回答。
 *
 * <p>当一次问答命中了知识库检索时，回答必须显式引用检索到的来源（形如 {@code [1]} 的序号，
 * 或来源标识/标题）。否则视为"无依据回答"，用安全兜底文本替换，避免模型凭空编造。
 *
 * <p>Quarkus 默认关闭（{@code ai.guardrail.citation-enforcement.enabled=false}），因为该模块
 * 的对话链路尚未通过 RAGAS 校准；需要拒答行为时显式开启。文本清洗不受该开关影响。
 */
@ApplicationScoped
public class AnswerGroundingPolicy {

    public static final String NO_SOURCE_ANSWER =
            "抱歉，当前知识库中没有可支撑该问题的资料，我无法给出有依据的回答。请补充更多信息或联系人工客服。";
    public static final String UNCITED_ANSWER =
            "抱歉，我无法为该问题提供有可靠来源支撑的回答。";

    // Accept half-width [1] and full-width 【1】 markers, including grouped forms such as
    // [1,2] and [1，2] that models emit when a sentence is supported by several sources.
    private static final Pattern NUMERIC_CITATION =
            Pattern.compile("[\\[【](\\d{1,2}(?:\\s*[,，]\\s*\\d{1,2})*)[\\]】]");

    @ConfigProperty(name = "ai.guardrail.citation-enforcement.enabled", defaultValue = "false")
    boolean enforcementEnabled;

    public AnswerGroundingPolicy() {
    }

    public AnswerGroundingPolicy(boolean enforcementEnabled) {
        this.enforcementEnabled = enforcementEnabled;
    }

    public boolean isEnforcementEnabled() {
        return enforcementEnabled;
    }

    /**
     * 对最终回答做引用强制判定。
     *
     * @param answer  模型产出的回答文本
     * @param sources 本次问答实际放入提示词的来源
     */
    public GroundingDecision evaluate(String answer, List<RagQueryService.RetrievedChunk> sources) {
        if (!enforcementEnabled) {
            return GroundingDecision.allowed(answer);
        }
        if (answer == null || answer.isBlank()) {
            return GroundingDecision.allowed(answer);
        }
        if (sources == null || sources.isEmpty()) {
            return GroundingDecision.refused(NO_SOURCE_ANSWER, "no_sources");
        }
        if (hasCitation(answer, sources)) {
            return GroundingDecision.allowed(answer);
        }
        return GroundingDecision.refused(UNCITED_ANSWER, "missing_citation");
    }

    private static boolean hasCitation(String answer, List<RagQueryService.RetrievedChunk> sources) {
        Matcher matcher = NUMERIC_CITATION.matcher(answer);
        while (matcher.find()) {
            for (String part : matcher.group(1).split("[,，]")) {
                String digits = part.trim();
                if (digits.isEmpty()) {
                    continue;
                }
                int index = Integer.parseInt(digits);
                if (index >= 1 && index <= sources.size()) {
                    return true;
                }
            }
        }
        String lowered = answer.toLowerCase(Locale.ROOT);
        for (RagQueryService.RetrievedChunk source : sources) {
            if (containsIdentifier(lowered, source.sourceId())
                    || containsIdentifier(lowered, source.documentId())
                    || containsIdentifier(lowered, source.title())) {
                return true;
            }
        }
        return false;
    }

    private static boolean containsIdentifier(String loweredAnswer, String candidate) {
        if (candidate == null) {
            return false;
        }
        String needle = candidate.trim().toLowerCase(Locale.ROOT);
        // Only treat *distinctive* identifiers as citations. A bare row id such as "12" or "7"
        // would otherwise match almost any answer that happens to contain those digits, letting
        // an uncited answer pass. Han titles are meaningful from two characters; Latin
        // identifiers must be longer and contain at least one letter (e.g. "doc-1").
        if (!isDistinctive(needle)) {
            return false;
        }
        return loweredAnswer.contains(needle);
    }

    private static boolean isDistinctive(String needle) {
        if (needle.length() < 2) {
            return false;
        }
        boolean han = false;
        boolean letter = false;
        for (int i = 0; i < needle.length(); i++) {
            char character = needle.charAt(i);
            if (Character.UnicodeScript.of(character) == Character.UnicodeScript.HAN) {
                han = true;
            }
            if (Character.isLetter(character)) {
                letter = true;
            }
        }
        if (han) {
            return true;
        }
        return letter && needle.length() >= 4;
    }
}
