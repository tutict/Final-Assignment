package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.traffic.service.ConsultationFeedbackService;
import com.tutict.finalassignmentcloud.traffic.service.ConsultationFeedbackService.SavedFeedback;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/feedback")
public class FeedbackController {

    private final ConsultationFeedbackService feedbackService;

    public FeedbackController(ConsultationFeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @GetMapping
    public List<Map<String, Object>> list(Authentication authentication) {
        return feedbackService.list(authentication.getName(), isStaff(authentication));
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(
            @RequestBody Map<String, Object> body,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            Authentication authentication) {
        SavedFeedback saved = feedbackService.create(
                authentication.getName(), isStaff(authentication), body, idempotencyKey);
        if (saved.created()) {
            return ResponseEntity.status(HttpStatus.CREATED).body(saved.body());
        }
        return ResponseEntity.ok(saved.body());
    }

    @PutMapping("/{feedbackId}")
    public Map<String, Object> update(
            @PathVariable long feedbackId,
            @RequestBody Map<String, Object> body,
            Authentication authentication) {
        return feedbackService.update(authentication.getName(), isStaff(authentication), feedbackId, body);
    }

    private static boolean isStaff(Authentication authentication) {
        if (authentication == null) {
            return false;
        }
        for (GrantedAuthority authority : authentication.getAuthorities()) {
            if (ConsultationFeedbackService.isStaffRole(authority.getAuthority())) {
                return true;
            }
        }
        return false;
    }
}
