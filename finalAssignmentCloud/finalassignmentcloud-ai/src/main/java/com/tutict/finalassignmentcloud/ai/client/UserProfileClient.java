package com.tutict.finalassignmentcloud.ai.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;
import java.util.Map;

@FeignClient(name = "finalassignmentcloud-user")
public interface UserProfileClient {
    @GetMapping("/api/users")
    List<Map<String, Object>> users();

    @GetMapping("/api/users/search/username/{username}")
    Map<String, Object> findByUsername(@PathVariable("username") String username);
}
