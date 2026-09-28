package com.tutict.finalassignmentcloud.reliability;

import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

@AutoConfiguration
@EnableAspectJAutoProxy
@ConditionalOnClass(name = "org.springframework.data.elasticsearch.repository.ElasticsearchRepository")
public class ElasticsearchUnavailableConfiguration {

    @Bean
    ElasticsearchUnavailableGuard elasticsearchUnavailableGuard() {
        return new ElasticsearchUnavailableGuard();
    }
}
