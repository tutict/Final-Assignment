package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.NetWorkHandler;
import com.tutict.finalassignmentbackend.service.events.AppealStatusChangedEvent;
import com.tutict.finalassignmentbackend.service.events.PaymentStatusChangedEvent;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class BusinessEventPushService {

    private final NetWorkHandler netWorkHandler;

    public BusinessEventPushService(NetWorkHandler netWorkHandler) {
        this.netWorkHandler = netWorkHandler;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onAppealStatusChanged(AppealStatusChangedEvent event) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("type", "APPEAL_STATUS_CHANGED");
        payload.put("appealId", event.appealId());
        payload.put("newStatus", event.newStatus());
        payload.put("updatedAt", formatTime(event.updatedAt()));
        netWorkHandler.pushToUser(event.applicantUserId(), withoutNullValues(payload));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPaymentStatusChanged(PaymentStatusChangedEvent event) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("type", "PAYMENT_STATUS_CHANGED");
        payload.put("paymentId", event.paymentId());
        payload.put("fineId", event.fineId());
        payload.put("newStatus", event.newStatus());
        payload.put("updatedAt", formatTime(event.updatedAt()));
        netWorkHandler.pushToUser(event.payerUserId(), withoutNullValues(payload));
    }

    public void pushAsyncFailure(String userId, String topic, String message) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("type", "ASYNC_OPERATION_FAILED");
        payload.put("topic", topic);
        payload.put("message", message);
        payload.put("updatedAt", LocalDateTime.now().toString());
        netWorkHandler.pushToUser(userId, withoutNullValues(payload));
    }

    private Map<String, Object> withoutNullValues(Map<String, Object> payload) {
        Map<String, Object> result = new LinkedHashMap<>();
        payload.forEach((key, value) -> {
            if (value != null) {
                result.put(key, value);
            }
        });
        return result;
    }

    private String formatTime(LocalDateTime value) {
        return value == null ? LocalDateTime.now().toString() : value.toString();
    }
}
