package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.service.DeductionInformationService;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

@ApplicationScoped
public class DeductionInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DeductionInformationKafkaListener.class);

    @Inject
    DeductionInformationService deductionInformationService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("deduction_create")
    public void onDeductionCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                DeductionInformation deductionInformation = deserializeMessage(message);
                deductionInformationService.createDeduction(deductionInformation);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing create deduction message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing create deduction message: %s", message, res.cause());
            }
        });
    }

    @Incoming("deduction_update")
    public void onDeductionUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                DeductionInformation deductionInformation = deserializeMessage(message);
                deductionInformationService.updateDeduction(deductionInformation);
                promise.complete();
            } catch (Exception e) {
                log.errorf("Error processing update deduction message: %s", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.errorf("Error processing update deduction message: %s", message, res.cause());
            }
        });
    }

    private DeductionInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DeductionInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
