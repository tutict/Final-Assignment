package com.tutict.finalassignmentcloud.audit;

import org.springframework.boot.SpringApplication;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableFeignClients
@EnableDiscoveryClient
@MapperScan("com.tutict.finalassignmentcloud.audit.mapper")
@SpringBootApplication
public class FinalAssignmentCloudAuditApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudAuditApplication.class, args);
    }
}

