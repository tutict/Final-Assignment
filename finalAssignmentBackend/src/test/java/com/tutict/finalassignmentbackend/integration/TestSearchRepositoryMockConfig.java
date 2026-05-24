package com.tutict.finalassignmentbackend.integration;

import com.tutict.finalassignmentbackend.repository.AppealRecordSearchRepository;
import com.tutict.finalassignmentbackend.repository.AppealReviewSearchRepository;
import com.tutict.finalassignmentbackend.repository.AuditLoginLogSearchRepository;
import com.tutict.finalassignmentbackend.repository.AuditOperationLogSearchRepository;
import com.tutict.finalassignmentbackend.repository.DeductionRecordSearchRepository;
import com.tutict.finalassignmentbackend.repository.DriverInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.DriverVehicleSearchRepository;
import com.tutict.finalassignmentbackend.repository.FineRecordSearchRepository;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.OffenseTypeDictSearchRepository;
import com.tutict.finalassignmentbackend.repository.PaymentRecordSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysBackupRestoreSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysDictSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysPermissionSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysRequestHistorySearchRepository;
import com.tutict.finalassignmentbackend.repository.SysRolePermissionSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysRoleSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysSettingsSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysUserRoleSearchRepository;
import com.tutict.finalassignmentbackend.repository.SysUserSearchRepository;
import com.tutict.finalassignmentbackend.repository.VehicleInformationSearchRepository;
import com.tutict.finalassignmentbackend.service.ai.ChatAgent;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.mockito.Mockito;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.cache.CacheManager;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@TestConfiguration
public class TestSearchRepositoryMockConfig {

    @Bean
    ConsumerFactory<String, String> consumerFactory() {
        return Mockito.mock(ConsumerFactory.class);
    }

    @Bean
    ChatAgent chatAgent() {
        return Mockito.mock(ChatAgent.class);
    }

    @Bean
    @Primary
    CacheManager cacheManager() {
        return new ConcurrentMapCacheManager();
    }

    @Bean
    @Primary
    @SuppressWarnings("unchecked")
    RedisTemplate<String, Object> redisTemplate() {
        RedisTemplate<String, Object> redisTemplate = Mockito.mock(RedisTemplate.class);
        ValueOperations<String, Object> valueOperations = Mockito.mock(ValueOperations.class);
        Set<String> keys = ConcurrentHashMap.newKeySet();

        Mockito.when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        Mockito.doAnswer(invocation -> {
            keys.add(invocation.getArgument(0));
            return null;
        }).when(valueOperations).set(
                Mockito.anyString(),
                Mockito.any(),
                Mockito.anyLong(),
                Mockito.any(TimeUnit.class));
        Mockito.when(redisTemplate.hasKey(Mockito.anyString()))
                .thenAnswer(invocation -> keys.contains(invocation.getArgument(0)));
        return redisTemplate;
    }

    @Bean
    @Primary
    @SuppressWarnings({"rawtypes", "unchecked"})
    KafkaTemplate kafkaTemplate() {
        KafkaTemplate kafkaTemplate = Mockito.mock(KafkaTemplate.class);
        SendResult sendResult = Mockito.mock(SendResult.class);
        RecordMetadata metadata = Mockito.mock(RecordMetadata.class);
        Mockito.when(metadata.partition()).thenReturn(0);
        Mockito.when(metadata.offset()).thenReturn(0L);
        Mockito.when(sendResult.getRecordMetadata()).thenReturn(metadata);
        Mockito.when(kafkaTemplate.send(Mockito.anyString(), Mockito.any(), Mockito.any()))
                .thenReturn(CompletableFuture.completedFuture(sendResult));
        return kafkaTemplate;
    }

    @Bean
    AppealRecordSearchRepository appealRecordSearchRepository() {
        return Mockito.mock(AppealRecordSearchRepository.class);
    }

    @Bean
    AppealReviewSearchRepository appealReviewSearchRepository() {
        return Mockito.mock(AppealReviewSearchRepository.class);
    }

    @Bean
    AuditLoginLogSearchRepository auditLoginLogSearchRepository() {
        return Mockito.mock(AuditLoginLogSearchRepository.class);
    }

    @Bean
    AuditOperationLogSearchRepository auditOperationLogSearchRepository() {
        return Mockito.mock(AuditOperationLogSearchRepository.class);
    }

    @Bean
    DeductionRecordSearchRepository deductionRecordSearchRepository() {
        return Mockito.mock(DeductionRecordSearchRepository.class);
    }

    @Bean
    DriverInformationSearchRepository driverInformationSearchRepository() {
        return Mockito.mock(DriverInformationSearchRepository.class);
    }

    @Bean
    DriverVehicleSearchRepository driverVehicleSearchRepository() {
        return Mockito.mock(DriverVehicleSearchRepository.class);
    }

    @Bean
    FineRecordSearchRepository fineRecordSearchRepository() {
        return Mockito.mock(FineRecordSearchRepository.class);
    }

    @Bean
    OffenseInformationSearchRepository offenseInformationSearchRepository() {
        return Mockito.mock(OffenseInformationSearchRepository.class);
    }

    @Bean
    OffenseTypeDictSearchRepository offenseTypeDictSearchRepository() {
        return Mockito.mock(OffenseTypeDictSearchRepository.class);
    }

    @Bean
    PaymentRecordSearchRepository paymentRecordSearchRepository() {
        return Mockito.mock(PaymentRecordSearchRepository.class);
    }

    @Bean
    SysBackupRestoreSearchRepository sysBackupRestoreSearchRepository() {
        return Mockito.mock(SysBackupRestoreSearchRepository.class);
    }

    @Bean
    SysDictSearchRepository sysDictSearchRepository() {
        return Mockito.mock(SysDictSearchRepository.class);
    }

    @Bean
    SysPermissionSearchRepository sysPermissionSearchRepository() {
        return Mockito.mock(SysPermissionSearchRepository.class);
    }

    @Bean
    SysRequestHistorySearchRepository sysRequestHistorySearchRepository() {
        return Mockito.mock(SysRequestHistorySearchRepository.class);
    }

    @Bean
    SysRolePermissionSearchRepository sysRolePermissionSearchRepository() {
        return Mockito.mock(SysRolePermissionSearchRepository.class);
    }

    @Bean
    SysRoleSearchRepository sysRoleSearchRepository() {
        return Mockito.mock(SysRoleSearchRepository.class);
    }

    @Bean
    SysSettingsSearchRepository sysSettingsSearchRepository() {
        return Mockito.mock(SysSettingsSearchRepository.class);
    }

    @Bean
    SysUserRoleSearchRepository sysUserRoleSearchRepository() {
        return Mockito.mock(SysUserRoleSearchRepository.class);
    }

    @Bean
    SysUserSearchRepository sysUserSearchRepository() {
        return Mockito.mock(SysUserSearchRepository.class);
    }

    @Bean
    VehicleInformationSearchRepository vehicleInformationSearchRepository() {
        return Mockito.mock(VehicleInformationSearchRepository.class);
    }
}
