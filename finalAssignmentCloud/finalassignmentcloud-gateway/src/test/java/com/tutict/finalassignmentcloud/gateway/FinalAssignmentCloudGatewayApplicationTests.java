package com.tutict.finalassignmentcloud.gateway;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

// dev profile 与实际部署一致；base 配置的 nacos import 需带 dataId 才能被解析
@SpringBootTest
@ActiveProfiles("dev")
class FinalAssignmentCloudGatewayApplicationTests {

    @Test
    void contextLoads() {
    }
}
