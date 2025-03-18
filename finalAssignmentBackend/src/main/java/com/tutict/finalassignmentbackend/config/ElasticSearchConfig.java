package com.tutict.finalassignmentbackend.config;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.json.jackson.JacksonJsonpMapper;
import co.elastic.clients.transport.ElasticsearchTransport;
import co.elastic.clients.transport.rest_client.RestClientTransport;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.mapper.AppealManagementMapper;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.repository.AppealManagementSearchRepository;
import com.tutict.finalassignmentbackend.repository.DriverInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.VehicleInformationSearchRepository;
import jakarta.annotation.PostConstruct;
import org.apache.http.HttpHost;
import org.elasticsearch.client.RestClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchTemplate;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.repository.config.EnableElasticsearchRepositories;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Configuration
@EnableElasticsearchRepositories(basePackages = "com.tutict.finalassignmentbackend.repository")
public class ElasticSearchConfig {

    private static final Logger log = Logger.getLogger(ElasticSearchConfig.class.getName());

    @Value("${spring-elasticsearch-uris}")
    private String springElasticsearchUris;

    private final VehicleInformationMapper vehicleInformationMapper;
    private final DriverInformationMapper driverInformationMapper;
    private final OffenseInformationMapper offenseInformationMapper;
    private final AppealManagementMapper appealManagementMapper;

    private final @Lazy VehicleInformationSearchRepository vehicleInformationSearchRepository;
    private final @Lazy DriverInformationSearchRepository driverInformationSearchRepository;
    private final @Lazy OffenseInformationSearchRepository offenseInformationSearchRepository;
    private final @Lazy AppealManagementSearchRepository appealManagementSearchRepository;

    public ElasticSearchConfig(
            VehicleInformationMapper vehicleInformationMapper,
            DriverInformationMapper driverInformationMapper,
            OffenseInformationMapper offenseInformationMapper,
            AppealManagementMapper appealManagementMapper,
            @Lazy VehicleInformationSearchRepository vehicleInformationSearchRepository,
            @Lazy DriverInformationSearchRepository driverInformationSearchRepository,
            @Lazy OffenseInformationSearchRepository offenseInformationSearchRepository,
            @Lazy AppealManagementSearchRepository appealManagementSearchRepository) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.driverInformationMapper = driverInformationMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.appealManagementMapper = appealManagementMapper;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
        this.offenseInformationSearchRepository = offenseInformationSearchRepository;
        this.appealManagementSearchRepository = appealManagementSearchRepository;
    }

    @Bean
    public RestClient restClient() {
        return RestClient.builder(HttpHost.create(springElasticsearchUris)).build();
    }

    @Bean
    public ElasticsearchTransport elasticsearchTransport(RestClient restClient) {
        return new RestClientTransport(restClient, new JacksonJsonpMapper());
    }

    @Bean
    public ElasticsearchClient elasticsearchClient(ElasticsearchTransport transport) {
        return new ElasticsearchClient(transport);
    }

    @Bean
    public ElasticsearchOperations elasticsearchTemplate(ElasticsearchClient client) {
        return new ElasticsearchTemplate(client);
    }

    @PostConstruct
    public void syncDatabaseToElasticsearch() {
        log.log(Level.INFO, "Starting synchronization of database to Elasticsearch");

        syncEntities("vehicles", vehicleInformationMapper.selectList(null),
                vehicleInformationSearchRepository, VehicleInformationDocument::fromEntity);

        syncEntities("drivers", driverInformationMapper.selectList(null),
                driverInformationSearchRepository, DriverInformationDocument::fromEntity);

        syncEntities("offenses", offenseInformationMapper.selectList(null),
                offenseInformationSearchRepository, OffenseInformationDocument::fromEntity);

        syncEntities("appeals", appealManagementMapper.selectList(null),
                appealManagementSearchRepository, AppealManagementDocument::fromEntity);

        log.log(Level.INFO, "Completed synchronization of database to Elasticsearch");
    }

    private <T, D> void syncEntities(String entityType, List<T> entities,
                                     org.springframework.data.elasticsearch.repository.ElasticsearchRepository<D, Integer> repository,
                                     java.util.function.Function<T, D> converter) {
        if (entities.isEmpty()) {
            log.log(Level.INFO, "No {0} found in database to sync", entityType);
            return;
        }
        for (T entity : entities) {
            try {
                D document = converter.apply(entity);
                repository.save(document);
                log.log(Level.INFO, "Synced {0} with ID={1} to Elasticsearch", new Object[]{entityType, getId(entity)});
            } catch (Exception e) {
                log.log(Level.SEVERE, "Failed to sync {0} with ID={1}: {2}",
                        new Object[]{entityType, getId(entity), e.getMessage()});
            }
        }
        log.log(Level.INFO, "Completed synchronization of {0} {1} to Elasticsearch", new Object[]{entities.size(), entityType});
    }

    private Integer getId(Object entity) {
        if (entity instanceof VehicleInformation) {
            return ((VehicleInformation) entity).getVehicleId();
        } else if (entity instanceof DriverInformation) {
            return ((DriverInformation) entity).getDriverId();
        } else if (entity instanceof OffenseInformation) {
            return ((OffenseInformation) entity).getOffenseId();
        } else if (entity instanceof AppealManagement) {
            return ((AppealManagement) entity).getAppealId();
        }
        return null;
    }
}