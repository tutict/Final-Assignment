package com.tutict.finalassignmentbackend.config;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.data.elasticsearch.repository.config.EnableElasticsearchRepositories;

import java.util.logging.Level;
import java.util.logging.Logger;

@Configuration
@Profile("!test")
@EnableElasticsearchRepositories(basePackages = "com.tutict.finalassignmentbackend.repository")
public class ElasticSearchConfig {

    private static final Logger LOG = Logger.getLogger(ElasticSearchConfig.class.getName());

    @Value("${app.elasticsearch.startup-sync.enabled:false}")
    private boolean startupSyncEnabled;

    @PostConstruct
    public void describeSyncMode() {
        if (startupSyncEnabled) {
            LOG.log(Level.WARNING,
                    "app.elasticsearch.startup-sync.enabled is ignored. Use CDC or an explicit reindex job instead.");
        }
        LOG.log(Level.INFO,
                "Elasticsearch repositories are enabled. Database-to-Elasticsearch startup full sync is disabled.");
    }
}
