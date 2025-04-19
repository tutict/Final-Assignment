package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.chat.GraalPyContext;
import jakarta.annotation.PreDestroy;
import org.graalvm.polyglot.PolyglotException;
import org.graalvm.polyglot.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@Service
public class AIChatSearchService {
    private static final Logger logger = LoggerFactory.getLogger(AIChatSearchService.class);
    private final GraalPyContext graalPyContext;
    private static final String PYTHON_MODULE = "baidu_crawler_scrapy";
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private boolean useGraalPy = true;

    public AIChatSearchService(GraalPyContext context) {
        this.graalPyContext = context;
        initializeGraalPy();
    }

    private void initializeGraalPy() {
        try {
            // 获取 Python 资源路径
            URL resourceUrl = getClass().getClassLoader().getResource("python");
            if (resourceUrl == null) {
                logger.error("Python resource directory not found");
                throw new RuntimeException("Python resource directory not found");
            }
            String resourcePath = new File(resourceUrl.toURI()).getAbsolutePath().replace("\\", "/");
            logger.info("Python resource path: {}", resourcePath);

            // 逐行执行初始化代码，调试
            String[] initSteps = {
                    "import sys; import os; os.environ['PYTHONIOENCODING'] = 'gbk'; print('Set PYTHONIOENCODING to gbk')",
                    "print('sys.executable: %s' % sys.executable)",
                    "print('sys.path before: %s' % sys.path)",
                    String.format("sys.path.append('%s'); print('sys.path after: %%s' %% sys.path)", resourcePath),
                    String.format("import %s; print('%s imported successfully')", PYTHON_MODULE, PYTHON_MODULE)
            };

            for (int i = 0; i < initSteps.length; i++) {
                logger.debug("Executing init step {}: {}", i, initSteps[i]);
                try {
                    graalPyContext.eval(initSteps[i]);
                } catch (PolyglotException e) {
                    logger.error("Failed at init step {}: {}", i, e.getMessage(), e);
                    throw new RuntimeException("GraalPy init failed at step " + i + ": " + e.getMessage(), e);
                }
            }

            logger.info("GraalPy initialized with {} in GBK encoding", PYTHON_MODULE);
        } catch (Exception e) {
            logger.error("GraalPy initialization failed, switching to pure Python", e);
            useGraalPy = false; // 回退到纯 Python
        }
    }

    public List<Map<String, String>> search(String query) {
        if (query == null || query.trim().isEmpty()) {
            logger.warn("Search query is empty or null");
            return Collections.emptyList();
        }

        if (useGraalPy) {
            return searchWithGraalPy(query);
        } else {
            return searchWithPurePython(query);
        }
    }

    private List<Map<String, String>> searchWithGraalPy(String query) {
        String searchCode = String.format("""
                from %s import BaiduSpider
                from scrapy.crawler import CrawlerProcess
                from scrapy.utils.project import get_project_settings
                try:
                    settings = get_project_settings()
                    settings.update(BaiduSpider.custom_settings)
                    process = CrawlerProcess(settings)
                    process.crawl(BaiduSpider, query='%s', num_results=20, debug=1)
                    process.start()
                except Exception as e:
                    print('Search failed: %%s' %% str(e))
                    raise
                """, PYTHON_MODULE, query.replace("'", "\\'"));

        logger.debug("Executing GraalPy search code: {}", searchCode);

        try {
            List<Map<String, String>> searchResults = executor.submit(() -> {
                List<Map<String, String>> results = new ArrayList<>();
                Value result = graalPyContext.eval(searchCode);

                if (!result.hasArrayElements()) {
                    logger.error("GraalPy returned non-list value: {}", result);
                    throw new RuntimeException("Expected a list from Python but got: " + result);
                }

                long size = result.getArraySize();
                for (int i = 0; i < size; i++) {
                    Value element = result.getArrayElement(i);
                    if (element.hasMembers()) {
                        results.add(element.as(Map.class));
                    } else {
                        logger.warn("Skipping invalid result element at index {}: {}", i, element);
                    }
                }
                return results;
            }).get(5, TimeUnit.MINUTES);

            logger.info("Search completed for query '{}', found {} results", query, searchResults.size());
            return searchResults;

        } catch (PolyglotException e) {
            logger.error("GraalPy execution error for query '{}': {}", query, e.getMessage(), e);
            throw new RuntimeException("Failed to execute search: " + e.getMessage(), e);
        } catch (Exception e) {
            logger.error("Unexpected error during GraalPy search for query '{}'", query, e);
            throw new RuntimeException("Unexpected error during search: " + e.getMessage(), e);
        }
    }

    private List<Map<String, String>> searchWithPurePython(String query) {
        try {
            String pythonScriptPath = "src/main/resources/python/" + PYTHON_MODULE + ".py";
            ProcessBuilder pb = new ProcessBuilder(
                    "python",
                    pythonScriptPath,
                    "-q", query,
                    "-n", "20",
                    "-d", "1"
            );
            pb.environment().put("PYTHONIOENCODING", "gbk");
            pb.redirectErrorStream(true);
            Process process = pb.start();

            List<Map<String, String>> results = new ArrayList<>();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream(), "GBK"))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    logger.debug("Python output: {}", line);
                }
            }

            int exitCode = process.waitFor();
            if (exitCode != 0) {
                logger.error("Python process exited with code {}", exitCode);
                throw new RuntimeException("Python process failed with exit code " + exitCode);
            }

            logger.info("Pure Python search completed for query '{}', found {} results", query, results.size());
            return results;

        } catch (Exception e) {
            logger.error("Pure Python search failed for query '{}': {}", query, e.getMessage(), e);
            throw new RuntimeException("Pure Python search failed: " + e.getMessage(), e);
        }
    }

    @PreDestroy
    public void shutdown() {
        try {
            executor.shutdown();
            if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
                logger.warn("ExecutorService did not terminate within 10 seconds, forcing shutdown");
                executor.shutdownNow();
            }
            logger.info("ExecutorService shut down successfully");
        } catch (InterruptedException e) {
            logger.error("Interrupted while shutting down ExecutorService", e);
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}