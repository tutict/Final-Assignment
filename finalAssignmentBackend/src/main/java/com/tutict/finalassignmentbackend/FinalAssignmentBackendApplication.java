package com.tutict.finalassignmentbackend;

import com.tutict.finalassignmentbackend.config.docker.RunDocker;
import com.tutict.finalassignmentbackend.config.shell.ShellScriptConfig;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.EnableAspectJAutoProxy;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableAsync
@EnableScheduling
@EnableAspectJAutoProxy
@MapperScan({
        "com.tutict.finalassignmentbackend.mapper",
        "com.tutict.finalassignmentbackend.rag.mapper"
})
@SpringBootApplication
public class FinalAssignmentBackendApplication {

    public static void main(String[] args) {
        new SpringApplicationBuilder(FinalAssignmentBackendApplication.class)
                .initializers(ShellScriptConfig.startupScriptBootstrap())
                .initializers(new RunDocker())
                .run(args);
    }

}
