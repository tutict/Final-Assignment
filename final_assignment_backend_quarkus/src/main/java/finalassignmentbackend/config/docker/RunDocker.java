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
    private GenericContainer<?> redisContainer;
    private GenericContainer<?> redpandaContainer;

    @Inject
    @ConfigProperty(name = "manticore.image", defaultValue = "manticoresearch/manticore:latest")
    String manticoreImage;

    @Inject
    @ConfigProperty(name = "redis.image", defaultValue = "redis:7")
    String redisImage;

    @Inject
    @ConfigProperty(name = "redpanda.image", defaultValue = "tutict/elasticsearch-with-plugins:8.17.3-for-my-work")
    String redpandaImage;

    /**
     * 启动ManticoreSearch容器与关闭容器
     *
     * @param ev the startup event
     */
    void onStart(@Observes StartupEvent ev) {
        startManticoreSearch();
    }
    void onStop(@Observes ShutdownEvent ev) {
        stopManticore();
    }

    /**
     * 启动Redis容器与关闭容器
     *
     * @param ev the startup event
     */
    void onStartRedis(@Observes StartupEvent ev) { startRedis(); }
    void onStopRedis(@Observes ShutdownEvent ev) { stopRedis(); }

    /**
     * 启动Redpanda容器与关闭容器
     *
     * @param ev the startup event
     */
    void onStartRedpanda(@Observes StartupEvent ev) { startRedpanda(); }
    void onStopRedpanda(@Observes ShutdownEvent ev) { stopRedpanda(); }

    // 启动ManticoreSearch
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
            log.warn("Failed to start Manticore container: {}", e.getMessage());
        }
    }

    // 启动Redis
    public void startRedis() {
        try {
            redisContainer = new GenericContainer<>(DockerImageName.parse(redisImage));
            redisContainer.start();
            String redisHost = redisContainer.getHost();
            int redisPort = redisContainer.getFirstMappedPort();
            log.info( "Redis容器启动成功，地址: {}:{}", redisHost, redisPort);
            System.setProperty("quarkus.redis.hosts", redisHost + ":" + redisPort);
            log.info("Redis配置已设置: host={}, port={}", redisHost, redisPort);
        } catch (Exception e) {
            log.warn("启动Redis容器失败: {}", e.getMessage());
        }
    }

    // 启动Redpanda
    public void startRedpanda() {
        try {
            redpandaContainer = new GenericContainer<>(DockerImageName.parse(redpandaImage));
            redpandaContainer.start();
            String bootstrapServersHost = redpandaContainer.getHost();
            int bootstrapServersPort = redpandaContainer.getFirstMappedPort();
            log.info("Redpanda容器启动成功，地址: {}:{}", bootstrapServersHost, bootstrapServersPort);
            System.setProperty("quarkus.kafka.bootstrap.servers",  bootstrapServersHost + ":" + bootstrapServersPort);
            log.info("Kafka bootstrap-servers已设置: host={}, port={}", bootstrapServersHost, bootstrapServersPort);
        } catch (Exception e) {
            log.warn("启动Redpanda容器失败: {}", e.getMessage());
        }
    }

    // 关闭ManticoreSearch
    public void stopManticore() {
        if (manticoreContainer != null && manticoreContainer.isRunning()) {
            manticoreContainer.stop();
            manticoreContainer.close();
            log.info("Manticore container stopped and closed");
        }
    }

    // 关闭Redis
    public void stopRedis() {
        if (redisContainer != null && redisContainer.isRunning()) {
            redisContainer.stop();
            redisContainer.close();
            log.info("Redis container stopped and closed");
        }
    }

    // 关闭Redpanda
    public void stopRedpanda() {
        if (redpandaContainer != null && redpandaContainer.isRunning()) {
            redpandaContainer.stop();
            redpandaContainer.close();
            log.info("Redpanda container stopped and closed");
        }
    }
}