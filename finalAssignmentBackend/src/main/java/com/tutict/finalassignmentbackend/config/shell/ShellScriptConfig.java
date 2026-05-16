package com.tutict.finalassignmentbackend.config.shell;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;

import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@Configuration
@Profile("dev")
public class ShellScriptConfig {

    private static final Logger logger = LoggerFactory.getLogger(ShellScriptConfig.class);
    private static final String LOG_FILE = "startup_script.log";
    private static final int MAX_RETRIES = 3;
    private static final long TIMEOUT_MINUTES = 5;
    private static final long DOCKER_DESKTOP_STARTUP_TIMEOUT_SECONDS = 180;

    @Value("${app.docker.startup-script.enabled:false}")
    private boolean dockerStartupScriptEnabled;

    @Value("${app.docker.desktop.path:C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe}")
    private String dockerDesktopPath;

    @Value("${app.ollama.startup-script.enabled:false}")
    private boolean ollamaStartupScriptEnabled;

    @Bean
    public CommandLineRunner runStartupScripts() {
        return _ -> {
            ExecutorService executor = Executors.newSingleThreadExecutor();
            try {
                if (ollamaStartupScriptEnabled) {
                    startOllama(executor);
                }
            } finally {
                executor.shutdown();
            }
        };
    }

    @Bean
    public static BeanFactoryPostProcessor dockerDesktopStartupBootstrap(Environment environment) {
        return beanFactory -> {
            boolean enabled = Boolean.parseBoolean(
                environment.getProperty("app.docker.startup-script.enabled", "false"));
            if (!enabled || !isDevProfileActive(environment)) {
                return;
            }

            String os = System.getProperty("os.name").toLowerCase(Locale.ROOT);
            if (!os.startsWith("windows")) {
                logger.info("Docker startup script is intended for Windows Docker Desktop. Current OS: {}", os);
                return;
            }

            String desktopPath = environment.getProperty(
                "app.docker.desktop.path",
                "C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe");

            try {
                ensureDockerDesktopReady(desktopPath);
                Path script = writeDockerStartupScript(desktopPath);
                executeScriptOnce(script.toString(), os);
                logger.info("Docker Desktop startup bootstrap completed: {}", script);
            } catch (IOException e) {
                throw new IllegalStateException("Failed to prepare Docker startup script", e);
            }
        };
    }

    private void startDockerDesktopServices(ExecutorService executor) throws IOException {
        String os = System.getProperty("os.name").toLowerCase(Locale.ROOT);
        if (!os.startsWith("windows")) {
            logger.info("Docker startup script is intended for Windows Docker Desktop. Current OS: {}", os);
            return;
        }

        ensureDockerDesktopReady();
        Path script = writeDockerStartupScript(dockerDesktopPath);
        executeScriptWithRetry(script.toString(), os, executor);
        logger.info("Docker Desktop startup script executed: {}", script);
    }

    private static Path writeDockerStartupScript(String dockerDesktopPath) throws IOException {
        Path dockerDir = Path.of(System.getProperty("user.dir"), "target", "dev-docker");
        Files.createDirectories(dockerDir);

        Path composeFile = dockerDir.resolve("docker-compose.yml");
        Path scriptFile = dockerDir.resolve("start-dev-docker.cmd");

        Files.writeString(composeFile, dockerComposeContent(), StandardCharsets.UTF_8);
        Files.writeString(scriptFile, windowsDockerStartupScript(composeFile, dockerDesktopPath), StandardCharsets.UTF_8);

        logger.info("Docker compose file written to {}", composeFile);
        logger.info("Docker startup script written to {}", scriptFile);
        return scriptFile;
    }

    private static String windowsDockerStartupScript(Path composeFile, String dockerDesktopPath) {
        return """
            @echo off
            setlocal
            docker info >nul 2>&1
            if errorlevel 1 (
              echo Docker Desktop is not running. Starting Docker Desktop...
              if not exist "%s" (
                echo Docker Desktop executable not found.
                exit /b 1
              )
              start "" "%s"
              for /l %%%%i in (1,1,%d) do (
                docker info >nul 2>&1
                if not errorlevel 1 goto docker_ready
                timeout /t 1 /nobreak >nul
              )
              echo Docker Desktop daemon did not become ready in time.
              exit /b 1
            )
            :docker_ready
            docker compose -f "%s" up -d --wait --wait-timeout 120
            endlocal
            """.formatted(
                dockerDesktopPath,
                dockerDesktopPath,
                DOCKER_DESKTOP_STARTUP_TIMEOUT_SECONDS,
                composeFile.toAbsolutePath());
    }

