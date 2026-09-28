package finalassignmentbackend.service.payment;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.PaymentRecord;
import finalassignmentbackend.reliability.ReliabilityMetrics;
import java.util.concurrent.CompletionStage;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Message;
import org.junit.jupiter.api.Test;

class PaymentEventPublishTest {

    @Test
    void brokerRejectionIncrementsTheCounterAndDoesNotThrow() {
        ReliabilityMetrics metrics = new ReliabilityMetrics();
        PaymentRecord record = new PaymentRecord();
        record.setPaymentId(7L);
        PaymentEventPublish.send(failingEmitter(), new ObjectMapper(), metrics, "pay-1", record);
        assertTrue(metrics.prometheus(0, 0, 0).contains("kafka_publish_failed_total 1\n"));
    }

    @Test
    void acceptedSendDoesNotIncrement() {
        ReliabilityMetrics metrics = new ReliabilityMetrics();
        PaymentRecord record = new PaymentRecord();
        record.setPaymentId(8L);
        PaymentEventPublish.send(acceptingEmitter(), new ObjectMapper(), metrics, "pay-2", record);
        assertFalse(metrics.prometheus(0, 0, 0).contains("kafka_publish_failed_total 1\n"));
        assertTrue(metrics.prometheus(0, 0, 0).contains("kafka_publish_failed_total 0\n"));
    }

    private static Emitter<String> failingEmitter() {
        return new FakeEmitter(true);
    }

    private static Emitter<String> acceptingEmitter() {
        return new FakeEmitter(false);
    }

    private static final class FakeEmitter implements Emitter<String> {
        private final boolean fail;

        private FakeEmitter(boolean fail) {
            this.fail = fail;
        }

        @Override
        public CompletionStage<Void> send(String msg) {
            throw new IllegalStateException("down");
        }

        @Override
        public <M extends Message<? extends String>> void send(M msg) {
            if (fail) {
                throw new IllegalStateException("down");
            }
        }

        @Override
        public void complete() {
        }

        @Override
        public void error(Exception e) {
        }

        @Override
        public boolean isCancelled() {
            return false;
        }

        @Override
        public boolean hasRequests() {
            return true;
        }
    }
}
