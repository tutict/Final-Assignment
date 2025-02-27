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
                System.out.println("Ollama script started in background.");
            } catch (IOException e) {
                throw new RuntimeException("Failed to execute shell script", e);
            }
        };
    }
}