    private static String dockerComposeContent() {
        return """
            services:
              mysql:
                image: mysql:8.0
                container_name: final-assignment-mysql
                environment:
                  MYSQL_ROOT_PASSWORD: root
                  MYSQL_DATABASE: traffic
                  MYSQL_USER: test
                  MYSQL_PASSWORD: test
                ports:
                  - "3306:3306"
                healthcheck:
                  test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-proot"]
                  interval: 10s
                  timeout: 5s
                  retries: 10

              redis:
                image: redis:7
                container_name: final-assignment-redis
                ports:
                  - "6379:6379"
                healthcheck:
                  test: ["CMD", "redis-cli", "ping"]
                  interval: 10s
                  timeout: 5s
                  retries: 10

              redpanda:
                image: redpandadata/redpanda:v24.1.2
                container_name: final-assignment-redpanda
                command:
                  - redpanda
                  - start
                  - --overprovisioned
                  - --smp
                  - "1"
                  - --memory
                  - 1G
                  - --reserve-memory
                  - 0M
                  - --node-id
                  - "0"
                  - --check=false
                  - --kafka-addr
                  - PLAINTEXT://0.0.0.0:9092
                  - --advertise-kafka-addr
                  - PLAINTEXT://localhost:9092
                ports:
                  - "9092:9092"
                  - "9644:9644"
                healthcheck:
                  test: ["CMD-SHELL", "rpk cluster health | grep -E 'Healthy:.+true'"]
                  interval: 10s
                  timeout: 5s
                  retries: 12

              elasticsearch:
                image: docker.elastic.co/elasticsearch/elasticsearch:8.17.3
                container_name: final-assignment-elasticsearch
                environment:
                  discovery.type: single-node
                  xpack.security.enabled: "false"
                  ES_JAVA_OPTS: -Xms512m -Xmx512m
                ports:
                  - "9200:9200"
                healthcheck:
                  test: ["CMD-SHELL", "curl -fsS http://localhost:9200/_cluster/health || exit 1"]
                  interval: 15s
                  timeout: 10s
                  retries: 12

              manticore:
                image: manticoresearch/manticore:dev
                container_name: final-assignment-manticore
                environment:
                  EXTRA: "1"
                ports:
                  - "9306:9306"
                  - "9308:9308"

            volumes:
              mysql-data:
              redis-data:
            """;
    }

    private void ensureDockerDesktopReady() {
        ensureDockerDesktopReady(dockerDesktopPath);
    }

    private static void ensureDockerDesktopReady(String dockerDesktopPath) {
        if (isDockerDaemonAvailable()) {
            logger.info("Docker Desktop daemon is already available.");
            return;
        }

        startDockerDesktop(dockerDesktopPath);
        waitForDockerDaemon();
    }

    private static boolean isDockerDaemonAvailable() {
        try {
            Process process = new ProcessBuilder("docker", "info").start();
            boolean finished = process.waitFor(30, TimeUnit.SECONDS);
            return finished && process.exitValue() == 0;
        } catch (IOException e) {
            throw new IllegalStateException("Docker CLI was not found. Please install or start Docker Desktop.", e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while checking Docker CLI", e);
        }
    }

    private static void startDockerDesktop(String dockerDesktopPath) {
        Path executable = Path.of(dockerDesktopPath);
        if (!Files.exists(executable)) {
            throw new IllegalStateException("Docker Desktop executable not found: " + executable);
        }

        try {
            logger.info("Starting Docker Desktop: {}", executable);
            new ProcessBuilder(executable.toString()).start();
        } catch (IOException e) {
            throw new IllegalStateException("Failed to start Docker Desktop: " + executable, e);
        }
    }

    private static void waitForDockerDaemon() {
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(DOCKER_DESKTOP_STARTUP_TIMEOUT_SECONDS);
        while (System.nanoTime() < deadline) {
            if (isDockerDaemonAvailable()) {
                logger.info("Docker Desktop daemon is ready.");
                return;
            }
            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException("Interrupted while waiting for Docker Desktop daemon", e);
            }
        }
        throw new IllegalStateException(
            "Docker Desktop daemon did not become ready within "
                + DOCKER_DESKTOP_STARTUP_TIMEOUT_SECONDS + " seconds");
    }

    private static boolean isDevProfileActive(Environment environment) {
        for (String profile : environment.getActiveProfiles()) {
            if ("dev".equalsIgnoreCase(profile)) {
                return true;
            }
        }
        return false;
    }

