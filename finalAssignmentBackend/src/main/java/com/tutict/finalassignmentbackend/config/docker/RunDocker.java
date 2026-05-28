package com.tutict.finalassignmentbackend.config.docker;

import com.redis.testcontainers.RedisContainer;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.testcontainers.elasticsearch.ElasticsearchContainer;
import org.testcontainers.redpanda.RedpandaContainer;
import org.testcontainers.utility.DockerImageName;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class RunDocker implements ApplicationContextInitializer<ConfigurableApplicationContext> {

    private static final Logger log = Logger.getLogger(RunDocker.class.getName());
    private static final String PROPERTY_SOURCE_NAME = "docker";
    private static final String DEFAULT_ELASTICSEARCH_IMAGE = "docker.elastic.co/elasticsearch/elasticsearch:9.4.1";
    private static volatile boolean shutdownHookRegistered = false;

    private static RedisContainer redisContainer;
    private static RedpandaContainer redpandaContainer;
    private static ElasticsearchContainer elasticsearchContainer;

    @Override
    public void initialize(ConfigurableApplicationContext applicationContext) {
        if (!isDevServicesEnabled(applicationContext.getEnvironment())) {
            log.log(Level.INFO, "Dev services are disabled. Skipping Redis, Redpanda, and Elasticsearch Testcontainers startup.");
            return;
        }
        ConfigurableEnvironment environment = applicationContext.getEnvironment();
        if (Boolean.parseBoolean(environment.getProperty("app.docker.startup-script.enabled", "false"))) {
            log.log(Level.INFO, "Script-managed Docker startup is enabled. Skipping Testcontainers dev service startup.");
            return;
        }
        if (isDevServiceEnabled(environment, "redis", true)) {
            startRedis(applicationContext);
        }
        if (isDevServiceEnabled(environment, "redpanda", false)) {
            startRedpanda(applicationContext);
        } else {
            log.log(Level.INFO, "Redpanda dev service is disabled. Kafka listeners should stay disabled for local startup.");
        }
        if (isDevServiceEnabled(environment, "elasticsearch", true)) {
            startElasticsearch(applicationContext);
        }
        registerShutdownHook();
    }

    private boolean isDevServicesEnabled(ConfigurableEnvironment environment) {
        boolean devProfileActive = Arrays.stream(environment.getActiveProfiles())
                .anyMatch(profile -> "dev".equalsIgnoreCase(profile));
        boolean enabled = Boolean.parseBoolean(environment.getProperty("app.dev-services.enabled", "false"));
        return devProfileActive && enabled;
    }

    private boolean isDevServiceEnabled(ConfigurableEnvironment environment, String serviceName, boolean defaultValue) {
        String key = "app.dev-services." + serviceName + ".enabled";
        return Boolean.parseBoolean(environment.getProperty(key, Boolean.toString(defaultValue)));
    }

    private void startRedis(ConfigurableApplicationContext applicationContext) {
        try {
            if (redisContainer == null || !redisContainer.isRunning()) {
                redisContainer = new RedisContainer("redis:7");
                redisContainer.start();
            }
            String redisHost = redisContainer.getHost();
            int redisPort = redisContainer.getFirstMappedPort();
            log.log(Level.INFO, "Redis container started successfully at {0}:{1}", new Object[]{redisHost, redisPort});
            setProperty(applicationContext, "spring.data.redis.host", redisHost);
            setProperty(applicationContext, "spring.data.redis.port", String.valueOf(redisPort));
            log.log(Level.INFO, "Redis properties set: host={0}, port={1}", new Object[]{redisHost, redisPort});
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Redis container: {0}", new Object[]{e.getMessage()});
        }
    }

    private void startRedpanda(ConfigurableApplicationContext applicationContext) {
        try {
            if (redpandaContainer == null || !redpandaContainer.isRunning()) {
                redpandaContainer = new RedpandaContainer("redpandadata/redpanda:v24.1.2");
                redpandaContainer.start();
            }
            String bootstrapServers = redpandaContainer.getBootstrapServers();
            log.log(Level.INFO, "Redpanda container started successfully with bootstrap servers: {0}", new Object[]{bootstrapServers});
            setProperty(applicationContext, "spring.kafka.bootstrap-servers", bootstrapServers);
            log.log(Level.INFO, "Kafka bootstrap-servers set: {0}", new Object[]{bootstrapServers});
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Redpanda container: {0}", new Object[]{e.getMessage(), e});
        }
    }

    private void startElasticsearch(ConfigurableApplicationContext applicationContext) {
        try {
            // Allow the local Elasticsearch image to be overridden by configuration.
            String image = applicationContext.getEnvironment()
                    .getProperty("app.docker.images.elasticsearch", DEFAULT_ELASTICSEARCH_IMAGE);
            DockerImageName elasticsearchImage = DockerImageName.parse(image)
                    .asCompatibleSubstituteFor("docker.elastic.co/elasticsearch/elasticsearch");

            // Start a single-node local Elasticsearch instance for dev services.
            if (elasticsearchContainer == null || !elasticsearchContainer.isRunning()) {
                elasticsearchContainer = new ElasticsearchContainer(elasticsearchImage)
                        .withEnv("xpack.security.enabled", "false")
                        .withEnv("discovery.type", "single-node");
                elasticsearchContainer.start();
            }

            String elasticsearchUrl = elasticsearchContainer.getHttpHostAddress();
            setProperty(applicationContext, "spring.elasticsearch.uris", "http://" + elasticsearchUrl);
            log.log(Level.INFO, "Elasticsearch started at: http://{0}", elasticsearchUrl);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to start Elasticsearch container: {0}", e.getMessage());
        }
    }

    private static void registerShutdownHook() {
        if (shutdownHookRegistered) {
            return;
        }
        synchronized (RunDocker.class) {
            if (shutdownHookRegistered) {
                return;
            }
            Runtime.getRuntime().addShutdownHook(new Thread(RunDocker::stopContainers, "docker-shutdown"));
            shutdownHookRegistered = true;
        }
    }

    private static void stopContainers() {
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
    }

    private static void setProperty(ConfigurableApplicationContext applicationContext, String key, String value) {
        ConfigurableEnvironment environment = applicationContext.getEnvironment();
        MutablePropertySources sources = environment.getPropertySources();
        MapPropertySource source = (MapPropertySource) sources.get(PROPERTY_SOURCE_NAME);
        if (source == null) {
            Map<String, Object> map = new HashMap<>();
            source = new MapPropertySource(PROPERTY_SOURCE_NAME, map);
            sources.addFirst(source);
        }
        source.getSource().put(key, value);
    }
}
