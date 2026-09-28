package finalassignmentbackend.reliability;

import io.smallrye.common.annotation.Identifier;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import java.util.HashMap;
import java.util.Map;
import org.apache.kafka.clients.producer.ProducerConfig;

@ApplicationScoped
public class LedgerKafkaClientConfig {

    public static final String IDENTIFIER = "ledger-producer";

    @Produces
    @Identifier(IDENTIFIER)
    @ApplicationScoped
    public Map<String, Object> ledgerProducerConfig() {
        Map<String, Object> config = new HashMap<>();
        config.put(ProducerConfig.ACKS_CONFIG, "all");
        config.put(ProducerConfig.RETRIES_CONFIG, 3);
        config.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        config.put(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG, 10_000);
        config.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 3_000);
        config.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, 500);
        config.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5);
        return config;
    }
}
