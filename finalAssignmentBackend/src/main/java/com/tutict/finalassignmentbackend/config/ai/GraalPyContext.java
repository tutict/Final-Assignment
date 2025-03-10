package com.tutict.finalassignmentbackend.config.ai;

import jakarta.annotation.PreDestroy;
import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.PolyglotException;
import org.graalvm.polyglot.Value;
import org.graalvm.python.embedding.utils.GraalPyResources;
import org.springframework.stereotype.Component;

//@Component
public class GraalPyContext {
    static final String PYTHON = "python";

    private final Context context;

    public GraalPyContext() {
        context = GraalPyResources.contextBuilder()
                .allowExperimentalOptions(true)
                .option("python.Executable", "E:\\graalpy\\bin\\python.exe")
                .option("python.WithCachedSources", "true")
                .build();
        context.initialize(PYTHON);
    }

    public Value eval(String source) {
        try {
            Value result = context.eval(PYTHON, source);
            if (result == null) {
                System.err.println("Eval returned null for source: " + source);
            }
            return result;
        } catch (PolyglotException e) {
            System.err.println("PolyglotException occurred while evaluating Python code: " + source);
            System.err.println("Error details: " + e.getMessage());
            e.printStackTrace();
            throw e;
        } catch (Exception e) {
            System.err.println("Unexpected exception during eval: " + source);
            e.printStackTrace();
            throw e;
        }
    }

    @PreDestroy
    public void close() {
        context.close(true);
    }
}