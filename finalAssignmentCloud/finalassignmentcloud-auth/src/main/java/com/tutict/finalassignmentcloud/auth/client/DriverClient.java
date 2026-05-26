package com.tutict.finalassignmentcloud.auth.client;

import com.tutict.finalassignmentcloud.entity.DriverInformation;
import com.tutict.finalassignmentcloud.entity.SysUser;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(name = "finalassignmentcloud-traffic")
public interface DriverClient {

    @PostMapping("/api/drivers/internal/linked")
    DriverInformation findOrCreateLinkedDriver(@RequestBody SysUser user);
}
