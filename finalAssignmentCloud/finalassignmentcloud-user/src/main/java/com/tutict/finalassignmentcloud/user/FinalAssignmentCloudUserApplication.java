package com.tutict.finalassignmentcloud.user;

import org.springframework.boot.SpringApplication;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableFeignClients
@EnableDiscoveryClient
@MapperScan("com.tutict.finalassignmentcloud.user.mapper")
@SpringBootApplication(scanBasePackages = "com.tutict.finalassignmentcloud")
public class FinalAssignmentCloudUserApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudUserApplication.class, args);
    }
}

