package com.tutict.finalassignmentcloud.audit;

import org.springframework.boot.SpringApplication;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableFeignClients
@EnableDiscoveryClient
@MapperScan("com.tutict.finalassignmentcloud.audit.mapper")
@SpringBootApplication(scanBasePackages = {
        "com.tutict.finalassignmentcloud.audit",
        "com.tutict.finalassignmentcloud.observability"
})
public class FinalAssignmentCloudAuditApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudAuditApplication.class, args);
    }
}

