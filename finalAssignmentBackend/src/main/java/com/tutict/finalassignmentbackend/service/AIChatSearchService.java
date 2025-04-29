package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.ai.chat.GraalPyContext;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.graalvm.polyglot.PolyglotException;
import org.graalvm.polyglot.Value;

import java.io.UnsupportedEncodingException;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;

@Service
public class AIChatSearchService {
    private static final Logger logger = LoggerFactory.getLogger(AIChatSearchService.class);
    private final GraalPyContext graalPyContext;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public AIChatSearchService(GraalPyContext context) {
        this.graalPyContext = context;
        try {
            graalPyContext.eval(
                    "import json\n" +
                            "from baidu_crawler import search\n"
            );
            logger.info("GraalPy Python 环境已就绪，模块 baidu_crawler.search 可用");
        } catch (PolyglotException e) {
            logger.error("无法导入 baidu_crawler.search: {}\nPython stacktrace: {}", e.getMessage(), e.getPolyglotStackTrace(), e);
            throw new RuntimeException("无法初始化 AIChatSearchService: " + e.getMessage(), e);
        } catch (Exception e) {
            logger.error("初始化 GraalPy 环境失败: {}", e.getMessage(), e);
            throw new RuntimeException("无法初始化 AIChatSearchService: " + e.getMessage(), e);
        }
    }

    public List<Map<String, String>> search(String query) {
        if (query == null || query.trim().isEmpty()) {
            logger.warn("搜索 query 为空，直接返回空列表");
            return Collections.emptyList();
        }
        try {
            List<Map<String, String>> results = searchWithGraalPy(query);
            for (int i = 0; i < results.size(); i++) {
                Map<String, String> item = results.get(i);
                String title = item.getOrDefault("title", "<无标题>");
                String abstractText = item.getOrDefault("abstract", "<无摘要>");
                logger.info("搜索结果 {}: 标题=\"{}\", 摘要=\"{}\"", i + 1, title, abstractText);
            }
            logger.info("搜索完成，query='{}'，共 {} 条结果", query, results.size());
            return results;
        } catch (Exception e) {
            logger.error("GraalPy 搜索失败，query='{}': {}", query, e.getMessage(), e);
            throw new RuntimeException("GraalPy 搜索失败: " + e.getMessage(), e);
        }
    }

    private List<Map<String, String>> searchWithGraalPy(String query) throws Exception {
        // Encode query to GBK
        String gbkQuery;
        try {
            gbkQuery = new String(query.getBytes("GBK"), "GBK").replace("'", "\\'");
            logger.debug("GBK 编码后的 query: {}", gbkQuery);
        } catch (UnsupportedEncodingException e) {
            logger.error("无法将 query 编码为 GBK: {}", query, e);
            throw new RuntimeException("查询编码失败: " + e.getMessage(), e);
        }

        // Construct Python script
        String pythonCode = String.format(
                "import json\n" +
                        "from baidu_crawler import search\n" +
                        "res = search('%s', num_results=15, debug=True)\n" +
                        "json.dumps(res, ensure_ascii=False)\n",
                gbkQuery
        );

        logger.debug("执行 GraalPy 脚本: {}", pythonCode);

        // Execute Python script
        Future<Value> future = executor.submit(() -> graalPyContext.eval(pythonCode));
        Value pyResult;
        try {
            pyResult = future.get(5, TimeUnit.MINUTES);
        } catch (TimeoutException e) {
            logger.error("GraalPy 执行超时，query='{}'", query, e);
            throw new RuntimeException("搜索超时: " + e.getMessage(), e);
        } catch (ExecutionException e) {
            logger.error("GraalPy 执行失败，query='{}': {}", query, e.getCause().getMessage(), e);
            throw new RuntimeException("搜索执行失败: " + e.getCause().getMessage(), e.getCause());
        }

        if (!pyResult.isString()) {
            logger.error("GraalPy 返回非字符串结果: {}", pyResult);
            throw new RuntimeException("预期 JSON 字符串，但得到: " + pyResult);
        }

        String json = pyResult.asString();
        logger.debug("从 Python 收到 JSON: {}", json);

        // Deserialize JSON
        List<Map<String, String>> results;
        try {
            results = objectMapper.readValue(
                    json,
                    new TypeReference<List<Map<String, String>>>() {
                    }
            );
            // Convert GBK-encoded fields to UTF-8
            for (Map<String, String> result : results) {
                result.replaceAll((key, value) -> {
                    try {
                        // Try UTF-8 first, fall back to GBK if invalid
                        byte[] bytes = value.getBytes("UTF-8");
                        String test = new String(bytes, "UTF-8");
                        return test; // If valid UTF-8, use it
                    } catch (Exception e) {
                        try {
                            return new String(value.getBytes("GBK"), "UTF-8");
                        } catch (UnsupportedEncodingException ex) {
                            logger.warn("无法转换字段 {}: {}", key, value, ex);
                            return value;
                        }
                    }
                });
            }
        } catch (Exception e) {
            logger.error("JSON 反序列化失败: {}", json, e);
            throw new RuntimeException("JSON 解析失败: " + e.getMessage(), e);
        }

        return results;
    }

    @PreDestroy
    public void shutdown() {
        try {
            executor.shutdown();
            if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
                logger.warn("ExecutorService 未在 10 秒内终止，强制关闭");
                executor.shutdownNow();
            }
            logger.info("ExecutorService 已成功关闭");
        } catch (InterruptedException e) {
            logger.error("关闭 ExecutorService 时被中断", e);
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}