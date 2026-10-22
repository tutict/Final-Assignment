package com.tutict.finalassignmentcloud.auth.reliability;

import com.tutict.finalassignmentcloud.auth.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.reliability.HistoryReserve;
import org.springframework.stereotype.Service;

/**
 * 注册链路的幂等台账。写入的是与其它模块共用的 {@code sys_request_history} 表，
 * 因此注册与其它写接口遵循同一套“预留 → 副作用 → 标记成功”的约定。
 */
@Service
public class RegistrationIdempotencyService {

    private static final String BUSINESS_TYPE = "USER_REGISTRATION";

    private final SysRequestHistoryMapper mapper;
    private final RegistrationFingerprint fingerprint;

    public RegistrationIdempotencyService(SysRequestHistoryMapper mapper, RegistrationFingerprint fingerprint) {
        this.mapper = mapper;
        this.fingerprint = fingerprint;
    }

    /**
     * 预留幂等键。同一把键重复提交时按台账既有状态区分：同键异内容是冲突，
     * 同一份请求已完成是重放，仍在处理中则拒绝重入。
     */
    public void reserve(String idempotencyKey, String username, String password) {
        HistoryReserve.reserve(mapper, idempotencyKey, BUSINESS_TYPE, fingerprint.fingerprint(username, password));
    }

    public void markSuccess(String idempotencyKey, Long userId) {
        HistoryReserve.markSuccess(mapper, idempotencyKey, userId);
    }
}
