package com.tutict.finalassignmentbackend.config.shell;

import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
public class ShellScriptConfig {

    @PostConstruct
    public void executeShellScript() {
        String os = System.getProperty("os.name").toLowerCase();
        String path = System.getProperty("user.dir");
        String powerShell = path + "/finalAssignmentTools/use_deepseek/run.bat"; // 更新文件名
        String shell = path + "/finalAssignmentTools/use_deepseek/run.sh";     // 更新文件名

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
            // 异步启动脚本，不等待完成
            Process process = builder.start();
            System.out.println("Ollama script started in background.");
            // 不调用 waitFor() 或读取输出，避免阻塞
        } catch (IOException e) {
            throw new RuntimeException("Failed to execute shell script", e);
        }
    }
}