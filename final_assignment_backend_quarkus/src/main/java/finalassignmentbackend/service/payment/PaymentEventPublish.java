package finalassignmentbackend.service.payment;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.PaymentRecord;
import finalassignmentbackend.reliability.ReliabilityMetrics;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.concurrent.CompletableFuture;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class PaymentEventPublish {

    private static final Logger LOG = Logger.getLogger(PaymentEventPublish.class.getName());

    private PaymentEventPublish() {
    }

    public static void send(Emitter<String> emitter, ObjectMapper mapper, ReliabilityMetrics metrics, String key, PaymentRecord payload) {
        if (emitter == null || mapper == null || payload == null) {
            failed(metrics, null);
            return;
        }
        try {
            String body = mapper.writeValueAsString(payload);
            Message<String> message = Message.of(body).withNack(error -> {
                failed(metrics, error);
                return CompletableFuture.completedFuture(null);
            });
            if (key != null && !key.isBlank()) {
                message = message.addMetadata(OutgoingKafkaRecordMetadata.<String>builder().withKey(key).build());
            }
            emitter.send(message);
        } catch (JsonProcessingException | RuntimeException ex) {
            failed(metrics, ex);
        }
    }

    private static void failed(ReliabilityMetrics metrics, Throwable error) {
        if (metrics != null) {
            metrics.kafkaPublishFailed();
        }
        if (error != null) {
            LOG.log(Level.WARNING, "Failed to publish payment_record_create", error);
        }
    }
}
