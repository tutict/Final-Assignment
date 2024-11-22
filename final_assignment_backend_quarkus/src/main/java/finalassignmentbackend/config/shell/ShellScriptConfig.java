package finalassignmentbackend.config.shell;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

@ApplicationScoped
public class ShellScriptConfig {

    private static final Logger logger = Logger.getLogger(ShellScriptConfig.class);

    public ShellScriptConfig() { }

    @PostConstruct
    public void executeShellScript() {
        String os = System.getProperty("os.name");
        String path = System.getProperty("user.dir");
        String powerShell = path + "/finalAssignmentTools/use_docker/run.bat";
        String shell = path + "/finalAssignmentTools/use_docker/run.sh";

        ProcessBuilder builder;
        if (os != null && os.toLowerCase().startsWith("windows")) {
            builder = new ProcessBuilder("cmd.exe", "/c", powerShell);
        } else if (os != null && os.toLowerCase().startsWith("linux")) {
            builder = new ProcessBuilder("sh", shell);
        } else {
            logger.warnf("您的%s系统暂时不支持", os);
            return;
        }

        try {
            Process process = builder.start();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    logger.info(line);
                }
            }
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            throw new RuntimeException("Failed to execute shell script", e);
        }
    }
}
