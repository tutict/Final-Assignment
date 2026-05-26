package com.tutict.finalassignmentcloud.ai.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.ai.config.ai.chat.GraalPyContext;
import jakarta.annotation.PreDestroy;
import org.graalvm.polyglot.PolyglotException;
import org.graalvm.polyglot.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.UnsupportedEncodingException;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

@Service
public class AIChatSearchService {

    private static final Logger log = LoggerFactory.getLogger(AIChatSearchService.class);

    private final GraalPyContext graalPyContext;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final long timeoutSeconds;
    private volatile boolean pythonReady = false;

    public AIChatSearchService(
            GraalPyContext graalPyContext,
            @org.springframework.beans.factory.annotation.Value("${ai.search.timeout-seconds:30}") long timeoutSeconds
    ) {
        this.graalPyContext = graalPyContext;
        this.timeoutSeconds = timeoutSeconds;
    }

    public List<Map<String, String>> search(String query) {
        if (query == null || query.trim().isEmpty()) {
            return Collections.emptyList();
        }
        ensurePythonReady();
        if (!pythonReady) {
            log.warn("Web search unavailable, returning empty results");
            return Collections.emptyList();
        }
        try {
            return searchWithGraalPy(query);
        } catch (Exception e) {
            log.warn("GraalPy web search failed for query='{}': {}", query, e.getMessage());
            return Collections.emptyList();
        }
    }

    private synchronized void ensurePythonReady() {
        if (pythonReady || !graalPyContext.isAvailable()) {
            return;
        }
        try {
            graalPyContext.eval(
                    """
                            import json
                            from baidu_crawler import search
                            """
            );
            pythonReady = true;
            log.info("GraalPy Python initialized for baidu_crawler.search");
        } catch (PolyglotException e) {
            log.warn("Python baidu_crawler import failed: {}", e.getMessage());
        } catch (Exception e) {
            log.warn("GraalPy initialization failed: {}", e.getMessage());
        }
    }

    private List<Map<String, String>> searchWithGraalPy(String query) throws Exception {
        String gbkQuery;
        try {
            gbkQuery = new String(query.getBytes("GBK"), "GBK").replace("'", "\\'");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException("Query encoding failed: " + e.getMessage(), e);
        }

        String pythonCode = String.format(
                """
                        import json
                        from baidu_crawler import search
                        res = search('%s', num_results=15, debug=False)
                        json.dumps(res, ensure_ascii=False)
                        """,
                gbkQuery
        );

        Future<Value> future = executor.submit(() -> graalPyContext.eval(pythonCode));
        Value pyResult;
        try {
            pyResult = future.get(timeoutSeconds, TimeUnit.SECONDS);
        } catch (TimeoutException e) {
            future.cancel(true);
            throw new RuntimeException("Web search timed out", e);
        } catch (ExecutionException e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            throw new RuntimeException("Web search execution failed: " + cause.getMessage(), cause);
        }

        if (!pyResult.isString()) {
            throw new RuntimeException("Web search returned non-string JSON: " + pyResult);
        }

        return objectMapper.readValue(
                pyResult.asString(),
                new TypeReference<>() {
                }
        );
    }

    @PreDestroy
    public void shutdown() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}
