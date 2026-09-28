package com.tutict.finalassignmentcloud.search;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableFeignClients
@EnableDiscoveryClient
@SpringBootApplication(scanBasePackages = {
        "com.tutict.finalassignmentcloud.search",
        "com.tutict.finalassignmentcloud.observability"
})
public class FinalAssignmentCloudSearchApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudSearchApplication.class, args);
    }
}
