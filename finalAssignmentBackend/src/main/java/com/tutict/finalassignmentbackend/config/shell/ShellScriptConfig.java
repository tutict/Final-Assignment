package com.tutict.finalassignmentbackend.config.shell;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

@Configuration
@Profile("dev")
public class ShellScriptConfig {

    private static final Logger logger = LoggerFactory.getLogger(ShellScriptConfig.class);
    private static final int MAX_RETRIES = 3;
    private static final long SCRIPT_TIMEOUT_MINUTES = 5;
    private static final int DOCKER_READY_TIMEOUT_SECONDS = 180;
    private static final int OLLAMA_READY_TIMEOUT_SECONDS = 60;

    public ShellScriptConfig() {
    }

    public static ApplicationContextInitializer<ConfigurableApplicationContext> startupScriptBootstrap() {
        return applicationContext -> {
            Environment environment = applicationContext.getEnvironment();
            if (!isDevProfileActive(environment)) {
                return;
            }

            boolean dockerEnabled = isEnabled(environment, "app.docker.startup-script.enabled");
            boolean ollamaEnabled = isEnabled(environment, "app.ollama.startup-script.enabled");
            if (!dockerEnabled && !ollamaEnabled) {
                logger.info("Local startup scripts are disabled.");
                return;
            }

            Platform platform = Platform.detect();
            Path startupDir = startupDirectory(environment);
            try {
                Files.createDirectories(startupDir);
                Path logFile = startupDir.resolve("startup_script.log");

                if (dockerEnabled) {
                    Path dockerScript = writeDockerScript(platform, startupDir, environment);
                    executeScriptWithRetry(dockerScript, platform, logFile);
                    logger.info("Local Docker environment startup completed by script: {}", dockerScript);
                }

                if (ollamaEnabled) {
                    Path ollamaScript = writeOllamaScript(platform, startupDir, environment);
                    executeScriptWithRetry(ollamaScript, platform, logFile);
                    logger.info("Ollama startup completed by script: {}", ollamaScript);
                }
            } catch (IOException e) {
                throw new IllegalStateException("Failed to prepare local startup scripts in " + startupDir, e);
            }
        };
    }

    private static Path writeDockerScript(Platform platform, Path startupDir, Environment environment) throws IOException {
        Path composeFile = startupDir.resolve("docker-compose.yml");
        Files.writeString(composeFile, dockerComposeContent(environment), StandardCharsets.UTF_8);

        Path script = switch (platform) {
            case WINDOWS -> startupDir.resolve("start-local-docker.cmd");
            case MACOS -> startupDir.resolve("start-local-docker-macos.sh");
            case LINUX -> startupDir.resolve("start-local-docker-linux.sh");
        };

        String scriptContent = switch (platform) {
            case WINDOWS -> windowsDockerScript(composeFile, environment);
            case MACOS -> macosDockerScript(composeFile, environment);
            case LINUX -> linuxDockerScript(composeFile);
        };
        writeScript(script, scriptContent, platform);
        logger.info("Docker compose file written to {}", composeFile);
        logger.info("Docker startup script written to {}", script);
        return script;
    }

    private static Path writeOllamaScript(Platform platform, Path startupDir, Environment environment) throws IOException {
        Path script = switch (platform) {
            case WINDOWS -> startupDir.resolve("start-ollama.cmd");
            case MACOS -> startupDir.resolve("start-ollama-macos.sh");
            case LINUX -> startupDir.resolve("start-ollama-linux.sh");
        };

        String scriptContent = switch (platform) {
            case WINDOWS -> windowsOllamaScript(environment);
            case MACOS, LINUX -> unixOllamaScript();
        };
        writeScript(script, scriptContent, platform);
        logger.info("Ollama startup script written to {}", script);
        return script;
    }

    private static void writeScript(Path script, String content, Platform platform) throws IOException {
        Files.writeString(script, content, StandardCharsets.UTF_8);
        if (!platform.isWindows()) {
            script.toFile().setExecutable(true, true);
        }
    }