    private static void executeScriptOnce(String scriptPath, String os) {
        try {
            ProcessBuilder builder = new ProcessBuilder(commandForOs(os, scriptPath));
            builder.redirectErrorStream(true);
            Process process = builder.start();
            captureOutputToLog(process, scriptPath);

            if (!process.waitFor(TIMEOUT_MINUTES, TimeUnit.MINUTES)) {
                process.destroy();
                throw new IllegalStateException("Script execution timed out after " + TIMEOUT_MINUTES + " minutes");
            }
            int exitCode = process.exitValue();
            if (exitCode != 0) {
                throw new IllegalStateException("Script failed with exit code: " + exitCode);
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to execute script: " + scriptPath, e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while executing script: " + scriptPath, e);
        }
    }

    private void startOllama(ExecutorService executor) {
        String os = System.getProperty("os.name").toLowerCase(Locale.ROOT);
        String path = System.getProperty("user.dir");
        String powerShell = path + "/finalAssignmentTools/use_deepseek/run.bat";
        String shell = path + "/finalAssignmentTools/use_deepseek/run.sh";
        String scriptPath;

        if (os.startsWith("windows")) {
            scriptPath = powerShell;
        } else if (os.startsWith("linux") || os.startsWith("mac")) {
            scriptPath = shell;
        } else {
            throw new IllegalStateException("Unsupported operating system: " + os);
        }

        if (!Files.exists(Path.of(scriptPath))) {
            throw new IllegalStateException("Script file not found: " + scriptPath);
        }

        if (isOllamaRunning()) {
            logger.info("Ollama is already running. Skipping script execution.");
            return;
        }

        executeScriptWithRetry(scriptPath, os, executor);
        logger.info("Ollama script scheduled successfully.");
    }

    private boolean isOllamaRunning() {
        try {
            ProcessBuilder pb;
            if (System.getProperty("os.name").toLowerCase(Locale.ROOT).startsWith("windows")) {
                pb = new ProcessBuilder("tasklist");
            } else {
                pb = new ProcessBuilder("ps", "aux");
            }
            Process process = pb.start();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.toLowerCase(Locale.ROOT).contains("ollama")) {
                        return true;
                    }
                }
            }
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.warn("Failed to check Ollama process status", e);
        }
        return false;
    }

    private void executeScriptWithRetry(String scriptPath, String os, ExecutorService executor) {
        int attempt = 0;
        boolean success = false;

        while (attempt < MAX_RETRIES && !success) {
            attempt++;
            logger.info("Attempt {} of {} to execute script: {}", attempt, MAX_RETRIES, scriptPath);

            try {
                ProcessBuilder builder = new ProcessBuilder(commandFor(os, scriptPath));
                builder.redirectErrorStream(true);

                Process process = builder.start();
                executor.submit(() -> captureOutput(process, scriptPath));

                if (!process.waitFor(TIMEOUT_MINUTES, TimeUnit.MINUTES)) {
                    process.destroy();
                    throw new IllegalStateException("Script execution timed out after " + TIMEOUT_MINUTES + " minutes");
                }

                int exitCode = process.exitValue();
                if (exitCode == 0) {
                    logger.info("Script executed successfully: {}", scriptPath);
                    success = true;
                } else if (attempt == MAX_RETRIES) {
                    throw new IllegalStateException("Script failed after " + MAX_RETRIES + " attempts with exit code: " + exitCode);
                } else {
                    logger.error("Script failed with exit code {}: {}", exitCode, scriptPath);
                }
            } catch (IOException | InterruptedException e) {
                if (e instanceof InterruptedException) {
                    Thread.currentThread().interrupt();
                }
                logger.error("Failed to execute script on attempt {}: {}", attempt, scriptPath, e);
                if (attempt == MAX_RETRIES) {
                    throw new IllegalStateException("Failed to execute script after " + MAX_RETRIES + " attempts", e);
                }
            }

            if (!success) {
                sleepBeforeRetry();
            }
        }
    }

    private List<String> commandFor(String os, String scriptPath) {
        return commandForOs(os, scriptPath);
    }

    private static List<String> commandForOs(String os, String scriptPath) {
        List<String> command = new ArrayList<>();
        if (os.startsWith("windows")) {
            command.add("cmd.exe");
            command.add("/c");
        } else {
            command.add("sh");
        }
        command.add(scriptPath);
        return command;
    }

    private void sleepBeforeRetry() {
        try {
            Thread.sleep(5000);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            logger.warn("Interrupted during retry delay", ie);
        }
    }

    private void captureOutput(Process process, String scriptPath) {
        captureOutputToLog(process, scriptPath);
    }

    private static void captureOutputToLog(Process process, String scriptPath) {
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
