package com.tutict.finalassignmentcloud.traffic.client;

import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "finalassignmentcloud-system")
public interface SystemRequestHistoryClient {

    @PostMapping("/api/system/requests")
    SysRequestHistory create(@RequestBody SysRequestHistory request,
                             @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);

    @PutMapping("/api/system/requests/{historyId}")
    SysRequestHistory update(@PathVariable("historyId") Long historyId,
                             @RequestBody SysRequestHistory request,
                             @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);

    @DeleteMapping("/api/system/requests/{historyId}")
    void delete(@PathVariable("historyId") Long historyId);

    @GetMapping("/api/system/requests/{historyId}")
    SysRequestHistory get(@PathVariable("historyId") Long historyId);

    @GetMapping("/api/system/requests")
    List<SysRequestHistory> list();

    @GetMapping("/api/system/requests/status")
    List<SysRequestHistory> listByStatus(@RequestParam("status") String status,
                                         @RequestParam(value = "page", defaultValue = "1") int page,
                                         @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/idempotency/{key}")
    SysRequestHistory getByIdempotencyKey(@PathVariable("key") String key);
}
