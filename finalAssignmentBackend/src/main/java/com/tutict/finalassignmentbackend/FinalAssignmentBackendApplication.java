package com.tutict.finalassignmentbackend;

import com.tutict.finalassignmentbackend.config.docker.RunDocker;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.EnableAspectJAutoProxy;
import org.springframework.scheduling.annotation.EnableAsync;

@EnableAsync
@EnableAspectJAutoProxy
@SpringBootApplication
public class FinalAssignmentBackendApplication {

    public static void main(String[] args) {
        new SpringApplicationBuilder(FinalAssignmentBackendApplication.class)
                .initializers(new RunDocker())
                .run(args);
    }

}
