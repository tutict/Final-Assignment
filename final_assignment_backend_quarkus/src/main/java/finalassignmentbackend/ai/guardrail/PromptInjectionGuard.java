package finalassignmentbackend.ai.guardrail;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Minimal prompt-injection guard: neutralizes instruction-override patterns in untrusted text
 * (user input, retrieved passages) before they reach the prompt. Deterministic and testable by
 * design; it covers the most common hijack patterns rather than every possible attack.
 */
public final class PromptInjectionGuard {

    public static final String NEUTRALIZED_MARKER = "[已过滤的指令性内容]";

    private static final int FLAGS = Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE;

    private static final List<Rule> RULES = List.of(
            new Rule("override_instructions", Pattern.compile(
                    "(ignore|disregard|forget|pay\\s+no\\s+attention\\s+to|stop\\s+following|do\\s+not\\s+follow)"
                            + "\\s+(the\\s+|all\\s+)*(previous|prior|above|earlier|preceding)?\\s*(system\\s+)?"
                            + "(instructions?|prompts?|rules?|directives?|context)", FLAGS)),
            new Rule("override_instructions", Pattern.compile(
                    "(忽略|无视|忘记|不要理会|不要遵守|不用遵守|别再遵守)(以上|上述|之前|前面|先前|所有|全部)(的)?"
                            + "(指令|要求|提示|内容|规则|上下文)")),
            new Rule("reveal_system_prompt", Pattern.compile(
                    "(reveal|show|print|repeat|output|leak)\\s+(me\\s+)?(your\\s+)?(system\\s+)?"
                            + "(prompt|instructions?|rules?|directives?)", FLAGS)),
            new Rule("reveal_system_prompt", Pattern.compile(
                    "(输出|打印|泄露|告诉我|重复|展示)(一下)?(你的)?(系统)?(提示词|提示|指令|规则|system\\s*prompt)")),
            new Rule("role_hijack", Pattern.compile("you\\s+are\\s+now\\s+", FLAGS)),
            new Rule("role_hijack", Pattern.compile("(现在你是|从现在开始你是|假装你是)")),
            new Rule("jailbreak", Pattern.compile("(jailbreak|developer\\s+mode|dan\\s+mode)", FLAGS)),
            new Rule("jailbreak", Pattern.compile("(越狱|开发者模式|上帝模式)"))
    );

    public record InjectionScan(boolean suspicious, List<String> signals, String sanitized) {
        public static InjectionScan clean(String text) {
            return new InjectionScan(false, List.of(), text);
        }
    }

    public InjectionScan scan(String text) {
        if (text == null || text.isBlank()) {
            return InjectionScan.clean(text);
        }
        // Match on a normalized copy: full-width letters, NBSP and zero-width joiners cannot
        // smuggle an instruction past the patterns. Unmatched text is returned as-is.
        String candidate = normalizeForMatching(text);
        List<String> signals = new ArrayList<>();
        String sanitized = candidate;
        for (Rule rule : RULES) {
            Matcher matcher = rule.pattern().matcher(sanitized);
            if (matcher.find()) {
                signals.add(rule.name());
                sanitized = matcher.replaceAll(Matcher.quoteReplacement(NEUTRALIZED_MARKER));
            }
        }
        if (signals.isEmpty()) {
            return InjectionScan.clean(text);
        }
        return new InjectionScan(true, List.copyOf(signals), sanitized);
    }

    /** NFKC-folds full-width characters and drops format characters / non-breaking spaces. */
    static String normalizeForMatching(String text) {
        String normalized = Normalizer.normalize(text, Normalizer.Form.NFKC);
        StringBuilder builder = new StringBuilder(normalized.length());
        normalized.codePoints().forEach(codePoint -> {
            if (codePoint == 0x00A0 || codePoint == 0x3000) {
                builder.append(' ');
            } else if (Character.getType(codePoint) != Character.FORMAT) {
                builder.appendCodePoint(codePoint);
            }
        });
        return builder.toString();
    }

    public String sanitize(String text) {
        return scan(text).sanitized();
    }

    private record Rule(String name, Pattern pattern) {
    }
}
