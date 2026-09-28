package com.tutict.finalassignmentcloud.ai;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableFeignClients
@EnableDiscoveryClient
@SpringBootApplication(scanBasePackages = {
        "com.tutict.finalassignmentcloud.ai",
        "com.tutict.finalassignmentcloud.observability"
})
public class FinalAssignmentCloudAiApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudAiApplication.class, args);
    }
}
