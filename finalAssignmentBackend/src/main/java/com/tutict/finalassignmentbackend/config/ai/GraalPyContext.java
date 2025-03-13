package com.tutict.finalassignmentbackend.config.ai;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

@Component
public class GraalPyContext {
    private static final Logger logger = LoggerFactory.getLogger(GraalPyContext.class);
    private final Context context;

    public GraalPyContext() {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ByteArrayOutputStream err = new ByteArrayOutputStream();
        this.context = Context.newBuilder("python")
                .allowAllAccess(true)
                .out(new PrintStream(out)) // 重定向标准输出
                .err(new PrintStream(err)) // 重定向标准错误
                .build();

        // 捕获并记录输出
        context.eval("python", "print('GraalPy context initialized')");
        logger.info("GraalPy stdout: {}", out.toString());
        if (!err.toString().isEmpty()) {
            logger.error("GraalPy stderr: {}", err.toString());
        }
    }

    public Value eval(String code) {
        logger.debug("Executing Python code: {}", code);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ByteArrayOutputStream err = new ByteArrayOutputStream();
        context.getBindings("python").putMember("sys", context.eval("python", "import sys; sys"));
        context.getBindings("python").putMember("sys.stdout", new PrintStream(out));
        context.getBindings("python").putMember("sys.stderr", new PrintStream(err));

        try {
            Value result = context.eval("python", code);
            logger.debug("Python stdout: {}", out.toString());
            if (!err.toString().isEmpty()) {
                logger.error("Python stderr: {}", err.toString());
            }
            return result;
        } catch (Exception e) {
            logger.error("GraalPy execution failed - stdout: {}, stderr: {}", out.toString(), err.toString(), e);
            throw e;
        }
    }
}