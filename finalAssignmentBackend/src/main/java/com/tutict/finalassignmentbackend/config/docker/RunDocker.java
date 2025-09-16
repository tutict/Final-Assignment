package com.tutict.finalassignmentbackend.config.docker;

import com.redis.testcontainers.RedisContainer;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.elasticsearch.ElasticsearchContainer;
import org.testcontainers.redpanda.RedpandaContainer;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class RunDocker {

    private static final Logger log = Logger.getLogger(RunDocker.class.getName());

    private RedisContainer redisContainer;
    private RedpandaContainer redpandaContainer;
    private ElasticsearchContainer elasticsearchContainer;
    private GenericContainer<?> manticoreContainer;

    @Value("${manticore.image:manticoresearch/manticore:dev}")
    private String manticoreImage;

    @PostConstruct
    public void init() {
        startRedis();
        startRedpanda();
        startElasticsearch();
        // startManticoreSearch();
    }

    public void startRedis() {
        try {
            redisContainer = new RedisContainer("redis:7");
            redisContainer.start();
            String redisHost = redisContainer.getHost();
            int redisPort = redisContainer.getFirstMappedPort();
            log.log(Level.INFO, "Redis container started successfully at {0}:{1}", new Object[]{redisHost, redisPort});
            System.setProperty("spring.data.redis.host", redisHost);
            System.setProperty("spring.data.redis.port", String.valueOf(redisPort));
            log.log(Level.INFO, "Redis properties set: host={0}, port={1}", new Object[]{redisHost, redisPort});
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Redis container: {0}", new Object[]{e.getMessage()});
        }
    }

    public void startRedpanda() {
        try {
            redpandaContainer = new RedpandaContainer("redpandadata/redpanda:v24.1.2");
            redpandaContainer.start();
            String bootstrapServers = redpandaContainer.getBootstrapServers();
            log.log(Level.INFO, "Redpanda container started successfully with bootstrap servers: {0}", new Object[]{bootstrapServers});
            System.setProperty("spring.kafka.bootstrap-servers", bootstrapServers);
            log.log(Level.INFO, "Kafka bootstrap-servers set: {0}", new Object[]{bootstrapServers});
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Redpanda container: {0}", new Object[]{e.getMessage(), e});
        }
    }

    public void startElasticsearch() {
        try {
            // 声明自定义镜像与官方镜像兼容
            DockerImageName myImage = DockerImageName.parse("tutict/elasticsearch-with-plugins:8.17.3-for-my-work")
                    .asCompatibleSubstituteFor("docker.elastic.co/elasticsearch/elasticsearch");

            // 使用自定义镜像启动容器，仅设置单节点模式
            elasticsearchContainer = new ElasticsearchContainer(myImage)
                    .withEnv("xpack.security.enabled", "false")
                    .withEnv("discovery.type", "single-node"); // 启用单节点模式
            elasticsearchContainer.start();

            String elasticsearchUrl = elasticsearchContainer.getHttpHostAddress();
            System.setProperty("spring-elasticsearch-uris", "http://" + elasticsearchUrl);
            log.log(Level.INFO, "Elasticsearch started at: http://{0}", elasticsearchUrl);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Elasticsearch container: {0}", e.getMessage());
        }
    }

    public void startManticoreSearch() {
        try (GenericContainer<?> container = new GenericContainer<>(DockerImageName.parse(manticoreImage))
                .withExposedPorts(9306, 9308)
                .withEnv("EXTRA", "1")
                .waitingFor(Wait.forHttp("/search")
                        .forPort(9308)
                        .withStartupTimeout(Duration.ofSeconds(120)))) {
            container.start();

            manticoreContainer = container;
            String manticoreHost = manticoreContainer.getHost();
            Integer httpPort = manticoreContainer.getMappedPort(9308);
            String manticoreUrl = String.format("http://%s:%d", manticoreHost, httpPort);

            System.setProperty("manticore.host", manticoreUrl);
            log.log(Level.INFO, "Manticore container started successfully at {0}", new Object[]{manticoreUrl});
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Manticore container: {0}", new Object[]{e.getMessage()});
            throw new RuntimeException("Manticore startup failed", e);
        }
    }

    @PreDestroy
    public void stopContainers() {
        if (redisContainer != null && redisContainer.isRunning()) {
            redisContainer.stop();
            log.log(Level.INFO, "Redis container stopped");
        }
        if (redpandaContainer != null && redpandaContainer.isRunning()) {
            redpandaContainer.stop();
            log.log(Level.INFO, "Redpanda container stopped");
        }
        if (elasticsearchContainer != null && elasticsearchContainer.isRunning()) {
            elasticsearchContainer.stop();
            log.log(Level.INFO, "Elasticsearch container stopped");
        }
        if (manticoreContainer != null && manticoreContainer.isRunning()) {
            manticoreContainer.stop();
            log.log(Level.INFO, "Manticore container stopped and closed");
        }
    }
}