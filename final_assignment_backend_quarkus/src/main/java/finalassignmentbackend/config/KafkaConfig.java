package finalassignmentbackend.config;

import io.vertx.kafka.client.consumer.KafkaConsumer;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import io.vertx.mutiny.core.Vertx;

import java.util.HashMap;
import java.util.Map;

@ApplicationScoped
public class KafkaConfig {

    @ConfigProperty(name = "kafka.bootstrap.servers")
    String bootstrapServers;

    @Produces
    @ApplicationScoped
    public KafkaConsumer<String, String> kafkaConsumer(Vertx vertx) {
        Map<String, String> config = new HashMap<>();
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "my-group");
        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        return KafkaConsumer.create((io.vertx.core.Vertx) vertx, config, String.class, String.class);
    }
}
