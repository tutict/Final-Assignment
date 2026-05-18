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
import org.mockito.Mockito;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.kafka.core.ConsumerFactory;

@TestConfiguration
public class TestSearchRepositoryMockConfig {

    @Bean
    ConsumerFactory<String, String> consumerFactory() {
        return Mockito.mock(ConsumerFactory.class);
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
