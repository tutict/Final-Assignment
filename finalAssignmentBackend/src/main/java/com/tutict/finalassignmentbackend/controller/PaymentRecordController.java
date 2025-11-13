package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.config.statemachine.states.PaymentState;
import com.tutict.finalassignmentbackend.entity.PaymentRecord;
import com.tutict.finalassignmentbackend.service.PaymentRecordService;
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
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/payments")
@Tag(name = "Payment Management", description = "罚款支付记录管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "FINANCE"})
public class PaymentRecordController {

    private static final Logger LOG = Logger.getLogger(PaymentRecordController.class.getName());

    private final PaymentRecordService paymentRecordService;

    public PaymentRecordController(PaymentRecordService paymentRecordService) {
        this.paymentRecordService = paymentRecordService;
    }

    @PostMapping
    @Operation(summary = "创建支付记录")
    public ResponseEntity<PaymentRecord> createPayment(@RequestBody PaymentRecord request,
                                                       @RequestHeader(value = "Idempotency-Key", required = false)
                                                       String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (paymentRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                paymentRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            PaymentRecord saved = paymentRecordService.createPaymentRecord(request);
            if (useKey && saved.getPaymentId() != null) {
                paymentRecordService.markHistorySuccess(idempotencyKey, saved.getPaymentId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create payment record failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{paymentId}")
    @Operation(summary = "更新支付记录")
    public ResponseEntity<PaymentRecord> updatePayment(@PathVariable Long paymentId,
                                                       @RequestBody PaymentRecord request,
                                                       @RequestHeader(value = "Idempotency-Key", required = false)
                                                       String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setPaymentId(paymentId);
            if (useKey) {
                paymentRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            PaymentRecord updated = paymentRecordService.updatePaymentRecord(request);
            if (useKey && updated.getPaymentId() != null) {
                paymentRecordService.markHistorySuccess(idempotencyKey, updated.getPaymentId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update payment record failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{paymentId}")
    @Operation(summary = "删除支付记录")
    public ResponseEntity<Void> deletePayment(@PathVariable Long paymentId) {
        try {
            paymentRecordService.deletePaymentRecord(paymentId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete payment record failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{paymentId}")
    @Operation(summary = "查询支付记录详情")
    public ResponseEntity<PaymentRecord> getPayment(@PathVariable Long paymentId) {
        PaymentRecord record = paymentRecordService.findById(paymentId);
        return record == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(record);
    }

    @GetMapping
    @Operation(summary = "查询全部支付记录")
    public ResponseEntity<List<PaymentRecord>> listPayments() {
        return ResponseEntity.ok(paymentRecordService.findAll());
    }

    @GetMapping("/fine/{fineId}")
    @Operation(summary = "按罚款记录分页查询支付记录")
    public ResponseEntity<List<PaymentRecord>> findByFine(@PathVariable Long fineId,
                                                          @RequestParam(defaultValue = "1") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(paymentRecordService.findByFineId(fineId, page, size));
    }

    @GetMapping("/search/payer")
    @Operation(summary = "按缴款人身份证搜索支付记录")
    public ResponseEntity<List<PaymentRecord>> searchByPayer(@RequestParam("idCard") String idCard,
                                                             @RequestParam(defaultValue = "1") int page,
                                                             @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(paymentRecordService.searchByPayerIdCard(idCard, page, size));
    }

    @GetMapping("/search/status")
    @Operation(summary = "按支付状态搜索支付记录")
    public ResponseEntity<List<PaymentRecord>> searchByStatus(@RequestParam String status,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(paymentRecordService.searchByPaymentStatus(status, page, size));
    }

    @GetMapping("/search/transaction")
    @Operation(summary = "按交易流水号搜索支付记录")
    public ResponseEntity<List<PaymentRecord>> searchByTransaction(@RequestParam String transactionId,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(paymentRecordService.searchByTransactionId(transactionId, page, size));
    }

    @PutMapping("/{paymentId}/status/{state}")
    @Operation(summary = "更新支付记录状态")
    public ResponseEntity<PaymentRecord> updatePaymentStatus(@PathVariable Long paymentId,
                                                             @PathVariable PaymentState state) {
        try {
            PaymentRecord updated = paymentRecordService.updatePaymentStatus(paymentId, state);
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Update payment status failed", ex);
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

