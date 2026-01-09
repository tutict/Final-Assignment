package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.AppealReview;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.AppealReviewMapper;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
@RegisterForReflection
public class AppealReviewService {

    private static final Logger log = Logger.getLogger(AppealReviewService.class.getName());

    @Inject
    AppealReviewMapper appealReviewMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "appealReviewCache")
    @WsAction(service = "AppealReviewService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealReview review, String action) {
        Objects.requireNonNull(review, "Appeal review cannot be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate appeal review request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(review.getReviewId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealReviewCache")
    public AppealReview createReview(AppealReview review) {
        validateReview(review);
        appealReviewMapper.insert(review);
        return review;
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealReviewCache")
    public AppealReview updateReview(AppealReview review) {
        validateReviewId(review);
        int rows = appealReviewMapper.updateById(review);
        if (rows == 0) {
            throw new IllegalStateException("Appeal review not found: " + review.getReviewId());
        }
        return review;
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealReviewCache")
    public void deleteReview(Long reviewId) {
        validateReviewId(reviewId);
        int rows = appealReviewMapper.deleteById(reviewId);
        if (rows == 0) {
            throw new IllegalStateException("Appeal review not found: " + reviewId);
        }
    }

    @CacheResult(cacheName = "appealReviewCache")
    public AppealReview findById(Long reviewId) {
        validateReviewId(reviewId);
        return appealReviewMapper.selectById(reviewId);
    }

    @CacheResult(cacheName = "appealReviewCache")
    public List<AppealReview> findAll() {
        return appealReviewMapper.selectList(null);
    }

    @CacheResult(cacheName = "appealReviewCache")
    public List<AppealReview> searchByReviewer(String reviewer, int page, int size) {
        if (isBlank(reviewer)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealReview> wrapper = new QueryWrapper<>();
        wrapper.likeRight("reviewer", reviewer)
                .orderByDesc("review_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealReviewCache")
    public List<AppealReview> searchByReviewerDept(String reviewerDept, int page, int size) {
        if (isBlank(reviewerDept)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealReview> wrapper = new QueryWrapper<>();
        wrapper.likeRight("reviewer_dept", reviewerDept)
                .orderByDesc("review_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealReviewCache")
    public List<AppealReview> searchByReviewTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<AppealReview> wrapper = new QueryWrapper<>();
        wrapper.between("review_time", start, end)
                .orderByDesc("review_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    public long countByReviewLevel(String reviewLevel) {
        if (isBlank(reviewLevel)) {
            return 0L;
        }
        QueryWrapper<AppealReview> wrapper = new QueryWrapper<>();
        wrapper.eq("review_level", reviewLevel);
        return appealReviewMapper.selectCount(wrapper);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long reviewId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(reviewId);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private List<AppealReview> fetchFromDatabase(QueryWrapper<AppealReview> wrapper, int page, int size) {
        Page<AppealReview> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        appealReviewMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
        }
    }

    private void validateReview(AppealReview review) {
        if (review == null) {
            throw new IllegalArgumentException("Appeal review cannot be null");
        }
        if (review.getAppealId() == null) {
            throw new IllegalArgumentException("Appeal ID is required");
        }
    }

    private void validateReviewId(AppealReview review) {
        validateReview(review);
        validateReviewId(review.getReviewId());
    }

    private void validateReviewId(Long reviewId) {
        if (reviewId == null || reviewId <= 0) {
            throw new IllegalArgumentException("Invalid review ID: " + reviewId);
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
