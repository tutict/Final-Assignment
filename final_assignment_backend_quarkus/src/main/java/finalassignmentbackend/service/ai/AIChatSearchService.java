package finalassignmentbackend.service.ai;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.config.ai.chat.GraalPyContext;
import io.quarkus.runtime.ShutdownEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import org.graalvm.polyglot.PolyglotException;
import org.graalvm.polyglot.Value;

import java.io.UnsupportedEncodingException;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;
import java.util.logging.Level;
import java.util.logging.Logger;

// Quarkus服务类，用于执行AI搜索操作，通过GraalPy调用Python脚本
@ApplicationScoped
public class AIChatSearchService {

    // 日志记录器，用于记录搜索操作过程中的信息
    private static final Logger logger = Logger.getLogger(AIChatSearchService.class.getName());

    // 注入GraalPyContext用于执行Python脚本
    @Inject
    GraalPyContext graalPyContext;

    // 注入ObjectMapper用于JSON序列化和反序列化
    @Inject
    ObjectMapper objectMapper;

    // 单线程执行器，用于异步执行Python脚本
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    // 构造函数，初始化GraalPy环境
    public AIChatSearchService() {
        try {
            graalPyContext.eval(
                    "import json\n" +
                            "from baidu_crawler import search\n"
            );
            logger.log(Level.INFO, "GraalPy Python环境已就绪，模块baidu_crawler.search可用");
        } catch (PolyglotException e) {
            logger.log(Level.SEVERE, "无法导入baidu_crawler.search: {0}\nPython stacktrace: {1}", new Object[]{e.getMessage(), e.getPolyglotStackTrace()});
            throw new RuntimeException("无法初始化AIChatSearchService: " + e.getMessage(), e);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "初始化GraalPy环境失败: {0}", e.getMessage());
            throw new RuntimeException("无法初始化AIChatSearchService: " + e.getMessage(), e);
        }
    }

    // 执行搜索操作
    public List<Map<String, String>> search(String query) {
        if (query == null || query.trim().isEmpty()) {
            logger.log(Level.WARNING, "搜索query为空，直接返回空列表");
            return Collections.emptyList();
        }
        try {
            List<Map<String, String>> results = searchWithGraalPy(query);
            for (int i = 0; i < results.size(); i++) {
                Map<String, String> item = results.get(i);
                String title = item.getOrDefault("title", "<无标题>");
                String abstractText = item.getOrDefault("abstract", "<无摘要>");
                logger.log(Level.INFO, "搜索结果 {0}: 标题=\"{1}\", 摘要=\"{2}\"", new Object[]{i + 1, title, abstractText});
            }
            logger.log(Level.INFO, "搜索完成，query='{0}'，共 {1} 条结果", new Object[]{query, results.size()});
            return results;
        } catch (Exception e) {
            logger.log(Level.SEVERE, "GraalPy搜索失败，query='{0}': {1}", new Object[]{query, e.getMessage()});
            throw new RuntimeException("GraalPy搜索失败: " + e.getMessage(), e);
        }
    }

    // 使用GraalPy执行Python搜索脚本
    private List<Map<String, String>> searchWithGraalPy(String query) throws Exception {
        // 将查询编码为GBK
        String gbkQuery;
        try {
            gbkQuery = new String(query.getBytes("GBK"), "GBK").replace("'", "\\'");
            logger.log(Level.FINE, "GBK编码后的query: {0}", gbkQuery);
        } catch (UnsupportedEncodingException e) {
            logger.log(Level.SEVERE, "无法将query编码为GBK: {0}", query);
            throw new RuntimeException("查询编码失败: " + e.getMessage(), e);
        }

        // 构造Python脚本
        String pythonCode = String.format(
                "import json\n" +
                        "from baidu_crawler import search\n" +
                        "res = search('%s', num_results=15, debug=True)\n" +
                        "json.dumps(res, ensure_ascii=False)\n",
                gbkQuery
        );

        logger.log(Level.FINE, "执行GraalPy脚本: {0}", pythonCode);

        // 异步执行Python脚本
        Future<Value> future = executor.submit(() -> graalPyContext.eval(pythonCode));
        Value pyResult;
        try {
            pyResult = future.get(5, TimeUnit.MINUTES);
        } catch (TimeoutException e) {
            logger.log(Level.SEVERE, "GraalPy执行超时，query='{0}'", query);
            throw new RuntimeException("搜索超时: " + e.getMessage(), e);
        } catch (ExecutionException e) {
            logger.log(Level.SEVERE, "GraalPy执行失败，query='{0}': {1}", new Object[]{query, e.getCause().getMessage()});
            throw new RuntimeException("搜索执行失败: " + e.getCause().getMessage(), e.getCause());
        }

        // 验证Python返回结果
        if (!pyResult.isString()) {
            logger.log(Level.SEVERE, "GraalPy返回非字符串结果: {0}", pyResult);
            throw new RuntimeException("预期JSON字符串，但得到: " + pyResult);
        }

        String json = pyResult.asString();
        logger.log(Level.FINE, "从Python收到JSON: {0}", json);

        // 反序列化JSON结果
        List<Map<String, String>> results;
        try {
            results = objectMapper.readValue(
                    json,
                    new TypeReference<List<Map<String, String>>>() {
                    }
            );
            // 将GBK编码的字段转换为UTF-8
            for (Map<String, String> result : results) {
                result.replaceAll((key, value) -> {
                    try {
                        // 首先尝试UTF-8，如果有效则使用
                        byte[] bytes = value.getBytes("UTF-8");
                        String test = new String(bytes, "UTF-8");
                        return test; // 如果是有效的UTF-8，直接使用
                    } catch (Exception e) {
                        try {
                            // 如果UTF-8无效，尝试从GBK转换为UTF-8
                            return new String(value.getBytes("GBK"), "UTF-8");
                        } catch (UnsupportedEncodingException ex) {
                            logger.log(Level.WARNING, "无法转换字段 {0}: {1}", new Object[]{key, value});
                            return value;
                        }
                    }
                });
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "JSON反序列化失败: {0}", json);
            throw new RuntimeException("JSON解析失败: " + e.getMessage(), e);
        }

        return results;
    }

    // 应用关闭时清理资源
    public void shutdown(@Observes ShutdownEvent event) {
        try {
            executor.shutdown();
            if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
                logger.log(Level.WARNING, "ExecutorService未在10秒内终止，强制关闭");
                executor.shutdownNow();
            }
            logger.log(Level.INFO, "ExecutorService已成功关闭");
        } catch (InterruptedException e) {
            logger.log(Level.SEVERE, "关闭ExecutorService时被中断", e);
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}