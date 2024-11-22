package finalassignmentbackend.kafkaListener.view;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.view.OffenseDetails;
import finalassignmentbackend.service.view.OffenseDetailsService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class OffenseDetailsKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseDetailsKafkaListener.class);

    @Inject
    OffenseDetailsService offenseDetailsService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("offense_details_topic")
    public void onOffenseDetailsReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                OffenseDetails offenseDetails = deserializeMessage(message);
                offenseDetailsService.saveOffenseDetails(offenseDetails);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing offense details message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing offense details message: %s", message, res.cause());
            }
        });
    }

    private OffenseDetails deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseDetails.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
