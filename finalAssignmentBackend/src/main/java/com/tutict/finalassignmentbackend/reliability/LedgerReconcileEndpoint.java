package com.tutict.finalassignmentbackend.reliability;

import java.util.Map;
import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.WriteOperation;
import org.springframework.stereotype.Component;

@Component
@Endpoint(id = "ledgerReconcile")
public class LedgerReconcileEndpoint {

    private final LedgerReconciliationService reconciliationService;

    public LedgerReconcileEndpoint(LedgerReconciliationService reconciliationService) {
        this.reconciliationService = reconciliationService;
    }

    @WriteOperation
    public Map<String, Integer> reconcile() {
        return Map.of("updated", reconciliationService.reconcileStaleProcessing());
    }
}