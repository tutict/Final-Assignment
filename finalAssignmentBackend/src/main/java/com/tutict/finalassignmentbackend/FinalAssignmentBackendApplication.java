package com.tutict.finalassignmentbackend;

import com.tutict.finalassignmentbackend.config.vertx.KafkaVerticle;
import io.vertx.core.Vertx;
import io.vertx.kafka.client.consumer.KafkaConsumer;
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
    public KafkaVerticle kafkaVerticle(KafkaConsumer<String, String> kafkaConsumer) {
        // 通过Spring容器注入Vertx和KafkaConsumer的实例
        return new KafkaVerticle(vertx, kafkaConsumer);
    }



    public static void main(String[] args) {
        SpringApplication.run(FinalAssignmentBackendApplication.class, args);
    }

     @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins("*")
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .exposedHeaders("Authorization")
                        .allowCredentials(true)
                        .maxAge(3600);
            }
        };
    }
}