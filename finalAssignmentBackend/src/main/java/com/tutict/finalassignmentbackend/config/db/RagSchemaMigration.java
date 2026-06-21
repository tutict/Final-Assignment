package com.tutict.finalassignmentbackend.config.db;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
public class RagSchemaMigration implements InitializingBean {

    private static final Logger LOG = Logger.getLogger(RagSchemaMigration.class.getName());

    private final DataSource dataSource;

    public RagSchemaMigration(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void afterPropertiesSet() {
        ResourceDatabasePopulator populator = new ResourceDatabasePopulator(
                new ClassPathResource("rag/rag_schema.sql")
        );
        populator.setContinueOnError(false);
        populator.execute(dataSource);
        LOG.log(Level.INFO, "RAG schema migration completed.");
    }
}
