package com.tutict.finalassignmentbackend.controller.business;

import com.tutict.finalassignmentbackend.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentbackend.config.statemachine.states.PaymentState;
import com.tutict.finalassignmentbackend.dto.mapper.PaymentRecordRequestMapper;
import com.tutict.finalassignmentbackend.dto.mapper.PaymentRecordResponseMapper;
import com.tutict.finalassignmentbackend.dto.request.PaymentRecordRequest;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.dto.response.PaymentRecordResponse;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceClassifier;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceLogFactory;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceSource;
import com.tutict.finalassignmentbackend.payment.exception.PaymentDuplicateRequestException;
import com.tutict.finalassignmentbackend.payment.exception.PaymentOptimisticLockException;
import com.tutict.finalassignmentbackend.service.auth.AuthWsService;
import com.tutict.finalassignmentbackend.service.payment.PaymentRecordService;
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
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/payments")
@Tag(name = "Payment Management", description = "罚款支付记录管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "FINANCE"})
public class PaymentRecordController {

    private static final Logger LOG = Logger.getLogger(PaymentRecordController.class.getName());
    private static final Set<String> ELEVATED_ROLES = Set.of(
            "SUPER_ADMIN",
            "ADMIN",
            "FINANCE"
    );

    private final AuthWsService authWsService;
    private final PaymentRecordService paymentRecordService;
    private final PaymentGovernanceClassifier paymentGovernanceClassifier;

    public PaymentRecordController(AuthWsService authWsService, PaymentRecordService paymentRecordService) {
        this.authWsService = authWsService;
        this.paymentRecordService = paymentRecordService;
        this.paymentGovernanceClassifier = new PaymentGovernanceClassifier();
    }

    @PostMapping
    @Operation(summary = "创建支付记录")
    public ResponseEntity<ApiResponse<PaymentRecordResponse>> createPayment(@Valid @RequestBody PaymentRecordRequest request,
                                                                            @RequestHeader(value = "Idempotency-Key", required = false)
                                                                            String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        PaymentRecord paymentRecord = PaymentRecordRequestMapper.toEntity(request);
        try {
            if (useKey) {
                if (paymentRecordService.isDuplicateIdempotencyKey(idempotencyKey)) {
                    logPaymentGovernance(PaymentGovernanceLogFactory.noOpSuppressed(
                            PaymentGovernanceSource.CONTROLLER,
                            paymentGovernanceClassifier.classifyControllerMutation("create", true),
                            paymentRecord,
                            "create",
                            idempotencyKey
                    ));
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED)
                            .body(ApiResponse.ok(null));
                }
                logPaymentGovernance(PaymentGovernanceLogFactory.preMutationKafka(
                        PaymentGovernanceSource.CONTROLLER,
                        paymentGovernanceClassifier.classifyPreMutationKafka("create"),
                        paymentRecord,
                        "create",
                        idempotencyKey
                ));
            }
            logPaymentGovernance(PaymentGovernanceLogFactory.shadowClassification(
                    PaymentGovernanceSource.CONTROLLER,
                    paymentGovernanceClassifier.classifyControllerMutation("create", false),
                    paymentRecord,
                    "create"
            ));
            PaymentRecord saved = useKey
                    ? paymentRecordService.createPaymentRecord(paymentRecord, idempotencyKey)
                    : paymentRecordService.createPaymentRecord(paymentRecord);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.ok(toPaymentResponse(saved)));
        } catch (PaymentDuplicateRequestException ex) {
            return ResponseEntity.status(HttpStatus.ALREADY_REPORTED)
                    .body(ApiResponse.ok(null));
        } catch (RuntimeException ex) {
            if (useKey) {
                paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create payment record failed", ex);
            throw ex;
        }
    }

    @PutMapping("/{paymentId}")
    @Operation(summary = "更新支付记录")
    public ResponseEntity<ApiResponse<PaymentRecordResponse>> updatePayment(@PathVariable Long paymentId,
                                                                            @Valid @RequestBody PaymentRecordRequest request,
                                                                            @RequestHeader(value = "Idempotency-Key", required = false)
                                                                            String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        PaymentRecord paymentRecord = PaymentRecordRequestMapper.toEntity(request);
        try {
            paymentRecord.setPaymentId(paymentId);
            if (useKey) {
                if (paymentRecordService.isDuplicateIdempotencyKey(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED)
                            .body(ApiResponse.ok(null));
                }
                logPaymentGovernance(PaymentGovernanceLogFactory.preMutationKafka(
                        PaymentGovernanceSource.CONTROLLER,
                        paymentGovernanceClassifier.classifyPreMutationKafka("update"),
                        paymentRecord,
                        "update",
                        idempotencyKey
                ));
            }
            logPaymentGovernance(PaymentGovernanceLogFactory.shadowClassification(
                    PaymentGovernanceSource.CONTROLLER,
                    paymentGovernanceClassifier.classifyControllerMutation("update", false),
                    paymentRecord,
                    "update"
            ));
            PaymentRecord updated = useKey
                    ? paymentRecordService.updatePaymentRecord(paymentRecord, idempotencyKey)
                    : paymentRecordService.updatePaymentRecord(paymentRecord);
            return ResponseEntity.ok(ApiResponse.ok(toPaymentResponse(updated)));
        } catch (PaymentDuplicateRequestException ex) {
            return ResponseEntity.status(HttpStatus.ALREADY_REPORTED)
                    .body(ApiResponse.ok(null));
        } catch (RuntimeException ex) {
            if (useKey) {
                paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update payment record failed", ex);
            throw ex;
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
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/{paymentId}")
    @Operation(summary = "查询支付记录详情")
    public ResponseEntity<ApiResponse<PaymentRecordResponse>> getPayment(@PathVariable Long paymentId) {
        PaymentRecord record = paymentRecordService.findById(paymentId);
        return record == null
                ? ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error("PAYMENT_NOT_FOUND", "Payment record not found"))
                : ResponseEntity.ok(ApiResponse.ok(toPaymentResponse(record)));
    }

    @GetMapping
    @Operation(summary = "查询全部支付记录")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> listPayments() {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.findAll())));
    }

    @GetMapping("/fine/{fineId}")
    @Operation(summary = "按罚款记录分页查询支付记录")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> findByFine(@PathVariable Long fineId,
                                                                               @RequestParam(defaultValue = "1") int page,
                                                                               @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.findByFineId(fineId, page, size))));
    }

    @GetMapping("/driver/{driverId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "FINANCE", "USER"})
    @Operation(summary = "按驾驶员查询支付记录")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> findByDriver(
            @PathVariable Long driverId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication) {
        if (!canAccessDriver(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error("FORBIDDEN", "Forbidden"));
        }
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.findByDriverId(driverId, page, size))));
    }

    @PostMapping("/driver/{driverId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "FINANCE", "USER"})
    @Operation(summary = "为当前驾驶员创建支付记录")
    public ResponseEntity<ApiResponse<PaymentRecordResponse>> createDriverPayment(
            @PathVariable Long driverId,
            @Valid @RequestBody PaymentRecordRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            Authentication authentication) {
        if (!canAccessDriver(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error("FORBIDDEN", "Forbidden"));
        }
        request.setDriverId(driverId);
        return createPayment(request, idempotencyKey);
    }

    @GetMapping("/search/payer")
    @Operation(summary = "按缴款人身份证搜索支付记录")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByPayer(@RequestParam("idCard") String idCard,
                                                                                  @RequestParam(defaultValue = "1") int page,
                                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByPayerIdCard(idCard, page, size))));
    }

    @GetMapping("/search/status")
    @Operation(summary = "按支付状态搜索支付记录")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByStatus(@RequestParam String status,
                                                                                   @RequestParam(defaultValue = "1") int page,
                                                                                   @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByPaymentStatus(status, page, size))));
    }

    @GetMapping("/search/transaction")
    @Operation(summary = "按交易流水号搜索支付记录")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByTransaction(@RequestParam String transactionId,
                                                                                       @RequestParam(defaultValue = "1") int page,
                                                                                       @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByTransactionId(transactionId, page, size))));
    }

    @GetMapping("/search/payment-number")
    @Operation(summary = "Search payment records by payment number")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByPaymentNumber(@RequestParam String paymentNumber,
                                                                                         @RequestParam(defaultValue = "1") int page,
                                                                                         @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByPaymentNumber(paymentNumber, page, size))));
    }

    @GetMapping("/search/payer-name")
    @Operation(summary = "Search payment records by payer name")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByPayerName(@RequestParam String payerName,
                                                                                      @RequestParam(defaultValue = "1") int page,
                                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByPayerName(payerName, page, size))));
    }

    @GetMapping("/search/payment-method")
    @Operation(summary = "Search payment records by payment method")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByPaymentMethod(@RequestParam String paymentMethod,
                                                                                         @RequestParam(defaultValue = "1") int page,
                                                                                         @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByPaymentMethod(paymentMethod, page, size))));
    }

    @GetMapping("/search/payment-channel")
    @Operation(summary = "Search payment records by payment channel")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByPaymentChannel(@RequestParam String paymentChannel,
                                                                                          @RequestParam(defaultValue = "1") int page,
                                                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByPaymentChannel(paymentChannel, page, size))));
    }

    @GetMapping("/search/time-range")
    @Operation(summary = "Search payment records by payment time range")
    public ResponseEntity<ApiResponse<List<PaymentRecordResponse>>> searchByTimeRange(@RequestParam String startTime,
                                                                                      @RequestParam String endTime,
                                                                                      @RequestParam(defaultValue = "1") int page,
                                                                                      @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toPaymentResponses(paymentRecordService.searchByPaymentTimeRange(startTime, endTime, page, size))));
    }

    @PutMapping("/{paymentId}/status/{state}")
    @Operation(summary = "更新支付记录状态")
    public ResponseEntity<ApiResponse<Void>> updatePaymentStatus(@PathVariable Long paymentId,
                                                                 @PathVariable PaymentState state,
                                                                 @RequestHeader(value = "Idempotency-Key", required = true)
                                                                 String idempotencyKey) {
        try {
            if (paymentRecordService.isDuplicateIdempotencyKey(idempotencyKey)) {
                return ResponseEntity.status(HttpStatus.ALREADY_REPORTED)
                        .body(ApiResponse.ok(null));
            }
            paymentRecordService.updatePaymentStatus(paymentId, state, idempotencyKey);
            return ResponseEntity.ok(ApiResponse.ok(null));
        } catch (PaymentDuplicateRequestException ex) {
            return ResponseEntity.status(HttpStatus.ALREADY_REPORTED)
                    .body(ApiResponse.ok(null));
        } catch (RuntimeException ex) {
            paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            LOG.log(Level.WARNING, "Update payment status failed", ex);
            throw ex;
        }
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private boolean canAccessDriver(Authentication authentication, Long driverId) {
        if (authentication == null || driverId == null) {
            return false;
        }
        boolean elevated = SecurityRoleUtils.hasAnyRole(authentication, ELEVATED_ROLES);
        if (elevated) {
            return true;
        }
        boolean regularUser = SecurityRoleUtils.hasRole(authentication, "USER");
        if (!regularUser) {
            return false;
        }
        UserProfileResponse profile = authWsService.getCurrentUserProfile(authentication.getName());
        return Objects.equals(profile.getDriverId(), driverId);
    }

    private void logPaymentGovernance(String payload) {
        LOG.log(Level.INFO, payload);
    }

    private PaymentRecordResponse toPaymentResponse(PaymentRecord record) {
        return PaymentRecordResponseMapper.toResponse(record);
    }

    private List<PaymentRecordResponse> toPaymentResponses(List<PaymentRecord> records) {
        if (records == null || records.isEmpty()) {
            return List.of();
        }
        return records.stream()
                .map(this::toPaymentResponse)
                .toList();
    }
}
