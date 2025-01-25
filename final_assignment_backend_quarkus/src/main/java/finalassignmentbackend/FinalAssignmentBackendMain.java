package finalassignmentbackend;

import io.quarkus.runtime.Quarkus;
import io.quarkus.runtime.QuarkusApplication;
import io.quarkus.runtime.annotations.QuarkusMain;

import java.util.logging.Logger;


// 使用Quarkus应用程序注解
@QuarkusMain
public class FinalAssignmentBackendMain implements QuarkusApplication {

    private static final Logger logger = Logger.getLogger(String.valueOf(FinalAssignmentBackendMain.class));

    @Override
    public int run(String... args) {
        logger.info("Quarkus application is running...");
        Quarkus.waitForExit();
        return 0;
    }

    public static void main(String[] args) {
        Quarkus.run(FinalAssignmentBackendMain.class, args);
    }
}
