package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.ai.GraalPyContext;
import org.graalvm.polyglot.PolyglotException;
import org.graalvm.polyglot.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.File;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Service
public class AIChatSearchService {
    private static final Logger logger = LoggerFactory.getLogger(AIChatSearchService.class);
    private final GraalPyContext graalPyContext;
    private static final String PYTHON_MODULE = "baidu_crawler";

    public AIChatSearchService(GraalPyContext context) {
        this.graalPyContext = context;
        initializeGraalPy();
    }

    private void initializeGraalPy() {
        try {
            URL resourceUrl = getClass().getClassLoader().getResource("python");
            if (resourceUrl == null) {
                throw new RuntimeException("Python resource directory not found");
            }
            String resourcePath = new File(resourceUrl.toURI()).getAbsolutePath().replace("\\", "\\\\");
            logger.info("Python resource path: {}", resourcePath);

            String debugCode = String.format("""
                    import sys
                    print('sys.executable: %%s' %% sys.executable)
                    print('sys.path before: %%s' %% sys.path)
                    sys.path.append('%s')
                    print('sys.path after: %%s' %% sys.path)
                    import %s
                    print('%s imported successfully')
                    """, resourcePath, PYTHON_MODULE, PYTHON_MODULE);

            graalPyContext.eval(debugCode);
            logger.info("GraalPy initialized with {}", PYTHON_MODULE);
        } catch (Exception e) {
            logger.error("Failed to initialize GraalPy", e);
            throw new RuntimeException("Failed to initialize GraalPy: " + e.getMessage(), e);
        }
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, String>> search(String query) {
        if (query == null || query.trim().isEmpty()) {
            logger.warn("Search query is empty or null");
            return Collections.emptyList();
        }

        // 查询已经是 UTF-8，无需额外转换
        String searchCode = String.format("""
                from %s import search
                search('%s', num_results=20)
                """, PYTHON_MODULE, query.replace("'", "\\'"));

        logger.debug("Executing Python search code: {}", searchCode);

        try {
            Value result = graalPyContext.eval(searchCode);
            logger.debug("GraalPy raw result: {}", result.toString());

            if (!result.hasArrayElements()) {
                logger.error("GraalPy returned non-list value: {}", result.toString());
                throw new RuntimeException("Expected a list from Python but got: " + result.toString());
            }

            List<Map<String, String>> searchResults = new ArrayList<>();
            long size = result.getArraySize();
            for (int i = 0; i < size; i++) {
                Value element = result.getArrayElement(i);
                if (element.hasMembers()) {
                    searchResults.add(element.as(Map.class));
                } else {
                    logger.warn("Skipping invalid result element at index {}: {}", i, element.toString());
                }
            }

            logger.info("Search completed for query '{}', found {} results", query, searchResults.size());
            return searchResults;

        } catch (PolyglotException e) {
            logger.error("GraalPy execution error for query '{}': {}", query, e.getMessage(), e);
            throw new RuntimeException("Failed to execute search: " + e.getMessage(), e);
        } catch (Exception e) {
            logger.error("Unexpected error during search for query '{}'", query, e);
            throw new RuntimeException("Unexpected error during search: " + e.getMessage(), e);
        }
    }
}