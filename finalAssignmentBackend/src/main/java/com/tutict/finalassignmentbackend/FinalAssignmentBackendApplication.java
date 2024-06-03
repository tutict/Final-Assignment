package com.tutict.finalassignmentbackend;

import io.vertx.core.Vertx;
import jakarta.annotation.PostConstruct;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@SpringBootApplication
public class FinalAssignmentBackendApplication {

    private final Vertx vertx;

    public FinalAssignmentBackendApplication(Vertx vertx) {
        this.vertx = vertx;
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins("http://localhost:8082") // 根据需求设置允许的来源
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .exposedHeaders("Authorization")
                        .allowCredentials(true)
                        .maxAge(3600);
            }
        };
    }


    @PostConstruct
    public void deployVerticles() {
        vertx.deployVerticle("com.tutict.finalassignmentbackend.config.vertx.WebSocketServer", res -> {
            if (res.succeeded()) {
                System.out.println("WebSocket server deployed successfully.");
            } else {
                System.err.println("Failed to deploy WebSocket server: " + res.cause().getMessage());
            }
        });
    }

    public static void main(String[] args) {
        SpringApplication.run(FinalAssignmentBackendApplication.class, args);
    }
}
