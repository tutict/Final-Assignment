package com.tutict.finalassignmentbackend.config.db;

import com.tutict.finalassignmentbackend.service.business.ConsultationFeedbackService;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Component;

import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class FeedbackSchemaMigration implements InitializingBean {

    private static final Logger LOG = Logger.getLogger(FeedbackSchemaMigration.class.getName());

    private final ConsultationFeedbackService feedbackService;

    public FeedbackSchemaMigration(ConsultationFeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @Override
    public void afterPropertiesSet() {
        feedbackService.ensureTable();
        LOG.log(Level.INFO, "Ensured consultation_feedback table exists.");
    }
}
