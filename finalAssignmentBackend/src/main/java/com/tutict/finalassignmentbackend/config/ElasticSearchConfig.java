package com.tutict.finalassignmentbackend.config;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.json.jackson.JacksonJsonpMapper;
import co.elastic.clients.transport.ElasticsearchTransport;
import co.elastic.clients.transport.rest_client.RestClientTransport;
import com.tutict.finalassignmentbackend.entity.*;
import com.tutict.finalassignmentbackend.entity.elastic.*;
import com.tutict.finalassignmentbackend.mapper.*;
import com.tutict.finalassignmentbackend.repository.*;
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

    // Mappers
    private final VehicleInformationMapper vehicleInformationMapper;
    private final DriverInformationMapper driverInformationMapper;
    private final OffenseInformationMapper offenseInformationMapper;
    private final AppealManagementMapper appealManagementMapper;
    private final FineInformationMapper fineInformationMapper;
    private final DeductionInformationMapper deductionInformationMapper;
    private final OffenseDetailsMapper offenseDetailsMapper;
    private final UserManagementMapper userManagementMapper;
    private final LoginLogMapper loginLogMapper;
    private final OperationLogMapper operationLogMapper;
    private final SystemLogsMapper systemLogsMapper;

    // Repositories (Lazy-loaded to avoid circular dependencies)
    private final @Lazy VehicleInformationSearchRepository vehicleInformationSearchRepository;
    private final @Lazy DriverInformationSearchRepository driverInformationSearchRepository;
    private final @Lazy OffenseInformationSearchRepository offenseInformationSearchRepository;
    private final @Lazy AppealManagementSearchRepository appealManagementSearchRepository;
    private final @Lazy FineInformationSearchRepository fineInformationSearchRepository;
    private final @Lazy DeductionInformationSearchRepository deductionInformationSearchRepository;
    private final @Lazy OffenseDetailsSearchRepository offenseDetailsSearchRepository;
    private final @Lazy UserManagementSearchRepository userManagementSearchRepository;
    private final @Lazy LoginLogSearchRepository loginLogSearchRepository;
    private final @Lazy OperationLogSearchRepository operationLogSearchRepository;
    private final @Lazy SystemLogsSearchRepository systemLogsSearchRepository;

    public ElasticSearchConfig(
            VehicleInformationMapper vehicleInformationMapper,
            DriverInformationMapper driverInformationMapper,
            OffenseInformationMapper offenseInformationMapper,
            AppealManagementMapper appealManagementMapper,
            FineInformationMapper fineInformationMapper,
            DeductionInformationMapper deductionInformationMapper,
            OffenseDetailsMapper offenseDetailsMapper,
            UserManagementMapper userManagementMapper,
            LoginLogMapper loginLogMapper,
            OperationLogMapper operationLogMapper,
            SystemLogsMapper systemLogsMapper,
            @Lazy VehicleInformationSearchRepository vehicleInformationSearchRepository,
            @Lazy DriverInformationSearchRepository driverInformationSearchRepository,
            @Lazy OffenseInformationSearchRepository offenseInformationSearchRepository,
            @Lazy AppealManagementSearchRepository appealManagementSearchRepository,
            @Lazy FineInformationSearchRepository fineInformationSearchRepository,
            @Lazy DeductionInformationSearchRepository deductionInformationSearchRepository,
            @Lazy OffenseDetailsSearchRepository offenseDetailsSearchRepository,
            @Lazy UserManagementSearchRepository userManagementSearchRepository,
            @Lazy LoginLogSearchRepository loginLogSearchRepository,
            @Lazy OperationLogSearchRepository operationLogSearchRepository,
            @Lazy SystemLogsSearchRepository systemLogsSearchRepository) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.driverInformationMapper = driverInformationMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.appealManagementMapper = appealManagementMapper;
        this.fineInformationMapper = fineInformationMapper;
        this.deductionInformationMapper = deductionInformationMapper;
        this.offenseDetailsMapper = offenseDetailsMapper;
        this.userManagementMapper = userManagementMapper;
        this.loginLogMapper = loginLogMapper;
        this.operationLogMapper = operationLogMapper;
        this.systemLogsMapper = systemLogsMapper;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
        this.offenseInformationSearchRepository = offenseInformationSearchRepository;
        this.appealManagementSearchRepository = appealManagementSearchRepository;
        this.fineInformationSearchRepository = fineInformationSearchRepository;
        this.deductionInformationSearchRepository = deductionInformationSearchRepository;
        this.offenseDetailsSearchRepository = offenseDetailsSearchRepository;
        this.userManagementSearchRepository = userManagementSearchRepository;
        this.loginLogSearchRepository = loginLogSearchRepository;
        this.operationLogSearchRepository = operationLogSearchRepository;
        this.systemLogsSearchRepository = systemLogsSearchRepository;
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

        syncEntities("fines", fineInformationMapper.selectList(null),
                fineInformationSearchRepository, FineInformationDocument::fromEntity);

        syncEntities("deductions", deductionInformationMapper.selectList(null),
                deductionInformationSearchRepository, DeductionInformationDocument::fromEntity);

        syncEntities("offense_details", offenseDetailsMapper.selectList(null),
                offenseDetailsSearchRepository, OffenseDetailsDocument::fromEntity);

        syncEntities("users", userManagementMapper.selectList(null),
                userManagementSearchRepository, UserManagementDocument::fromEntity);

        syncEntities("login_logs", loginLogMapper.selectList(null),
                loginLogSearchRepository, LoginLogDocument::fromEntity);

        syncEntities("operation_logs", operationLogMapper.selectList(null),
                operationLogSearchRepository, OperationLogDocument::fromEntity);

        syncEntities("system_logs", systemLogsMapper.selectList(null),
                systemLogsSearchRepository, SystemLogsDocument::fromEntity);

        log.log(Level.INFO, "Completed synchronization of database to Elasticsearch");
    }

    private <T, D> void syncEntities(String entityType, List<T> entities,
                                     org.springframework.data.elasticsearch.repository.ElasticsearchRepository<D, Integer> repository,
                                     java.util.function.Function<T, D> converter) {
        if (entities == null || entities.isEmpty()) {
            log.log(Level.INFO, "No {0} found in database to sync", entityType);
            return;
        }
        for (T entity : entities) {
            try {
                D document = converter.apply(entity);
                if (document != null) {
                    repository.save(document);
                    log.log(Level.INFO, "Synced {0} with ID={1} to Elasticsearch", new Object[]{entityType, getId(entity)});
                } else {
                    log.log(Level.WARNING, "Failed to convert {0} with ID={1} to document", new Object[]{entityType, getId(entity)});
                }
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
        } else if (entity instanceof DeductionInformation) {
            return ((DeductionInformation) entity).getDeductionId();
        } else if (entity instanceof FineInformation) {
            return ((FineInformation) entity).getFineId();
        } else if (entity instanceof OffenseDetails) {
            return ((OffenseDetails) entity).getOffenseId();
        } else if (entity instanceof UserManagement) {
            return ((UserManagement) entity).getUserId();
        } else if (entity instanceof LoginLog) {
            return ((LoginLog) entity).getLogId();
        } else if (entity instanceof OperationLog) {
            return ((OperationLog) entity).getLogId();
        } else if (entity instanceof SystemLogs) {
            return ((SystemLogs) entity).getLogId();
        }
        return null;
    }
}