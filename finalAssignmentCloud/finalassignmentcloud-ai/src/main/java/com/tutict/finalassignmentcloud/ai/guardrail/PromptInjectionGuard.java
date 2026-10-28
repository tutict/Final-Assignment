package com.tutict.finalassignmentcloud.ai.guardrail;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 最小提示注入护栏：在不可信文本（用户输入、检索到的上下文）进入提示词之前，检测并中和
 * 典型的"指令覆盖"型注入。
 *
 * <p>设计取舍：这里做的是<b>确定性、可测试</b>的规则检测，而不是依赖模型自我防御。命中片段
 * 会被替换为中占位标记，使模型看到的是"数据"而非"指令"。它不追求覆盖全部攻击面，只拦下
 * 最常见、最容易造成越权或提示词泄漏的模式。
 */
@Component
public final class PromptInjectionGuard {

    /** 命中片段被替换成的占位标记。 */
    public static final String NEUTRALIZED_MARKER = "[已过滤的指令性内容]";

    private static final int FLAGS = Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE;

    private static final List<Rule> RULES = List.of(
            new Rule("override_instructions", Pattern.compile(
                    "(ignore|disregard|forget)\\s+(all\\s+)?(the\\s+)?(previous|prior|above|earlier|preceding)\\s+"
                            + "(instructions?|prompts?|rules?|context)", FLAGS)),
            new Rule("override_instructions", Pattern.compile(
                    "(忽略|无视|忘记|不要理会)(以上|上述|之前|前面|先前|所有|全部)(的)?(指令|要求|提示|内容|规则|上下文)")),
            new Rule("reveal_system_prompt", Pattern.compile(
                    "(reveal|show|print|repeat|output|leak)\\s+(me\\s+)?(your\\s+)?(system\\s+)?"
                            + "(prompt|instructions?|rules?)", FLAGS)),
            new Rule("reveal_system_prompt", Pattern.compile(
                    "(输出|打印|泄露|告诉我|重复|展示)(一下)?(你的)?(系统)?(提示词|提示|指令|规则|system\\s*prompt)")),
            new Rule("role_hijack", Pattern.compile("you\\s+are\\s+now\\s+", FLAGS)),
            new Rule("role_hijack", Pattern.compile("(现在你是|从现在开始你是|假装你是)")),
            new Rule("jailbreak", Pattern.compile("(jailbreak|developer\\s+mode|dan\\s+mode)", FLAGS)),
            new Rule("jailbreak", Pattern.compile("(越狱|开发者模式|上帝模式)"))
    );

    /** 扫描文本，返回是否命中、命中特征与中和后的文本。 */
    public InjectionScan scan(String text) {
        if (text == null || text.isBlank()) {
            return InjectionScan.clean(text);
        }
        List<String> signals = new ArrayList<>();
        String sanitized = text;
        for (Rule rule : RULES) {
            Matcher matcher = rule.pattern().matcher(sanitized);
            if (matcher.find()) {
                signals.add(rule.name());
                sanitized = matcher.replaceAll(Matcher.quoteReplacement(NEUTRALIZED_MARKER));
            }
        }
        return new InjectionScan(!signals.isEmpty(), List.copyOf(signals), sanitized);
    }

    /** 只做中和，不关心是否命中。 */
    public String sanitize(String text) {
        return scan(text).sanitized();
    }

    private record Rule(String name, Pattern pattern) {
    }
}
