package finalassignmentbackend.config;

import io.vertx.core.Vertx;
import io.vertx.kafka.client.consumer.KafkaConsumer;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.eclipse.microprofile.config.inject.ConfigProperties;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.Properties;

@ConfigProperties(prefix = "kafka")
public class KafkaConfig {

    @ConfigProperty(name = "quarkus.kafka.servers")
    String bootstrapServers;


    @ApplicationScoped
    public KafkaConsumer<String, String> kafkaConsumer(Vertx vertx) {
        Properties props = new Properties();
        props.put("bootstrap.servers", bootstrapServers);
        props.put("group.id", "my-group");
        props.put("key.deserializer", StringDeserializer.class.getName());
        props.put("value.deserializer", StringDeserializer.class.getName());

        // 使用Vert.x的KafkaConsumer创建方法
        return KafkaConsumer.create(vertx, props, String.class, String.class);
    }
}