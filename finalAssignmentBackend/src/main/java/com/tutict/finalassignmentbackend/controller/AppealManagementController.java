package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.dto.mapper.AppealRecordRequestMapper;
import com.tutict.finalassignmentbackend.dto.request.AppealCreateRequest;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.dto.response.AppealResponse;
import com.tutict.finalassignmentbackend.dto.response.PageResponse;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.AppealReview;
import com.tutict.finalassignmentbackend.exception.EntityNotFoundException;
import com.tutict.finalassignmentbackend.service.AppealRecordService;
import com.tutict.finalassignmentbackend.service.AppealReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/appeals")
@Tag(name = "Appeal Management", description = "Appeal management APIs")
@SecurityRequirement(name = "bearerAuth")
public class AppealManagementController {

    private static final Logger LOG = Logger.getLogger(AppealManagementController.class.getName());

    private final AppealRecordService appealRecordService;
    private final AppealReviewService appealReviewService;

    public AppealManagementController(AppealRecordService appealRecordService,
                                      AppealReviewService appealReviewService) {
        this.appealRecordService = appealRecordService;
        this.appealReviewService = appealReviewService;
    }

    @PostMapping
    @RolesAllowed({"USER", "ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Create appeal")
    public ResponseEntity<ApiResponse<AppealResponse>> createAppeal(
            @Valid @RequestBody AppealCreateRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            Authentication authentication) {
        boolean useIdempotency = hasKey(idempotencyKey);
        AppealRecord appealRecord = AppealRecordRequestMapper.toEntity(request);
        appealRecord.setCreatedBy(authentication.getName());
        appealRecord.setUpdatedBy(authentication.getName());
        try {
            if (useIdempotency) {
                if (appealRecordService.shouldSkipProcessing(idempotencyKey)) {
                    LOG.log(Level.INFO, "Appeal create skipped by idempotency key {0}", idempotencyKey);
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
                }
                appealRecordService.checkAndInsertIdempotency(idempotencyKey, appealRecord, "create");
            }
            AppealRecord saved = appealRecordService.createAppeal(appealRecord);
            if (useIdempotency && saved.getAppealId() != null) {
                appealRecordService.markHistorySuccess(idempotencyKey, saved.getAppealId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(AppealResponse.from(saved)));
        } catch (RuntimeException ex) {
            if (useIdempotency) {
                appealRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create appeal failed", ex);
            throw ex;
        }
    }

    @GetMapping("/my")
    @RolesAllowed({"USER", "ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "List current user's appeals")
    public ResponseEntity<ApiResponse<PageResponse<AppealResponse>>> getMyAppeals(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<AppealResponse> content = toResponses(
                appealRecordService.findByCreatedBy(authentication.getName(), page, size));
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(content, content.size(), page, size)));
    }

    @GetMapping
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "List appeals by offense")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> listAppeals(
            @RequestParam Long offenseId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.findByOffenseId(offenseId, page, size))));
    }

    @GetMapping("/{appealId}")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Get appeal by id")
    public ResponseEntity<ApiResponse<AppealResponse>> getAppeal(@PathVariable Long appealId) {
        AppealRecord record = appealRecordService.getAppealById(appealId);
        if (record == null) {
            throw new EntityNotFoundException("Appeal not found: " + appealId);
        }
        return ResponseEntity.ok(ApiResponse.ok(AppealResponse.from(record)));
    }

    @PutMapping("/{appealId}")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Update appeal")
    public ResponseEntity<ApiResponse<AppealResponse>> updateAppeal(
            @PathVariable Long appealId,
            @Valid @RequestBody AppealCreateRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            Authentication authentication) {
        boolean useIdempotency = hasKey(idempotencyKey);
        AppealRecord appealRecord = AppealRecordRequestMapper.toEntity(request);
        appealRecord.setAppealId(appealId);
        appealRecord.setUpdatedBy(authentication.getName());
        try {
            if (useIdempotency) {
                appealRecordService.checkAndInsertIdempotency(idempotencyKey, appealRecord, "update");
            }
            AppealRecord updated = appealRecordService.updateAppeal(appealRecord);
            if (useIdempotency && updated.getAppealId() != null) {
                appealRecordService.markHistorySuccess(idempotencyKey, updated.getAppealId());
            }
            return ResponseEntity.ok(ApiResponse.ok(AppealResponse.from(updated)));
        } catch (RuntimeException ex) {
            if (useIdempotency) {
                appealRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update appeal failed", ex);
            throw ex;
        }
    }

    @DeleteMapping("/{appealId}")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Delete appeal")
    public ResponseEntity<ApiResponse<Void>> deleteAppeal(@PathVariable Long appealId) {
        appealRecordService.deleteAppeal(appealId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @GetMapping("/search/number/prefix")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by number prefix")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByNumberPrefix(
            @RequestParam String appealNumber,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAppealNumberPrefix(appealNumber, page, size))));
    }

    @GetMapping("/search/number/fuzzy")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by number fuzzy")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByNumberFuzzy(
            @RequestParam String appealNumber,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAppealNumberFuzzy(appealNumber, page, size))));
    }

    @GetMapping("/search/appellant/name/prefix")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by appellant name prefix")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByAppellantNamePrefix(
            @RequestParam String appellantName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAppellantNamePrefix(appellantName, page, size))));
    }

    @GetMapping("/search/appellant/name/fuzzy")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by appellant name fuzzy")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByAppellantNameFuzzy(
            @RequestParam String appellantName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAppellantNameFuzzy(appellantName, page, size))));
    }

    @GetMapping("/search/appellant/id-card")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by appellant ID card")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByAppellantIdCard(
            @RequestParam String appellantIdCard,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAppellantIdCard(appellantIdCard, page, size))));
    }

    @GetMapping("/search/acceptance-status")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by acceptance status")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByAcceptanceStatus(
            @RequestParam String acceptanceStatus,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAcceptanceStatus(acceptanceStatus, page, size))));
    }

    @GetMapping("/search/process-status")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by process status")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByProcessStatus(
            @RequestParam String processStatus,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByProcessStatus(processStatus, page, size))));
    }

    @GetMapping("/search/time-range")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by appeal time range")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByTimeRange(
            @RequestParam String startTime,
            @RequestParam String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAppealTimeRange(startTime, endTime, page, size))));
    }

    @GetMapping("/search/handler")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeals by acceptance handler")
    public ResponseEntity<ApiResponse<List<AppealResponse>>> searchByHandler(
            @RequestParam String acceptanceHandler,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                toResponses(appealRecordService.searchByAcceptanceHandler(acceptanceHandler, page, size))));
    }

    @PostMapping("/{appealId}/reviews")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Create appeal review")
    public ResponseEntity<ApiResponse<AppealReview>> createReview(
            @PathVariable Long appealId,
            @Valid @RequestBody AppealReview review,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
        boolean useIdempotency = hasKey(idempotencyKey);
        try {
            review.setAppealId(appealId);
            if (useIdempotency) {
                if (appealReviewService.shouldSkipProcessing(idempotencyKey)) {
                    LOG.log(Level.INFO, "Appeal review skipped by idempotency key {0}", idempotencyKey);
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
                }
                appealReviewService.checkAndInsertIdempotency(idempotencyKey, review, "create");
            }
            AppealReview saved = appealReviewService.createReview(review);
            if (useIdempotency && saved.getReviewId() != null) {
                appealReviewService.markHistorySuccess(idempotencyKey, saved.getReviewId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(saved));
        } catch (RuntimeException ex) {
            if (useIdempotency) {
                appealReviewService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create appeal review failed", ex);
            throw ex;
        }
    }

    @PutMapping("/reviews/{reviewId}")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Update appeal review")
    public ResponseEntity<ApiResponse<AppealReview>> updateReview(
            @PathVariable Long reviewId,
            @Valid @RequestBody AppealReview review,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
        boolean useIdempotency = hasKey(idempotencyKey);
        try {
            review.setReviewId(reviewId);
            if (useIdempotency) {
                appealReviewService.checkAndInsertIdempotency(idempotencyKey, review, "update");
            }
            AppealReview updated = appealReviewService.updateReview(review);
            if (useIdempotency && updated.getReviewId() != null) {
                appealReviewService.markHistorySuccess(idempotencyKey, updated.getReviewId());
            }
            return ResponseEntity.ok(ApiResponse.ok(updated));
        } catch (RuntimeException ex) {
            if (useIdempotency) {
                appealReviewService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update appeal review failed", ex);
            throw ex;
        }
    }

    @DeleteMapping("/reviews/{reviewId}")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Delete appeal review")
    public ResponseEntity<ApiResponse<Void>> deleteReview(@PathVariable Long reviewId) {
        appealReviewService.deleteReview(reviewId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @GetMapping("/reviews/{reviewId}")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Get appeal review")
    public ResponseEntity<ApiResponse<AppealReview>> getReview(@PathVariable Long reviewId) {
        AppealReview review = appealReviewService.findById(reviewId);
        if (review == null) {
            throw new EntityNotFoundException("Appeal review not found: " + reviewId);
        }
        return ResponseEntity.ok(ApiResponse.ok(review));
    }

    @GetMapping("/reviews")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "List appeal reviews")
    public ResponseEntity<ApiResponse<List<AppealReview>>> listReviews() {
        return ResponseEntity.ok(ApiResponse.ok(appealReviewService.findAll()));
    }

    @GetMapping("/reviews/search/reviewer")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeal reviews by reviewer")
    public ResponseEntity<ApiResponse<List<AppealReview>>> searchReviewsByReviewer(
            @RequestParam String reviewer,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(appealReviewService.searchByReviewer(reviewer, page, size)));
    }

    @GetMapping("/reviews/search/reviewer-dept")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeal reviews by reviewer department")
    public ResponseEntity<ApiResponse<List<AppealReview>>> searchReviewsByReviewerDept(
            @RequestParam String reviewerDept,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(appealReviewService.searchByReviewerDept(reviewerDept, page, size)));
    }

    @GetMapping("/reviews/search/time-range")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Search appeal reviews by review time range")
    public ResponseEntity<ApiResponse<List<AppealReview>>> searchReviewsByTimeRange(
            @RequestParam String startTime,
            @RequestParam String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(
                appealReviewService.searchByReviewTimeRange(startTime, endTime, page, size)));
    }

    @GetMapping("/reviews/count")
    @RolesAllowed({"ADMIN", "APPEAL_REVIEWER", "SUPER_ADMIN"})
    @Operation(summary = "Count appeal reviews")
    public ResponseEntity<ApiResponse<Map<String, Object>>> countReviews(@RequestParam("level") String reviewLevel) {
        long total = appealReviewService.countByReviewLevel(reviewLevel);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("reviewLevel", reviewLevel, "count", total)));
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private List<AppealResponse> toResponses(List<AppealRecord> records) {
        return records == null ? List.of() : records.stream().map(AppealResponse::from).toList();
    }
}
