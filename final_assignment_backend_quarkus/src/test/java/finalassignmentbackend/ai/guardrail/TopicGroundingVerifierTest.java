package finalassignmentbackend.ai.guardrail;

import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.chat.request.ChatRequest;
import dev.langchain4j.model.chat.response.ChatResponse;
import finalassignmentbackend.rag.service.RagQueryService.RetrievedChunk;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TopicGroundingVerifierTest {

    @Test
    void staysDisabledWithoutAJudgeModel() {
        TopicGroundingVerifier verifier = verifier();
        verifier.model = Optional.of("  ");

        assertFalse(verifier.isEnabled());
        assertTrue(verifier.verify("报废流程？", "过户流程 [1]。", knowledgeSources()).grounded());
    }

    @Test
    void refusesWhenTheJudgeSaysTheTopicIsMissing() {
        TopicGroundingVerifier verifier = verifier();
        FakeJudge judge = new FakeJudge("{\"topic_in_sources\":false,\"reason\":\"跑题\"}");
        verifier.judge = judge;

        GroundingDecision decision = verifier.verify("车辆报废流程？", "车辆过户流程 [1]。", knowledgeSources());

        assertFalse(decision.grounded());
        assertEquals("topic_mismatch", decision.reason());
        assertEquals(AnswerGroundingPolicy.NO_SOURCE_ANSWER, decision.answer());
    }

    @Test
    void acceptsABooleanWrappedInProse() {
        TopicGroundingVerifier verifier = verifier();
        verifier.judge = new FakeJudge(
                "判断如下：{\"topic_in_sources\":true,\"reason\":\"一致\"} 完毕");

        assertTrue(verifier.verify("罚款怎么缴？", "十五日内缴纳 [1]。", knowledgeSources()).grounded());
    }

    @Test
    void acceptsAStringVerdict() {
        TopicGroundingVerifier verifier = verifier();
        verifier.judge = new FakeJudge("{\"topic_in_sources\":\"false\",\"reason\":\"跑题\"}");

        assertFalse(verifier.verify("车辆报废流程？", "过户流程 [1]。", knowledgeSources()).grounded());
    }

    @Test
    void failsOpenOnAnUnparseableVerdict() {
        TopicGroundingVerifier verifier = verifier();
        verifier.judge = new FakeJudge("我觉得主题是一致的。");

        assertTrue(verifier.verify("罚款怎么缴？", "十五日内缴纳 [1]。", knowledgeSources()).grounded());
    }

    @Test
    void failsOpenWhenTheJudgeFails() {
        TopicGroundingVerifier verifier = verifier();
        FakeJudge judge = new FakeJudge(null);
        judge.failure = new IllegalStateException("Ollama is down");
        verifier.judge = judge;

        assertTrue(verifier.verify("罚款怎么缴？", "十五日内缴纳 [1]。", knowledgeSources()).grounded());
    }

    @Test
    void skipsWebSearchSources() {
        TopicGroundingVerifier verifier = verifier();
        FakeJudge judge = new FakeJudge("{\"topic_in_sources\":false,\"reason\":\"跑题\"}");
        verifier.judge = judge;
        List<RetrievedChunk> web = List.of(new RetrievedChunk(
                "w1", "web", "https://example.com", "网页摘要", "网页", "WEB_SEARCH", "web_search", 1.0));

        assertTrue(verifier.verify("罚款怎么缴？", "十五日内缴纳 [1]。", web).grounded());
        assertFalse(judge.called);
    }

    @Test
    void skipsCanonicalRefusals() {
        TopicGroundingVerifier verifier = verifier();
        FakeJudge judge = new FakeJudge("{\"topic_in_sources\":false,\"reason\":\"跑题\"}");
        verifier.judge = judge;

        assertTrue(verifier.verify(
                "罚款怎么缴？", AnswerGroundingPolicy.UNCITED_ANSWER, knowledgeSources()).grounded());
        assertFalse(judge.called);
    }

    @Test
    void promptContainsTheNumberedSourcesAndQuestion() {
        TopicGroundingVerifier verifier = verifier();
        FakeJudge judge = new FakeJudge("{\"topic_in_sources\":true,\"reason\":\"一致\"}");
        verifier.judge = judge;

        verifier.verify("罚款怎么缴？", "十五日内缴纳 [1]。", knowledgeSources());

        assertNotNull(judge.lastPrompt);
        assertTrue(judge.lastPrompt.contains("[1] 罚款应在十五日内缴纳。"));
        assertTrue(judge.lastPrompt.contains("问题：罚款怎么缴？"));
        assertTrue(judge.lastPrompt.contains("输出 JSON"));
    }

    private static TopicGroundingVerifier verifier() {
        TopicGroundingVerifier verifier = new TopicGroundingVerifier();
        verifier.enabled = true;
        verifier.model = Optional.of("judge-model");
        verifier.timeout = Duration.ofSeconds(2);
        return verifier;
    }

    private static List<RetrievedChunk> knowledgeSources() {
        return List.of(new RetrievedChunk(
                "c1", "d1", "s1", "罚款应在十五日内缴纳。", "罚款规定", "MANUAL", null, 1.0));
    }

    private static final class FakeJudge implements ChatModel {
        private final String response;
        private RuntimeException failure;
        private boolean called;
        private String lastPrompt;

        private FakeJudge(String response) {
            this.response = response;
        }

        @Override
        public ChatResponse chat(ChatRequest request) {
            called = true;
            lastPrompt = ((UserMessage) request.messages().getFirst()).singleText();
            if (failure != null) {
                throw failure;
            }
            return ChatResponse.builder().aiMessage(AiMessage.from(response)).build();
        }
    }
}
