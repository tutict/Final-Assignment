package com.tutict.finalassignmentbackend.ai.guardrail;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

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
 * <p>可通过 {@code ai.guardrail.citation-enforcement.enabled} 关闭（默认开启）。
 */
@Component
public class AnswerGroundingPolicy {

    public static final String NO_SOURCE_ANSWER =
            "抱歉，当前知识库中没有可支撑该问题的资料，我无法给出有依据的回答。请补充更多信息或联系人工客服。";
    public static final String UNCITED_ANSWER =
            "抱歉，我无法为该问题提供有可靠来源支撑的回答。";

    private static final Pattern NUMERIC_CITATION = Pattern.compile("\\[(\\d{1,2})]");

    private final boolean enforcementEnabled;

    public AnswerGroundingPolicy(
            @Value("${ai.guardrail.citation-enforcement.enabled:true}") boolean enforcementEnabled
    ) {
        this.enforcementEnabled = enforcementEnabled;
    }

    public boolean isEnforcementEnabled() {
        return enforcementEnabled;
    }

    /**
     * 对最终回答做引用强制判定。
     *
     * @param answer  模型产出的回答文本
     * @param sources 本次问答检索到的来源
     */
    public GroundingDecision evaluate(String answer, List<RetrievalResult> sources) {
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

    private static boolean hasCitation(String answer, List<RetrievalResult> sources) {
        Matcher matcher = NUMERIC_CITATION.matcher(answer);
        while (matcher.find()) {
            int index = Integer.parseInt(matcher.group(1));
            if (index >= 1 && index <= sources.size()) {
                return true;
            }
        }
        String lowered = answer.toLowerCase(Locale.ROOT);
        for (RetrievalResult source : sources) {
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
        return needle.length() >= 2 && loweredAnswer.contains(needle);
    }
}