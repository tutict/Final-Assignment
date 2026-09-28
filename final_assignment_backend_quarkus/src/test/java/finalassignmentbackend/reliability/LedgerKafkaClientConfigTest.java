package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.junit.jupiter.api.Test;

class LedgerKafkaClientConfigTest {

    @Test
    void producerMapIsBoundedAndIdempotent() {
        Map<String, Object> config = new LedgerKafkaClientConfig().ledgerProducerConfig();
        assertEquals("all", config.get(ProducerConfig.ACKS_CONFIG));
        assertEquals(3, config.get(ProducerConfig.RETRIES_CONFIG));
        assertEquals(true, config.get(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG));
        assertEquals(10_000, config.get(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG));
        assertEquals(3_000, config.get(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG));
        assertEquals(500, config.get(ProducerConfig.MAX_BLOCK_MS_CONFIG));
        assertEquals(5, config.get(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION));
    }

    @Test
    void outgoingChannelsUseTheBoundedClientConfig() throws Exception {
        String text = Files.readString(Path.of("src/main/resources/application.yaml"));
        for (String channel : new String[] {"offense-create-out", "offense-update-out", "payment-create-out"}) {
            assertTrue(text.contains("      " + channel + ":"), channel);
            assertTrue(text.contains("acks: all"), channel);
            assertTrue(text.contains("retries: 3"), channel);
            assertTrue(text.contains("kafka-configuration: ledger-producer"), channel);
        }
    }
}
