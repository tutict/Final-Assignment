package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.ai.GraalPyContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.net.URL;
import java.util.List;
import java.util.Map;

@Service
public class AIChatSearchService {
    private static final Logger logger = LoggerFactory.getLogger(AIChatSearchService.class);
    private final GraalPyContext graalPyContext;

    public AIChatSearchService(GraalPyContext context) {
        this.graalPyContext = context;
        try {
            URL resourceUrl = getClass().getClassLoader().getResource("python");
            String resourcePath;
            if (resourceUrl != null) {
                resourcePath = resourceUrl.getPath();
                logger.info("Resource path for python directory: {}", resourcePath);
            } else {
                resourcePath = "src/main/resources/python";
                logger.warn("Python directory not found in classpath, using fallback: {}", resourcePath);
            }

            // 使用 Java 的 String.format 预先格式化，避免 Python 的 % 运算符
            String pythonCode = String.format("""
                    import sys
                    sys.path.append('%s')
                    print('Python sys.path updated with: %s')
                    import baidu_crawler
                    print('Successfully imported baidu_crawler')
                    """, resourcePath, resourcePath);

            graalPyContext.eval(pythonCode);
            logger.info("GraalPy initialized with baidu_crawler");
        } catch (Exception e) {
            logger.error("Failed to initialize GraalPy with baidu_crawler", e);
            throw new RuntimeException("Failed to initialize GraalPy with baidu_crawler: " + e.toString(), e);
        }
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, String>> search(String query) {
        try {
            String searchCode = String.format("""
                    import baidu_crawler
                    results = baidu_crawler.search('%s', num_results=20)
                    """, query.replace("'", "\\'"));
            var value = graalPyContext.eval(searchCode);
            return (List<Map<String, String>>) value.as(List.class);
        } catch (Exception e) {
            logger.error("Failed to execute search for query: {}", query, e);
            throw new RuntimeException("Failed to execute search: " + e.getMessage(), e);
        }
    }
}