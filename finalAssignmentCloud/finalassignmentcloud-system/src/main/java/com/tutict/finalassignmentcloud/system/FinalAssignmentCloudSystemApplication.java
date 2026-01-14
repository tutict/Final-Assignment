package com.tutict.finalassignmentcloud.system;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableFeignClients
@EnableDiscoveryClient
@SpringBootApplication(scanBasePackages = "com.tutict.finalassignmentcloud")
public class FinalAssignmentCloudSystemApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudSystemApplication.class, args);
    }
}