    private static String windowsDockerScript(Path composeFile, Environment environment) {
        String dockerDesktopPath = environment.getProperty(
                "app.docker.desktop.path",
                "C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe");
        return """
                @echo off
                setlocal EnableExtensions
                set "DOCKER_DESKTOP_PATH=__DOCKER_DESKTOP_PATH__"
                set "COMPOSE_FILE=__COMPOSE_FILE__"

                where docker >nul 2>&1
                if errorlevel 1 (
                  echo Docker CLI was not found in PATH.
                  exit /b 1
                )

                docker info >nul 2>&1
                if errorlevel 1 (
                  echo Docker daemon is not ready. Starting Docker Desktop...
                  if not exist "%DOCKER_DESKTOP_PATH%" (
                    echo Docker Desktop executable not found: %DOCKER_DESKTOP_PATH%
                    exit /b 1
                  )
                  start "" "%DOCKER_DESKTOP_PATH%"
                )

                for /l %%i in (1,1,__DOCKER_TIMEOUT__) do (
                  docker info >nul 2>&1
                  if not errorlevel 1 goto docker_ready
                  timeout /t 1 /nobreak >nul
                )
                echo Docker daemon did not become ready in time.
                exit /b 1

                :docker_ready
                docker compose -f "%COMPOSE_FILE%" up -d --wait --wait-timeout __DOCKER_TIMEOUT__
                endlocal
                """.replace("__DOCKER_DESKTOP_PATH__", dockerDesktopPath)
                .replace("__COMPOSE_FILE__", composeFile.toAbsolutePath().toString())
                .replace("__DOCKER_TIMEOUT__", Integer.toString(DOCKER_READY_TIMEOUT_SECONDS));
    }

    private static String macosDockerScript(Path composeFile, Environment environment) {
        String dockerAppName = environment.getProperty("app.docker.desktop.macos-app-name", "Docker");
        return unixDockerScript(composeFile, """
                if ! docker info >/dev/null 2>&1; then
                  echo "Docker daemon is not ready. Starting Docker Desktop for macOS..."
                  open -a "__DOCKER_APP_NAME__" || true
                fi
                """.replace("__DOCKER_APP_NAME__", dockerAppName));
    }

    private static String linuxDockerScript(Path composeFile) {
        return unixDockerScript(composeFile, """
                if ! docker info >/dev/null 2>&1; then
                  echo "Docker daemon is not ready. Attempting to start Docker on Linux..."
                  if command -v systemctl >/dev/null 2>&1; then
                    systemctl --user start docker-desktop >/dev/null 2>&1 || true
                    sudo -n systemctl start docker >/dev/null 2>&1 || true
                  fi
                  if command -v service >/dev/null 2>&1; then
                    sudo -n service docker start >/dev/null 2>&1 || true
                  fi
                fi
                """);
    }

    private static String unixDockerScript(Path composeFile, String startDockerBlock) {
        return """
                #!/usr/bin/env sh
                set -eu
                COMPOSE_FILE="__COMPOSE_FILE__"

                if ! command -v docker >/dev/null 2>&1; then
                  echo "Docker CLI was not found in PATH."
                  exit 1
                fi

                __START_DOCKER_BLOCK__

                WAIT_SECONDS=0
                until docker info >/dev/null 2>&1; do
                  if [ "$WAIT_SECONDS" -ge "__DOCKER_TIMEOUT__" ]; then
                    echo "Docker daemon did not become ready in time."
                    exit 1
                  fi
                  sleep 2
                  WAIT_SECONDS=$((WAIT_SECONDS + 2))
                done

                docker compose -f "$COMPOSE_FILE" up -d --wait --wait-timeout __DOCKER_TIMEOUT__
                """.replace("__COMPOSE_FILE__", composeFile.toAbsolutePath().toString())
                .replace("__START_DOCKER_BLOCK__", startDockerBlock)
                .replace("__DOCKER_TIMEOUT__", Integer.toString(DOCKER_READY_TIMEOUT_SECONDS));
    }

