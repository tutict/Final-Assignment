package com.tutict.finalassignmentcloud.rag;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableCaching
@EnableScheduling
@EnableDiscoveryClient
@MapperScan("com.tutict.finalassignmentcloud.rag.mapper")
@SpringBootApplication(scanBasePackages = "com.tutict.finalassignmentcloud")
public class FinalAssignmentCloudRagApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudRagApplication.class, args);
    }
}
