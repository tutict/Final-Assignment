package com.tutict.finalassignmentcloud.system;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.annotation.FullyQualifiedAnnotationBeanNameGenerator;

@EnableFeignClients
@EnableDiscoveryClient
@MapperScan({
        "com.tutict.finalassignmentcloud.system.mapper",
        "com.tutict.finalassignmentcloud.mapper.appeal",
        "com.tutict.finalassignmentcloud.mapper.offense"
})
@MapperScan(
        basePackages = "com.tutict.finalassignmentcloud.mapper.system",
        nameGenerator = FullyQualifiedAnnotationBeanNameGenerator.class
)
@SpringBootApplication(scanBasePackages = "com.tutict.finalassignmentcloud")
public class FinalAssignmentCloudSystemApplication {

    static void main(String[] args) {
        SpringApplication.run(FinalAssignmentCloudSystemApplication.class, args);
    }
}