    private static String windowsOllamaScript(Environment environment) {
        String ollamaExecutable = environment.getProperty("app.ollama.executable", "ollama");
        return """
                @echo off
                setlocal EnableExtensions
                set "OLLAMA_EXE=__OLLAMA_EXE__"

                if exist "%OLLAMA_EXE%" goto ollama_found
                where "%OLLAMA_EXE%" >nul 2>&1
                if errorlevel 1 (
                  echo Ollama executable was not found in PATH: %OLLAMA_EXE%
                  exit /b 1
                )
                :ollama_found

                powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }"
                if not errorlevel 1 (
                  echo Ollama is already reachable.
                  exit /b 0
                )

                echo Starting Ollama service...
                start "" /B "%OLLAMA_EXE%" serve

                for /l %%i in (1,1,__OLLAMA_TIMEOUT__) do (
                  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }"
                  if not errorlevel 1 goto ollama_ready
                  timeout /t 1 /nobreak >nul
                )
                echo Ollama did not become reachable in time.
                exit /b 1

                :ollama_ready
                echo Ollama is ready.
                endlocal
                """.replace("__OLLAMA_EXE__", ollamaExecutable)
                .replace("__OLLAMA_TIMEOUT__", Integer.toString(OLLAMA_READY_TIMEOUT_SECONDS));
    }

    private static String unixOllamaScript() {
        return """
                #!/usr/bin/env sh
                set -eu

                if ! command -v ollama >/dev/null 2>&1; then
                  echo "Ollama executable was not found in PATH."
                  exit 1
                fi

                if command -v curl >/dev/null 2>&1 && curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
                  echo "Ollama is already reachable."
                  exit 0
                fi

                echo "Starting Ollama service..."
                nohup ollama serve >/tmp/final-assignment-ollama.log 2>&1 &

                WAIT_SECONDS=0
                while true; do
                  if command -v curl >/dev/null 2>&1; then
                    curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && break
                  else
                    ollama list >/dev/null 2>&1 && break
                  fi
                  if [ "$WAIT_SECONDS" -ge "__OLLAMA_TIMEOUT__" ]; then
                    echo "Ollama did not become reachable in time."
                    exit 1
                  fi
                  sleep 2
                  WAIT_SECONDS=$((WAIT_SECONDS + 2))
                done

                echo "Ollama is ready."
                """.replace("__OLLAMA_TIMEOUT__", Integer.toString(OLLAMA_READY_TIMEOUT_SECONDS));
    }

    private static String dockerComposeContent(Environment environment) {
        String redisImage = environment.getProperty("app.docker.images.redis", "redis:7");
        String redpandaImage = environment.getProperty("app.docker.images.redpanda", "redpandadata/redpanda:v24.1.2");
        String elasticsearchImage = environment.getProperty(
                "app.docker.images.elasticsearch",
                "docker.elastic.co/elasticsearch/elasticsearch:9.4.1");

        return """
                services:
                  redis:
                    image: __REDIS_IMAGE__
                    container_name: final-assignment-redis
                    ports:
                      - "6379:6379"
                    volumes:
                      - redis-data:/data
                    healthcheck:
                      test: ["CMD", "redis-cli", "ping"]
                      interval: 10s
                      timeout: 5s
                      retries: 10

                  redpanda:
                    image: __REDPANDA_IMAGE__
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
                    volumes:
                      - redpanda-data:/var/lib/redpanda/data
                    healthcheck:
                      test: ["CMD-SHELL", "rpk cluster health | grep -E 'Healthy:.+true'"]
                      interval: 10s
                      timeout: 5s
                      retries: 12

                  elasticsearch:
                    image: __ELASTICSEARCH_IMAGE__
                    container_name: final-assignment-elasticsearch
                    environment:
                      discovery.type: single-node
                      xpack.security.enabled: "false"
                      ES_JAVA_OPTS: -Xms512m -Xmx512m
                    ports:
                      - "9200:9200"
                    volumes:
                      - elasticsearch-data:/usr/share/elasticsearch/data
                    healthcheck:
                      test: ["CMD-SHELL", "curl -fsS http://localhost:9200/_cluster/health || exit 1"]
                      interval: 15s
                      timeout: 10s
                      retries: 12

                volumes:
                  redis-data:
                  redpanda-data:
                  elasticsearch-data:
                """.replace("__REDIS_IMAGE__", redisImage)
                .replace("__REDPANDA_IMAGE__", redpandaImage)
                .replace("__ELASTICSEARCH_IMAGE__", elasticsearchImage);
    }

