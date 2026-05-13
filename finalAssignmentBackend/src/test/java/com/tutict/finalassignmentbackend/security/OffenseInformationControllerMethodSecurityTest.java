package com.tutict.finalassignmentbackend.security;

import com.tutict.finalassignmentbackend.config.SecurityConfig;
import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.controller.OffenseInformationController;
import com.tutict.finalassignmentbackend.service.OffenseRecordService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.web.SpringJUnitWebConfig;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.util.List;

import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringJUnitWebConfig(classes = OffenseInformationControllerMethodSecurityTest.TestConfig.class)
@TestPropertySource(properties = "jwt.secret.key=MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")
class OffenseInformationControllerMethodSecurityTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private TokenProvider tokenProvider;

    @Autowired
    private OffenseRecordService offenseRecordService;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        reset(offenseRecordService);
        when(offenseRecordService.findAll()).thenReturn(List.of());
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void noTokenRequestReturns401() throws Exception {
        mockMvc.perform(get("/api/offenses"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void wrongRoleTokenReturns403() throws Exception {
        mockMvc.perform(get("/api/offenses")
                        .header("Authorization", bearer("FINANCE")))
                .andExpect(status().isForbidden());
    }

    @Test
    void allowedRoleTokenReturns200() throws Exception {
        mockMvc.perform(get("/api/offenses")
                        .header("Authorization", bearer("TRAFFIC_POLICE")))
                .andExpect(status().isOk());
    }

    private String bearer(String role) {
        return "Bearer " + tokenProvider.createToken("method-security-test", role);
    }

    @Configuration
    @EnableWebMvc
    @EnableWebSecurity
    @Import({SecurityConfig.class, TokenProvider.class})
    static class TestConfig {

        @Bean
        OffenseRecordService offenseRecordService() {
            return Mockito.mock(OffenseRecordService.class);
        }

        @Bean
        OffenseInformationController offenseInformationController(OffenseRecordService offenseRecordService) {
            return new OffenseInformationController(offenseRecordService);
        }
    }
}
