package com.tutict.finalassignmentcloud.traffic;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;

@EnableFeignClients
@EnableDiscoveryClient
@MapperScan("com.tutict.finalassignmentcloud.traffic.mapper")
@SpringBootApplication
@ComponentScan(
        basePackages = "com.tutict.finalassignmentcloud",
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = com.tutict.finalassignmentcloud.config.db.AccountDriverSchemaMigration.class
        )
)
public class FinalAssignmentCloudTrafficApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudTrafficApplication.class, args);
    }
}