    private static void executeScriptWithRetry(Path script, Platform platform, Path logFile) {
        int attempt = 1;
        while (attempt <= MAX_RETRIES) {
            try {
                appendLogHeader(logFile, script, attempt);
                ProcessBuilder builder = new ProcessBuilder(commandFor(platform, script));
                builder.redirectErrorStream(true);
                builder.redirectOutput(ProcessBuilder.Redirect.appendTo(logFile.toFile()));

                logger.info("Executing startup script attempt {}/{}: {}", attempt, MAX_RETRIES, script);
                Process process = builder.start();
                if (!process.waitFor(SCRIPT_TIMEOUT_MINUTES, TimeUnit.MINUTES)) {
                    process.destroyForcibly();
                    throw new IllegalStateException(
                            "Script execution timed out after " + SCRIPT_TIMEOUT_MINUTES + " minutes: " + script);
                }

                int exitCode = process.exitValue();
                if (exitCode == 0) {
                    logger.info("Startup script succeeded: {}", script);
                    return;
                }
                throw new IllegalStateException("Script failed with exit code " + exitCode + ": " + script);
            } catch (IOException e) {
                if (attempt == MAX_RETRIES) {
                    throw new IllegalStateException("Failed to execute startup script: " + script, e);
                }
                logger.warn("Startup script failed on attempt {}/{}: {}", attempt, MAX_RETRIES, script, e);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException("Interrupted while executing startup script: " + script, e);
            } catch (RuntimeException e) {
                if (attempt == MAX_RETRIES) {
                    throw e;
                }
                logger.warn("Startup script failed on attempt {}/{}: {}", attempt, MAX_RETRIES, script, e);
            }

            sleepBeforeRetry();
            attempt++;
        }
    }

    private static void appendLogHeader(Path logFile, Path script, int attempt) throws IOException {
        String header = System.lineSeparator()
                + "===== " + script.getFileName() + " attempt " + attempt + " ====="
                + System.lineSeparator();
        Files.writeString(logFile, header, StandardCharsets.UTF_8,
                StandardOpenOption.CREATE, StandardOpenOption.APPEND);
    }

    private static List<String> commandFor(Platform platform, Path script) {
        if (platform.isWindows()) {
            return List.of("cmd.exe", "/c", script.toAbsolutePath().toString());
        }
        return List.of("sh", script.toAbsolutePath().toString());
    }

    private static void sleepBeforeRetry() {
        try {
            TimeUnit.SECONDS.sleep(5);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while waiting to retry startup script", e);
        }
    }

    private static boolean isEnabled(Environment environment, String propertyName) {
        return Boolean.parseBoolean(environment.getProperty(propertyName, "false"));
    }

    private static boolean isDevProfileActive(Environment environment) {
        return Arrays.stream(environment.getActiveProfiles())
                .anyMatch(profile -> "dev".equalsIgnoreCase(profile));
    }

    private static Path startupDirectory(Environment environment) {
        String configured = environment.getProperty("app.startup-script.output-dir");
        if (configured != null && !configured.isBlank()) {
            return Path.of(configured).toAbsolutePath();
        }
        return Path.of(System.getProperty("user.dir"), "target", "dev-startup").toAbsolutePath();
    }

    private enum Platform {
        WINDOWS,
        LINUX,
        MACOS;

        static Platform detect() {
            String osName = System.getProperty("os.name").toLowerCase(Locale.ROOT);
            if (osName.startsWith("windows")) {
                return WINDOWS;
            }
            if (osName.startsWith("mac") || osName.contains("darwin")) {
                return MACOS;
            }
            if (osName.startsWith("linux")) {
                return LINUX;
            }
            throw new IllegalStateException("Unsupported operating system for local startup scripts: " + osName);
        }

        boolean isWindows() {
            return this == WINDOWS;
        }
    }
}
