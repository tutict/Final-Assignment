package com.tutict.finalassignmentcloud.system.appeal.domain.idempotency;

import com.tutict.finalassignmentcloud.reliability.HistoryReserve;
import com.tutict.finalassignmentcloud.system.appeal.domain.policy.AppealBusinessPolicy;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.reliability.IdempotencyReplayException;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealIdempotencyService {

    private static final Logger log = Logger.getLogger(AppealIdempotencyService.class.getName());

    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final AppealBusinessPolicy businessPolicy;

    public AppealIdempotencyService(
            SysRequestHistoryMapper sysRequestHistoryMapper,
            AppealBusinessPolicy businessPolicy
    ) {
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.businessPolicy = businessPolicy;
    }

    public void checkAndInsert(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (businessPolicy.isDuplicateRequest(history)) {
            throw new IdempotencyReplayException("Duplicate appeal request detected");
        }
        sysRequestHistoryMapper.insert(buildHistory(idempotencyKey));
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return businessPolicy.shouldSkipProcessedRequest(history);
    }

    public void markPendingSuccess(String idempotencyKey, Long appealId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (!businessPolicy.canUpdateHistory(history)) {
            log.log(Level.WARNING, "Cannot mark pending success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(appealId);
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        Long businessId = appealId;
        if (!HistoryReserve.markSuccess(sysRequestHistoryMapper, idempotencyKey, businessId)) {
            log.log(Level.WARNING, "Idempotency key {0} is not pending, success marking skipped", idempotencyKey);
        }
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        log.log(Level.FINE, "Marking idempotency key {0} as failed: {1}", new Object[]{idempotencyKey, reason});
        if (!HistoryReserve.markFailure(sysRequestHistoryMapper, idempotencyKey)) {
            log.log(Level.WARNING, "Idempotency key {0} is not pending, failure marking skipped", idempotencyKey);
        }
    }

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

}
