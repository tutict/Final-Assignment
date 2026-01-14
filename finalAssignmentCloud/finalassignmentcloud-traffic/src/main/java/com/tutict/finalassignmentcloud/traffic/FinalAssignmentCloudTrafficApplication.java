package com.tutict.finalassignmentcloud.traffic;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableFeignClients
@EnableDiscoveryClient
@SpringBootApplication(scanBasePackages = "com.tutict.finalassignmentcloud")
public class FinalAssignmentCloudTrafficApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudTrafficApplication.class, args);
    }
}

