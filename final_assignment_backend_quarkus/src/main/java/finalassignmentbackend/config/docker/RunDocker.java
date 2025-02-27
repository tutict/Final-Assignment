package finalassignmentbackend.config.docker;

import io.quarkus.runtime.ShutdownEvent;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;

@ApplicationScoped
public class RunDocker {

    private static final Logger log = LoggerFactory.getLogger(RunDocker.class);
    private GenericContainer<?> manticoreContainer;

    @Inject
    @ConfigProperty(name = "manticore.image", defaultValue = "manticoresearch/manticore:latest")
    String manticoreImage;

    void onStart(@Observes StartupEvent ev) {
        startManticoreSearch();
    }

    void onStop(@Observes ShutdownEvent ev) {
        stopManticore();
    }

    @SuppressWarnings("resource")
    public void startManticoreSearch() {
        try {
            manticoreContainer = new GenericContainer<>(DockerImageName.parse(manticoreImage))
                    .withExposedPorts(9306, 9308)
                    .withEnv("EXTRA", "1")
                    .waitingFor(Wait.forHttp("/search")
                            .forPort(9308)
                            .withStartupTimeout(Duration.ofSeconds(120)));

            manticoreContainer.start();

            String manticoreHost = manticoreContainer.getHost();
            Integer httpPort = manticoreContainer.getMappedPort(9308);
            String manticoreUrl = String.format("http://%s:%d", manticoreHost, httpPort);

            System.setProperty("manticore.host", manticoreUrl);
            log.info("Manticore container started successfully at {}", manticoreUrl);
        } catch (Exception e) {
            log.warn("Failed to start Manticore container: {}", e.getMessage(), e);
            throw new RuntimeException("Manticore startup failed", e);
        }
    }

    public void stopManticore() {
        if (manticoreContainer != null && manticoreContainer.isRunning()) {
            manticoreContainer.stop();
            manticoreContainer.close();
            log.info("Manticore container stopped and closed");
        }
    }
}