package com.tutict.finalassignmentcloud.audit.client;

import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "finalassignmentcloud-system")
public interface SystemRequestHistoryClient {

    @GetMapping("/api/system/requests/{historyId}")
    SysRequestHistory get(@PathVariable("historyId") Long historyId);

    @GetMapping("/api/system/requests")
    List<SysRequestHistory> list();

    @GetMapping("/api/system/requests/search/idempotency")
    List<SysRequestHistory> searchByIdempotency(@RequestParam("key") String key,
                                                @RequestParam(value = "page", defaultValue = "1") int page,
                                                @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/method")
    List<SysRequestHistory> searchByRequestMethod(@RequestParam("requestMethod") String requestMethod,
                                                  @RequestParam(value = "page", defaultValue = "1") int page,
                                                  @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/url")
    List<SysRequestHistory> searchByRequestUrl(@RequestParam("requestUrl") String requestUrl,
                                               @RequestParam(value = "page", defaultValue = "1") int page,
                                               @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/business-type")
    List<SysRequestHistory> searchByBusinessType(@RequestParam("businessType") String businessType,
                                                 @RequestParam(value = "page", defaultValue = "1") int page,
                                                 @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/business-id")
    List<SysRequestHistory> searchByBusinessId(@RequestParam("businessId") Long businessId,
                                               @RequestParam(value = "page", defaultValue = "1") int page,
                                               @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/status")
    List<SysRequestHistory> searchByBusinessStatus(@RequestParam("status") String status,
                                                   @RequestParam(value = "page", defaultValue = "1") int page,
                                                   @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/user")
    List<SysRequestHistory> searchByUser(@RequestParam("userId") Long userId,
                                         @RequestParam(value = "page", defaultValue = "1") int page,
                                         @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/ip")
    List<SysRequestHistory> searchByRequestIp(@RequestParam("requestIp") String requestIp,
                                              @RequestParam(value = "page", defaultValue = "1") int page,
                                              @RequestParam(value = "size", defaultValue = "20") int size);

    @GetMapping("/api/system/requests/search/time-range")
    List<SysRequestHistory> searchByCreatedTimeRange(@RequestParam("startTime") String startTime,
                                                     @RequestParam("endTime") String endTime,
                                                     @RequestParam(value = "page", defaultValue = "1") int page,
                                                     @RequestParam(value = "size", defaultValue = "20") int size);
}
