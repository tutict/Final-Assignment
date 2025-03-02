package com.tutict.finalassignmentbackend.config.shell;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
public class ShellScriptConfig {

    @Bean
    public CommandLineRunner runShellScript() {
        return args -> {
            String os = System.getProperty("os.name").toLowerCase();
            String path = System.getProperty("user.dir");
            String powerShell = path + "/finalAssignmentTools/use_deepseek/run.bat";
            String shell = path + "/finalAssignmentTools/use_deepseek/run.sh";

            ProcessBuilder builder;
            if (os.startsWith("windows")) {
                builder = new ProcessBuilder("cmd.exe", "/c", powerShell);
            } else if (os.startsWith("linux") || os.startsWith("mac")) {
                builder = new ProcessBuilder("sh", shell);
            } else {
                System.out.printf("您的%s系统暂时不支持%n", os);
                return;
            }

            try {
                Process process = builder.start();
                // 等待脚本执行完成
                int exitCode = process.waitFor();
                if (exitCode != 0) {
                    throw new RuntimeException("Shell script failed with exit code: " + exitCode);
                }
                System.out.println("Ollama script completed successfully.");
            } catch (IOException | InterruptedException e) {
                throw new RuntimeException("Failed to execute or wait for shell script", e);
            }
        };
    }
}