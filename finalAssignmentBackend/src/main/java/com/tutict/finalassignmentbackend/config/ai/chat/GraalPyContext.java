package com.tutict.finalassignmentbackend.config.ai.chat;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Value;
import org.jetbrains.annotations.NotNull;
import org.springframework.stereotype.Component;

import java.io.File;

@Component
public class GraalPyContext {
    private final Context context;

    public GraalPyContext() {
        try {
            String sitePackagesPath;
            String executablePath;
            // Get project root directory
            String projectRoot = System.getProperty("user.dir");
            // Get target directory path
            File targetDir = new File(projectRoot, "finalAssignmentBackend/target");
            // Get venv directory path
            File venvDir = new File(targetDir, "classes/org.graalvm.python.vfs/venv");
            String os = System.getProperty("os.name").toLowerCase();

            // Verify venv directory exists
            if (!venvDir.exists()) {
                throw new RuntimeException("venv directory does not exist ( Maybe you didn't run maven install ) : " + venvDir.getAbsolutePath());
            }

            if (os.startsWith("windows")) {
                // Get site-packages path
                sitePackagesPath = new File(venvDir, "Lib/site-packages").getAbsolutePath();

            } else if (os.startsWith("linux")) {
                sitePackagesPath = new File(venvDir, "lib/python3.11/site-packages").getAbsolutePath();
            } else {
                throw new RuntimeException("Unsupported operating system: " + os);
            }

            // Get directory containing baidu_crawler.py
            String pythonPath = getString(projectRoot, sitePackagesPath);
            if (os.startsWith("windows")) {
                executablePath = new File(venvDir, "Scripts/graalpy.exe").getAbsolutePath();
            } else if (os.startsWith("linux")) {
                executablePath = new File(venvDir, "Scripts/graalpy.sh").getAbsolutePath();
            } else {
                throw new RuntimeException("Unsupported operating system: " + os);
            }


            // Configure GraalPy Context
            context = Context.newBuilder("python")
                    .option("python.PythonPath", pythonPath)
                    .option("python.Executable", executablePath)
                    .allowAllAccess(true)
                    .build();
        } catch (Exception e) {
            throw new RuntimeException("Failed to initialize GraalPy context: " + e.getMessage(), e);
        }
    }

    private static @NotNull String getString(String projectRoot, String sitePackagesPath) {
        File pythonScriptDir = new File(projectRoot, "finalAssignmentBackend/src/main/resources/python/");
        if (!pythonScriptDir.exists()) {
            throw new RuntimeException("Python script directory does not exist: " + pythonScriptDir.getAbsolutePath());
        }
        String pythonScriptPath = pythonScriptDir.getAbsolutePath();

        // Combine site-packages and script directory paths
        return sitePackagesPath + File.pathSeparator + pythonScriptPath;
    }

    public Value eval(String source) {
        return context.eval("python", source);
    }
}