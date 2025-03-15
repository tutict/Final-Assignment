package com.tutict.finalassignmentbackend.config.ai;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Value;
import org.springframework.stereotype.Component;

@Component
public class GraalPyContext {
    private final Context context;

    public GraalPyContext() {
        String venvPath = "C:\\Users\\16237\\IdeaProjects\\Final-Assignment\\finalAssignmentBackend\\target\\classes\\org.graalvm.python.vfs\\venv";
        context = Context.newBuilder("python")
                .option("python.PythonPath", venvPath + "\\Lib\\site-packages")
                .option("python.Executable", venvPath + "\\Scripts\\graalpy.exe")
                .allowAllAccess(true)
                .build();
    }

    public Value eval(String source) {
        return context.eval("python", source);
    }
}