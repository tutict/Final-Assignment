package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.entity.AppealReview;
import com.tutict.finalassignmentcloud.traffic.service.AppealRecordService;
import com.tutict.finalassignmentcloud.traffic.service.AppealReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
@Tag(name = "Appeal Management", description = "违法申诉记录及复核管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "APPEAL_REVIEWER"})
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
    @Operation(summary = "创建申诉记录")
    public ResponseEntity<AppealRecord> createAppeal(@RequestBody AppealRecord request,
                                                     @RequestHeader(value = "Idempotency-Key", required = false)
                                                     String idempotencyKey) {
        boolean useIdempotency = hasKey(idempotencyKey);
        try {
            if (useIdempotency) {
                if (appealRecordService.shouldSkipProcessing(idempotencyKey)) {
                    LOG.log(Level.INFO, "Appeal create skipped by idempotency key {0}", idempotencyKey);
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                appealRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            AppealRecord saved = appealRecordService.createAppeal(request);
            if (useIdempotency && saved.getAppealId() != null) {
                appealRecordService.markHistorySuccess(idempotencyKey, saved.getAppealId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useIdempotency) {
                appealRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create appeal failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{appealId}")
    @Operation(summary = "更新申诉记录")
    public ResponseEntity<AppealRecord> updateAppeal(@PathVariable Long appealId,
                                                     @RequestBody AppealRecord request,
                                                     @RequestHeader(value = "Idempotency-Key", required = false)
                                                     String idempotencyKey) {
        boolean useIdempotency = hasKey(idempotencyKey);
        try {
            request.setAppealId(appealId);
            if (useIdempotency) {
                appealRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            AppealRecord updated = appealRecordService.updateAppeal(request);
            if (useIdempotency && updated.getAppealId() != null) {
                appealRecordService.markHistorySuccess(idempotencyKey, updated.getAppealId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useIdempotency) {
                appealRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update appeal failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{appealId}")
    @Operation(summary = "删除申诉记录")
    public ResponseEntity<Void> deleteAppeal(@PathVariable Long appealId) {
        try {
            appealRecordService.deleteAppeal(appealId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete appeal failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{appealId}")
    @Operation(summary = "查询申诉详情")
    public ResponseEntity<AppealRecord> getAppeal(@PathVariable Long appealId) {
        try {
            AppealRecord record = appealRecordService.getAppealById(appealId);
            return record == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(record);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get appeal failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "按违法记录分页查询申诉记录")
    public ResponseEntity<List<AppealRecord>> listAppeals(@RequestParam Long offenseId,
                                                          @RequestParam(defaultValue = "1") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(appealRecordService.findByOffenseId(offenseId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List appeals failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/number/prefix")
    @Operation(summary = "Search appeals by number prefix")
    public ResponseEntity<List<AppealRecord>> searchByNumberPrefix(@RequestParam String appealNumber,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAppealNumberPrefix(appealNumber, page, size));
    }

    @GetMapping("/search/number/fuzzy")
    @Operation(summary = "Search appeals by number fuzzy")
    public ResponseEntity<List<AppealRecord>> searchByNumberFuzzy(@RequestParam String appealNumber,
                                                                  @RequestParam(defaultValue = "1") int page,
                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAppealNumberFuzzy(appealNumber, page, size));
    }

    @GetMapping("/search/appellant/name/prefix")
    @Operation(summary = "Search appeals by appellant name prefix")
    public ResponseEntity<List<AppealRecord>> searchByAppellantNamePrefix(@RequestParam String appellantName,
                                                                          @RequestParam(defaultValue = "1") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAppellantNamePrefix(appellantName, page, size));
    }

    @GetMapping("/search/appellant/name/fuzzy")
    @Operation(summary = "Search appeals by appellant name fuzzy")
    public ResponseEntity<List<AppealRecord>> searchByAppellantNameFuzzy(@RequestParam String appellantName,
                                                                         @RequestParam(defaultValue = "1") int page,
                                                                         @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAppellantNameFuzzy(appellantName, page, size));
    }

    @GetMapping("/search/appellant/id-card")
    @Operation(summary = "Search appeals by appellant ID card")
    public ResponseEntity<List<AppealRecord>> searchByAppellantIdCard(@RequestParam String appellantIdCard,
                                                                      @RequestParam(defaultValue = "1") int page,
                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAppellantIdCard(appellantIdCard, page, size));
    }

    @GetMapping("/search/acceptance-status")
    @Operation(summary = "Search appeals by acceptance status")
    public ResponseEntity<List<AppealRecord>> searchByAcceptanceStatus(@RequestParam String acceptanceStatus,
                                                                       @RequestParam(defaultValue = "1") int page,
                                                                       @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAcceptanceStatus(acceptanceStatus, page, size));
    }

    @GetMapping("/search/process-status")
    @Operation(summary = "Search appeals by process status")
    public ResponseEntity<List<AppealRecord>> searchByProcessStatus(@RequestParam String processStatus,
                                                                    @RequestParam(defaultValue = "1") int page,
                                                                    @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByProcessStatus(processStatus, page, size));
    }

    @GetMapping("/search/time-range")
    @Operation(summary = "Search appeals by appeal time range")
    public ResponseEntity<List<AppealRecord>> searchByTimeRange(@RequestParam String startTime,
                                                                @RequestParam String endTime,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAppealTimeRange(startTime, endTime, page, size));
    }

    @GetMapping("/search/handler")
    @Operation(summary = "Search appeals by acceptance handler")
    public ResponseEntity<List<AppealRecord>> searchByHandler(@RequestParam String acceptanceHandler,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealRecordService.searchByAcceptanceHandler(acceptanceHandler, page, size));
    }

    @PostMapping("/{appealId}/reviews")
    @Operation(summary = "创建复核记录")
    public ResponseEntity<AppealReview> createReview(@PathVariable Long appealId,
                                                     @RequestBody AppealReview review,
                                                     @RequestHeader(value = "Idempotency-Key", required = false)
                                                     String idempotencyKey) {
        boolean useIdempotency = hasKey(idempotencyKey);
        try {
            review.setAppealId(appealId);
            if (useIdempotency) {
                if (appealReviewService.shouldSkipProcessing(idempotencyKey)) {
                    LOG.log(Level.INFO, "Appeal review skipped by idempotency key {0}", idempotencyKey);
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                appealReviewService.checkAndInsertIdempotency(idempotencyKey, review, "create");
            }
            AppealReview saved = appealReviewService.createReview(review);
            if (useIdempotency && saved.getReviewId() != null) {
                appealReviewService.markHistorySuccess(idempotencyKey, saved.getReviewId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useIdempotency) {
                appealReviewService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create appeal review failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/reviews/{reviewId}")
    @Operation(summary = "更新复核记录")
    public ResponseEntity<AppealReview> updateReview(@PathVariable Long reviewId,
                                                     @RequestBody AppealReview review,
                                                     @RequestHeader(value = "Idempotency-Key", required = false)
                                                     String idempotencyKey) {
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
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useIdempotency) {
                appealReviewService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update appeal review failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/reviews/{reviewId}")
    @Operation(summary = "删除复核记录")
    public ResponseEntity<Void> deleteReview(@PathVariable Long reviewId) {
        try {
            appealReviewService.deleteReview(reviewId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete appeal review failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/reviews/{reviewId}")
    @Operation(summary = "查询复核详情")
    public ResponseEntity<AppealReview> getReview(@PathVariable Long reviewId) {
        try {
            AppealReview review = appealReviewService.findById(reviewId);
            return review == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(review);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get appeal review failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/reviews")
    @Operation(summary = "查询全部复核记录")
    public ResponseEntity<List<AppealReview>> listReviews() {
        try {
            return ResponseEntity.ok(appealReviewService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List appeal reviews failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/reviews/search/reviewer")
    @Operation(summary = "Search appeal reviews by reviewer")
    public ResponseEntity<List<AppealReview>> searchReviewsByReviewer(@RequestParam String reviewer,
                                                                      @RequestParam(defaultValue = "1") int page,
                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealReviewService.searchByReviewer(reviewer, page, size));
    }

    @GetMapping("/reviews/search/reviewer-dept")
    @Operation(summary = "Search appeal reviews by reviewer department")
    public ResponseEntity<List<AppealReview>> searchReviewsByReviewerDept(@RequestParam String reviewerDept,
                                                                          @RequestParam(defaultValue = "1") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealReviewService.searchByReviewerDept(reviewerDept, page, size));
    }

    @GetMapping("/reviews/search/time-range")
    @Operation(summary = "Search appeal reviews by review time range")
    public ResponseEntity<List<AppealReview>> searchReviewsByTimeRange(@RequestParam String startTime,
                                                                       @RequestParam String endTime,
                                                                       @RequestParam(defaultValue = "1") int page,
                                                                       @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(appealReviewService.searchByReviewTimeRange(startTime, endTime, page, size));
    }

    @GetMapping("/reviews/count")
    @Operation(summary = "按复核级别统计数据")
    public ResponseEntity<Map<String, Object>> countReviews(@RequestParam("level") String reviewLevel) {
        try {
            long total = appealReviewService.countByReviewLevel(reviewLevel);
            return ResponseEntity.ok(Map.of("reviewLevel", reviewLevel, "count", total));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Count appeal reviews failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private HttpStatus resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
