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

    private GenericContainer<?> elasticsearchContainer;
    private GenericContainer<?> redisContainer;
    private GenericContainer<?> redpandaContainer;

    @Inject
    @ConfigProperty(name = "elasticsearch.image", defaultValue = "docker.elastic.co/elasticsearch/elasticsearch:9.4.1")
    String elasticsearchImage;

    @Inject
    @ConfigProperty(name = "redis.image", defaultValue = "redis:7")
    String redisImage;

    @Inject
    @ConfigProperty(name = "redpanda.image", defaultValue = "docker.redpanda.com/redpandadata/redpanda:v26.1.9")
    String redpandaImage;

    void onStartElasticsearch(@Observes StartupEvent event) {
        startElasticsearch();
    }

    void onStopElasticsearch(@Observes ShutdownEvent event) {
        stopElasticsearch();
    }

    void onStartRedis(@Observes StartupEvent event) {
        startRedis();
    }

    void onStopRedis(@Observes ShutdownEvent event) {
        stopRedis();
    }

    void onStartRedpanda(@Observes StartupEvent event) {
        startRedpanda();
    }

    void onStopRedpanda(@Observes ShutdownEvent event) {
        stopRedpanda();
    }

    @SuppressWarnings("resource")
    public void startElasticsearch() {
        try {
            elasticsearchContainer = new GenericContainer<>(DockerImageName.parse(elasticsearchImage))
                    .withExposedPorts(9200)
                    .withEnv("xpack.security.enabled", "false")
                    .withEnv("discovery.type", "single-node")
                    .waitingFor(Wait.forHttp("/_cluster/health")
                            .forPort(9200)
                            .withStartupTimeout(Duration.ofSeconds(120)));
            elasticsearchContainer.start();

            String host = elasticsearchContainer.getHost();
            Integer httpPort = elasticsearchContainer.getMappedPort(9200);
            String elasticsearchUrl = String.format("http://%s:%d", host, httpPort);
            System.setProperty("elasticsearch.host", elasticsearchUrl);
            log.info("Elasticsearch container started successfully at {}", elasticsearchUrl);
        } catch (Exception e) {
            log.warn("Failed to start Elasticsearch container: {}", e.getMessage());
        }
    }

    @SuppressWarnings("resource")
    public void startRedis() {
        try {
            redisContainer = new GenericContainer<>(DockerImageName.parse(redisImage))
                    .withExposedPorts(6379)
                    .waitingFor(Wait.forListeningPort().withStartupTimeout(Duration.ofSeconds(60)));
            redisContainer.start();

            String redisHost = redisContainer.getHost();
            int redisPort = redisContainer.getMappedPort(6379);
            System.setProperty("quarkus.redis.hosts", redisHost + ":" + redisPort);
            log.info("Redis container started successfully at {}:{}", redisHost, redisPort);
        } catch (Exception e) {
            log.warn("Failed to start Redis container: {}", e.getMessage());
        }
    }

    @SuppressWarnings("resource")
    public void startRedpanda() {
        try {
            redpandaContainer = new GenericContainer<>(DockerImageName.parse(redpandaImage))
                    .withExposedPorts(9092)
                    .waitingFor(Wait.forListeningPort().withStartupTimeout(Duration.ofSeconds(120)));
            redpandaContainer.start();

            String host = redpandaContainer.getHost();
            int port = redpandaContainer.getMappedPort(9092);
            System.setProperty("quarkus.kafka.bootstrap.servers", host + ":" + port);
            log.info("Redpanda container started successfully at {}:{}", host, port);
        } catch (Exception e) {
            log.warn("Failed to start Redpanda container: {}", e.getMessage());
        }
    }

    public void stopElasticsearch() {
        stopContainer(elasticsearchContainer, "Elasticsearch");
    }

    public void stopRedis() {
        stopContainer(redisContainer, "Redis");
    }

    public void stopRedpanda() {
        stopContainer(redpandaContainer, "Redpanda");
    }

    private void stopContainer(GenericContainer<?> container, String name) {
        if (container != null && container.isRunning()) {
            container.stop();
            container.close();
            log.info("{} container stopped and closed", name);
        }
    }
}
