package finalassignmentbackend.ai.chat;

import dev.langchain4j.model.chat.StreamingChatModel;
import dev.langchain4j.model.chat.request.ChatRequest;
import dev.langchain4j.model.chat.response.StreamingChatResponseHandler;
import finalassignmentbackend.ai.agent.AgentModels;
import finalassignmentbackend.ai.agent.AgentRuntime;
import finalassignmentbackend.ai.guardrail.AnswerGroundingPolicy;
import finalassignmentbackend.ai.guardrail.GuardrailStage;
import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.service.RagQueryService;
import finalassignmentbackend.rag.service.RagQueryService.RetrievedChunk;
import finalassignmentbackend.reliability.ModelCallBulkhead;
import jakarta.json.bind.Jsonb;
import jakarta.json.bind.JsonbBuilder;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ChatPipelineTest {

    private final Jsonb jsonb = JsonbBuilder.create();
    private final FakeModel model = new FakeModel();
    private final FakeAgent agent = new FakeAgent();
    private final FakeRag rag = new FakeRag();
    private final ChatPipeline pipeline = new ChatPipeline();

    @BeforeEach
    void setUp() {
        pipeline.chatModel = model;
        pipeline.agentRuntime = agent;
        pipeline.ragQueryService = rag;
        pipeline.promptAssembler = new PromptAssembler();
        // Guardrail switches stay off by default here; the refusal tests enable them explicitly.
        pipeline.guardrailStage = new GuardrailStage();
        pipeline.modelCalls = new ModelCallBulkhead();
        pipeline.agentEnabled = true;
        pipeline.ragEnabledByDefault = true;
        pipeline.defaultTopK = 5;
    }

    @Test
    void pureRagTurnStreamsTokensAndDoneWithSingleMessageId() {
        model.tokens = List.of("罚款", "应在十五日内缴纳 [1]。");

        List<Map<String, Object>> events = collect(request("罚款怎么缴？"));

        assertEquals(List.of("token", "token", "done"), types(events));
        assertEquals("罚款应在十五日内缴纳 [1]。", answer(events));
        String messageId = String.valueOf(events.getFirst().get("messageId"));
        assertNotNull(messageId);
        assertTrue(events.stream().allMatch(event -> messageId.equals(event.get("messageId"))));
        assertTrue(events.stream().allMatch(event -> "s1".equals(event.get("sessionKey"))));
    }

    @Test
    void agentAnswerSkipsModelAndRag() {
        agent.events = List.of(event("result", Map.of("ok", true)));

        List<Map<String, Object>> events = collect(request("查一下我的违法记录"));

        assertEquals(List.of("result", "done"), types(events));
        assertFalse(model.called);
        assertFalse(rag.called);
    }

    @Test
    void blankMessageReturnsErrorFrame() {
        List<Map<String, Object>> events = collect(request("   "));

        assertEquals(List.of("error", "done"), types(events));
        assertEquals("message must not be blank", payloadMessage(events.getFirst()));
        assertFalse(model.called);
    }

    @Test
    void sessionOwnedByAnotherUserIsRejected() {
        agent.bound = false;

        List<Map<String, Object>> events = collect(request("你好"));

        assertEquals(List.of("error", "done"), types(events));
        assertEquals("不能使用其他用户的会话", payloadMessage(events.getFirst()));
    }

    @Test
    void requestCanDisableRag() {
        rag.results = List.of(new RetrievedChunk("c1", "d1", "s1", "资料", "标题", "MANUAL", null, 1.0));

        collect(new ChatPipeline.Request("罚款怎么缴？", "s1", "alice", "alice", "USER", null,
                Map.of("ragEnabled", false)));

        assertFalse(rag.called);
        assertTrue(model.called);
    }

    @Test
    void retrievedSourcesArePassedToThePrompt() {
        rag.results = List.of(new RetrievedChunk("c1", "d1", "s1", "罚款应在十五日内缴纳。", "标题", "MANUAL", null, 1.0));

        collect(request("缴纳期限是多久？"));

        assertTrue(model.lastPrompt.contains("<retrieved_context>"));
        assertTrue(model.lastPrompt.contains("[1]\ncontent: 罚款应在十五日内缴纳。"));
    }

    @Test
    void conversationWindowKeepsLastTurns() {
        List<Map<String, Object>> turns = new ArrayList<>();
        for (int i = 1; i <= 12; i++) {
            turns.add(Map.of("role", i % 2 == 0 ? "assistant" : "user", "content", "turn-" + i));
        }

        List<String> window = ChatPipeline.conversationWindow(Map.of("conversationWindow", turns));

        assertEquals(10, window.size());
        assertEquals("user: turn-3", window.getFirst());
        assertEquals("assistant: turn-12", window.getLast());
    }

    @Test
    void uncitedRagAnswerIsRepairedOnceThenRefused() {
        enableCitationEnforcement();
        rag.results = List.of(source());
        model.tokens = List.of("罚款十五日。");

        List<Map<String, Object>> events = collect(request("罚款怎么缴？"));

        assertEquals(2, model.calls.get());
        assertEquals(List.of("token", "done"), types(events));
        assertEquals(AnswerGroundingPolicy.UNCITED_ANSWER, answer(events));
        String messageId = String.valueOf(events.getFirst().get("messageId"));
        assertTrue(events.stream().allMatch(event -> messageId.equals(event.get("messageId"))));
    }

    @Test
    void citationRepairRecoversTheAnswer() {
        enableCitationEnforcement();
        rag.results = List.of(source());
        model.tokens = List.of("罚款十五日。");
        model.retryTokens = List.of("罚款需在十五日内缴纳 [1]。");

        List<Map<String, Object>> events = collect(request("罚款怎么缴？"));

        assertEquals(2, model.calls.get());
        assertEquals("罚款需在十五日内缴纳 [1]。", answer(events));
    }

    @Test
    void emptyRetrievalRefusesWithoutCallingTheRepair() {
        enableCitationEnforcement();
        rag.results = List.of();

        List<Map<String, Object>> events = collect(request("罚款怎么缴？"));

        assertEquals(1, model.calls.get());
        assertEquals(AnswerGroundingPolicy.NO_SOURCE_ANSWER, answer(events));
    }

    @Test
    void retrievalFailureRefusesInsteadOfAnsweringWithoutEvidence() {
        enableCitationEnforcement();
        rag.failure = new IllegalStateException("search backend down");
        model.tokens = List.of("罚款十五日。");

        List<Map<String, Object>> events = collect(request("罚款怎么缴？"));

        assertEquals(1, model.calls.get());
        assertEquals(AnswerGroundingPolicy.NO_SOURCE_ANSWER, answer(events));
    }

    @Test
    void requestCanDisableRagAndBypassTheGuardrail() {
        enableCitationEnforcement();
        model.tokens = List.of("罚款十五日。");

        List<Map<String, Object>> events = collect(new ChatPipeline.Request(
                "罚款怎么缴？", "s1", "alice", "alice", "USER", null, Map.of("ragEnabled", false)));

        assertEquals(1, model.calls.get());
        assertEquals("罚款十五日。", answer(events));
        assertFalse(rag.called);
    }

    @Test
    void retrievalIdentityComesFromTheSessionInsteadOfThePayload() {
        rag.results = List.of(source());

        collect(new ChatPipeline.Request("罚款怎么缴？", "s1", "alice", "alice", "TRAFFIC_POLICE", () -> null,
                Map.of("username", "mallory", "role", "SUPER_ADMIN")));

        assertNotNull(rag.lastContext);
        assertEquals("alice", rag.lastContext.userId());
        assertEquals(Set.of("TRAFFIC_POLICE"), rag.lastContext.roles());
        assertEquals("DEPARTMENT", rag.lastContext.department());
    }

    private void enableCitationEnforcement() {
        pipeline.guardrailStage = new GuardrailStage(new AnswerGroundingPolicy(true), null);
    }

    private static RetrievedChunk source() {
        return new RetrievedChunk("c1", "d1", "s1", "罚款应在十五日内缴纳。", "罚款规定", "MANUAL", null, 1.0);
    }

    private ChatPipeline.Request request(String message) {
        return new ChatPipeline.Request(message, "s1", "alice", "alice", "USER", () -> null, Map.of());
    }

    private List<Map<String, Object>> collect(ChatPipeline.Request request) {
        List<String> frames = pipeline.stream(request).collect().asList()
                .await().atMost(Duration.ofSeconds(5));
        List<Map<String, Object>> events = new ArrayList<>();
        for (String frame : frames) {
            events.add(jsonb.fromJson(frame, LinkedHashMap.class));
        }
        return events;
    }

    @SuppressWarnings("unchecked")
    private static String answer(List<Map<String, Object>> events) {
        StringBuilder text = new StringBuilder();
        for (Map<String, Object> event : events) {
            if ("token".equals(event.get("type"))) {
                text.append(event.get("token"));
            }
        }
        return text.toString();
    }

    private static List<String> types(List<Map<String, Object>> events) {
        return events.stream().map(event -> String.valueOf(event.get("type"))).toList();
    }

    @SuppressWarnings("unchecked")
    private static String payloadMessage(Map<String, Object> event) {
        Object payload = event.get("payload");
        return payload instanceof Map<?, ?> map ? String.valueOf(map.get("message")) : null;
    }

    private static Map<String, Object> event(String type, Object payload) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type", type);
        event.put("payload", payload);
        return event;
    }

    private static final class FakeModel implements StreamingChatModel {
        List<String> tokens = List.of("好");
        List<String> retryTokens;
        final AtomicInteger calls = new AtomicInteger();
        boolean called;
        String lastPrompt;

        @Override
        public void chat(ChatRequest chatRequest, StreamingChatResponseHandler handler) {
            called = true;
            int call = calls.incrementAndGet();
            lastPrompt = ((dev.langchain4j.data.message.UserMessage) chatRequest.messages().getFirst()).singleText();
            List<String> parts = call > 1 && retryTokens != null ? retryTokens : tokens;
            parts.forEach(handler::onPartialResponse);
            handler.onCompleteResponse(null);
        }
    }

    private static final class FakeAgent extends AgentRuntime {
        List<Map<String, Object>> events = List.of();
        boolean bound = true;

        @Override
        public boolean bindSession(String userKey, String sessionKey) {
            return bound;
        }

        @Override
        public List<Map<String, Object>> execute(String message, AgentModels.Context context) {
            return events;
        }
    }

    private static final class FakeRag extends RagQueryService {
        final AtomicInteger calls = new AtomicInteger();
        List<RetrievedChunk> results = List.of();
        RuntimeException failure;
        boolean called;
        RagAccessContext lastContext;

        @Override
        public List<RetrievedChunk> retrieve(String query, RagAccessContext context, int topK) {
            called = true;
            calls.incrementAndGet();
            lastContext = context;
            if (failure != null) {
                throw failure;
            }
            return results;
        }
    }
}
