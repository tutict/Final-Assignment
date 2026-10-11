package finalassignmentbackend.config.db;

import finalassignmentbackend.service.business.ConsultationFeedbackService;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;

import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class FeedbackSchemaMigration {

    private static final Logger LOG = Logger.getLogger(FeedbackSchemaMigration.class.getName());

    @Inject
    ConsultationFeedbackService feedbackService;

    void onStart(@Observes StartupEvent event) {
        try {
            feedbackService.ensureTable();
            LOG.log(Level.INFO, "Ensured consultation_feedback table exists.");
        } catch (SQLException ex) {
            throw new IllegalStateException("Failed to ensure consultation_feedback table", ex);
        }
    }
}
