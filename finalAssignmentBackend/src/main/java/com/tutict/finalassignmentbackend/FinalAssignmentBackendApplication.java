package com.tutict.finalassignmentbackend;

import io.vertx.core.Vertx;
import jakarta.annotation.PostConstruct;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class FinalAssignmentBackendApplication {

    private final Vertx vertx;

    public FinalAssignmentBackendApplication(Vertx vertx) {
        this.vertx = vertx;
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
