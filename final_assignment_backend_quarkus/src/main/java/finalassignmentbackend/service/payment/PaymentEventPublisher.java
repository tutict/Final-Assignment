package finalassignmentbackend.service.payment;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.PaymentRecord;
import finalassignmentbackend.reliability.ReliabilityMetrics;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

@ApplicationScoped
public class PaymentEventPublisher {

    @Inject
    @Channel("payment-create-out")
    Emitter<String> emitter;

    @Inject
    ObjectMapper objectMapper;

    @Inject
    ReliabilityMetrics metrics;

    public void sendCreate(String key, PaymentRecord record) {
        PaymentEventPublish.send(emitter, objectMapper, metrics, key, record);
    }
}
