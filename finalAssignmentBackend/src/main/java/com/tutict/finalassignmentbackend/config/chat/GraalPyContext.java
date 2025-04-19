package com.tutict.finalassignmentbackend.config.chat;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Value;
import org.springframework.stereotype.Component;

import java.io.File;

/**
 * 用于 GraalVM 配置 python 虚拟环境地址
 */
@Component
public class GraalPyContext {
    private final Context context;

    public GraalPyContext() {
        try {
            // 获取项目根目录
            String projectRoot = System.getProperty("user.dir");
            // 读取 target 目录路径
            File targetDir = new File(projectRoot, "finalAssignmentBackend/target");
            // 读取 venv 目录路径
            File venvDir = new File(targetDir, "classes/org.graalvm.python.vfs/venv");

            // 验证目录是否存在
            if (!venvDir.exists()) {
                throw new RuntimeException("venv directory does not exist: " + venvDir.getAbsolutePath());
            }

            // 读取 PythonPath 和 Executable 路径
            String pythonPath = new File(venvDir, "lib/python3.11/site-packages").getAbsolutePath();
            String executablePath = new File(venvDir, "Scripts/graalpy.exe").getAbsolutePath();

            // 配置 GraalPy Context
            context = Context.newBuilder("python")
                    .option("python.PythonPath", pythonPath)
                    .option("python.Executable", executablePath)
                    .allowAllAccess(true)
                    .build();
        } catch (Exception e) {
            throw new RuntimeException("Failed to initialize GraalPy context: " + e.getMessage(), e);
        }
    }

    public Value eval(String source) {
        return context.eval("python", source);
    }
}