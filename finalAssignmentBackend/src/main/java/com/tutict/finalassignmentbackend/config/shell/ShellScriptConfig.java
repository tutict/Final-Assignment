package com.tutict.finalassignmentbackend.config.shell;

import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

@Configuration
public class ShellScriptConfig {

    public ShellScriptConfig() {
    }

    @PostConstruct
    public void executeShellScript() {
        String os = System.getProperty("os.name");
        String path = System.getProperty("user.dir");
        String PowerShell = path + "/finalAssignmentTools/use_docker/run.bat";
        String shell = path + "/finalAssignmentTools/use_docker/run.sh";

        ProcessBuilder builder;
        if (os != null && os.toLowerCase().startsWith("windows")) {
            builder = new ProcessBuilder("cmd.exe", "/c", PowerShell);
        } else if (os != null && os.toLowerCase().startsWith("linux")) {
            builder = new ProcessBuilder("sh", shell);
        } else {
            System.out.printf("您的%s系统暂时不支持", os);
            return;
        }

        try {
            Process process = builder.start();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    System.out.println(line);
                }
            }
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            throw new RuntimeException("Failed to execute shell script", e);
        }
    }
}
