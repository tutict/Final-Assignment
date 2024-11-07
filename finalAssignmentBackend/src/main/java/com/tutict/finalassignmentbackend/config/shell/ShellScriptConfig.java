package com.tutict.finalassignmentbackend.config.shell;

import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
public class ShellScriptConfig {

    public ShellScriptConfig() {

        String os = System.getProperty("os.name");
        // 获取当前项目路径
        String path = System.getProperty("user.dir");
        String PowerShell = "." + path + "/finalAssignmentTools/use_docker/run.bat";
        String shell = path + "/finalAssignmentTools/use_docker/run.sh";

        // 判断是否为Windows系统
        if (os != null && os.toLowerCase().startsWith("windows")) {

            ProcessBuilder builder = new ProcessBuilder(PowerShell);

            try {
                Process process = builder.start();
                process.waitFor();
            } catch (IOException | InterruptedException e) {
                throw new RuntimeException(e);
            }

            // 判断是否为Linux系统
        } else if (os != null && os.toLowerCase().startsWith("linux")) {

            ProcessBuilder builder = new ProcessBuilder("sh", shell);

            try {
                Process process = builder.start();
                process.waitFor();
            } catch (IOException | InterruptedException e) {
                throw new RuntimeException(e);
            }

        } else {
            System.out.printf("您的%s系统暂时不支持", os);
        }
    }
}
