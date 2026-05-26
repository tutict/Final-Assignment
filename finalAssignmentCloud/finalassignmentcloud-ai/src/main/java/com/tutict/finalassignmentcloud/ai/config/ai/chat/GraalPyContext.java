package com.tutict.finalassignmentcloud.ai.config.ai.chat;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.net.URL;
import java.nio.file.Path;
import java.nio.file.Paths;

@Component
public class GraalPyContext {

    private static final Logger log = LoggerFactory.getLogger(GraalPyContext.class);

    private Context context;
    private volatile boolean initialized = false;

    @PostConstruct
    public void init() {
        try {
            URL venvUrl = getClass().getClassLoader()
                    .getResource("org.graalvm.python.vfs/venv");
            if (venvUrl == null) {
                log.warn("GraalPy venv not found in classpath. Web search will be disabled. Run 'mvn package' to build the venv.");
                return;
            }

            Path venvPath = Paths.get(venvUrl.toURI());
            Context.Builder builder = Context.newBuilder("python")
                    .allowAllAccess(true)
                    .option("python.PythonHome", venvPath.toString());

            URL pythonUrl = getClass().getClassLoader().getResource("python");
            if (pythonUrl != null) {
                builder.option("python.PythonPath", Paths.get(pythonUrl.toURI()).toString());
            }

            context = builder.build();
            initialized = true;
            log.info("GraalPyContext initialized successfully");
        } catch (Exception e) {
            initialized = false;
            context = null;
            log.error("GraalPyContext initialization failed, web search disabled: {}", e.getMessage());
        }
    }

    @PreDestroy
    public void destroy() {
        if (context == null) {
            return;
        }
        try {
            context.close();
            log.info("GraalPyContext closed");
        } catch (Exception e) {
            log.warn("GraalPyContext close failed", e);
        }
    }

    public boolean isAvailable() {
        return initialized && context != null;
    }

    public Context getContext() {
        if (!isAvailable()) {
            throw new IllegalStateException("GraalPy is not available. Web search is disabled.");
        }
        return context;
    }

    public Value eval(String source) {
        return getContext().eval("python", source);
    }
}
