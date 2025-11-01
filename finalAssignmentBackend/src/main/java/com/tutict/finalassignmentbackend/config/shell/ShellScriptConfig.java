package com.tutict.finalassignmentbackend.config.shell;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * 启动时执行脚本，用于启动 Ollama
 */
@Configuration
public class ShellScriptConfig {

    private static final Logger logger = LoggerFactory.getLogger(ShellScriptConfig.class);
    private static final String LOG_FILE = "ollama_script.log";
    private static final int MAX_RETRIES = 3;
    private static final long TIMEOUT_MINUTES = 5;

    @Bean
    public CommandLineRunner runShellScript() {
        return _ -> {
            String os = System.getProperty("os.name").toLowerCase();
            String path = System.getProperty("user.dir");
            String powerShell = path + "/finalAssignmentTools/use_deepseek/run.bat";
            String shell = path + "/finalAssignmentTools/use_deepseek/run.sh";
            String scriptPath;

            // 确定脚本路径
            if (os.startsWith("windows")) {
                scriptPath = powerShell;
            } else if (os.startsWith("linux") || os.startsWith("mac")) {
                scriptPath = shell;
            } else {
                logger.error("Unsupported operating system: {}", os);
                throw new RuntimeException("Unsupported operating system: " + os);
            }

            // 检查脚本文件是否存在
            if (!Files.exists(Paths.get(scriptPath))) {
                logger.error("Script file not found: {}", scriptPath);
                throw new RuntimeException("Script file not found: " + scriptPath);
            }

            // 检查 Ollama 进程是否已在运行
            if (isOllamaRunning()) {
                logger.info("Ollama is already running. Skipping script execution.");
                return;
            }

            // 使用线程池异步执行脚本
            ExecutorService executor = Executors.newSingleThreadExecutor();
            try {
                executeScriptWithRetry(scriptPath, os, executor);
                logger.info("Ollama script scheduled successfully.");
            } finally {
                executor.shutdown();
            }
        };
    }

    /**
     * 检查 Ollama 进程是否正在运行
     */
    private boolean isOllamaRunning() {
        try {
            ProcessBuilder pb;
            if (System.getProperty("os.name").toLowerCase().startsWith("windows")) {
                pb = new ProcessBuilder("tasklist");
            } else {
                pb = new ProcessBuilder("ps", "aux");
            }
            Process process = pb.start();
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.contains("ollama")) {
                    return true;
                }
            }
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            logger.warn("Failed to check Ollama process status", e);
        }
        return false;
    }

    /**
     * 执行脚本，支持重试和超时
     */
    private void executeScriptWithRetry(String scriptPath, String os, ExecutorService executor) {
        int attempt = 0;
        boolean success = false;

        while (attempt < MAX_RETRIES && !success) {
            attempt++;
            logger.info("Attempt {} of {} to execute script: {}", attempt, MAX_RETRIES, scriptPath);

            try {
                // 构建脚本执行命令
                ProcessBuilder builder;
                if (os.startsWith("windows")) {
                    builder = new ProcessBuilder("cmd.exe", "/c", scriptPath);
                } else {
                    builder = new ProcessBuilder("sh", scriptPath);
                }
                builder.redirectErrorStream(true); // 合并标准输出和错误输出

                // 启动进程
                Process process = builder.start();

                // 异步读取输出
                executor.submit(() -> captureOutput(process, scriptPath));

                // 等待进程完成或超时
                if (!process.waitFor(TIMEOUT_MINUTES, TimeUnit.MINUTES)) {
                    process.destroy();
                    logger.error("Script execution timed out after {} minutes: {}", TIMEOUT_MINUTES, scriptPath);
                    throw new RuntimeException("Script execution timed out");
                }

                int exitCode = process.exitValue();
                if (exitCode == 0) {
                    logger.info("Script executed successfully: {}", scriptPath);
                    success = true;
                } else {
                    logger.error("Script failed with exit code {}: {}", exitCode, scriptPath);
                    if (attempt == MAX_RETRIES) {
                        throw new RuntimeException("Script failed after " + MAX_RETRIES + " attempts with exit code: " + exitCode);
                    }
                }
            } catch (IOException | InterruptedException e) {
                logger.error("Failed to execute script on attempt {}: {}", attempt, scriptPath, e);
                if (attempt == MAX_RETRIES) {
                    throw new RuntimeException("Failed to execute script after " + MAX_RETRIES + " attempts", e);
                }
            }

            // 重试前等待
            if (!success) {
                try {
                    Thread.sleep(5000); // 等待 5 秒
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    logger.warn("Interrupted during retry delay", ie);
                }
            }
        }
    }

    /**
     * 捕获脚本输出并记录到日志文件
     */
    private void captureOutput(Process process, String scriptPath) {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));

            FileWriter writer = new FileWriter(LOG_FILE, true)) {
            String line;
            while ((line = reader.readLine()) != null) {
                logger.info("[Script Output] {}: {}", scriptPath, line);
                writer.write(line + System.lineSeparator());
                writer.flush();
            }
        } catch (IOException e) {
            logger.error("Failed to capture script output: {}", scriptPath, e);
        }
    }
}