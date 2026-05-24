package com.tutict.finalassignmentbackend.config;

import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.entity.appeal.AppealReview;
import com.tutict.finalassignmentbackend.entity.audit.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.audit.AuditOperationLog;
import com.tutict.finalassignmentbackend.entity.offense.DeductionRecord;
import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import com.tutict.finalassignmentbackend.entity.driver.DriverVehicle;
import com.tutict.finalassignmentbackend.entity.offense.FineRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseTypeDict;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;
import com.tutict.finalassignmentbackend.entity.system.SysBackupRestore;
import com.tutict.finalassignmentbackend.entity.system.SysDict;
import com.tutict.finalassignmentbackend.entity.admin.SysPermission;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.admin.SysRole;
import com.tutict.finalassignmentbackend.entity.admin.SysRolePermission;
import com.tutict.finalassignmentbackend.entity.system.SysSettings;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.entity.admin.SysUserRole;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import com.tutict.finalassignmentbackend.entity.elastic.AppealReviewDocument;
import com.tutict.finalassignmentbackend.entity.elastic.AuditLoginLogDocument;
import com.tutict.finalassignmentbackend.entity.elastic.AuditOperationLogDocument;
import com.tutict.finalassignmentbackend.entity.elastic.DeductionRecordDocument;
import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.DriverVehicleDocument;
import com.tutict.finalassignmentbackend.entity.elastic.FineRecordDocument;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseRecordDocument;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseTypeDictDocument;
import com.tutict.finalassignmentbackend.entity.elastic.PaymentRecordDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysBackupRestoreDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysDictDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysPermissionDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysRequestHistoryDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysRoleDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysRolePermissionDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysSettingsDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysUserDocument;
import com.tutict.finalassignmentbackend.entity.elastic.SysUserRoleDocument;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.mapper.appeal.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.appeal.AppealReviewMapper;
import com.tutict.finalassignmentbackend.mapper.audit.AuditLoginLogMapper;
import com.tutict.finalassignmentbackend.mapper.audit.AuditOperationLogMapper;
import com.tutict.finalassignmentbackend.mapper.offense.DeductionRecordMapper;
import com.tutict.finalassignmentbackend.mapper.driver.DriverInformationMapper;
import com.tutict.finalassignmentbackend.mapper.driver.DriverVehicleMapper;
import com.tutict.finalassignmentbackend.mapper.offense.FineRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseTypeDictMapper;
import com.tutict.finalassignmentbackend.mapper.payment.PaymentRecordMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysBackupRestoreMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysDictMapper;
import com.tutict.finalassignmentbackend.mapper.admin.SysPermissionMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.admin.SysRoleMapper;
import com.tutict.finalassignmentbackend.mapper.admin.SysRolePermissionMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysSettingsMapper;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserMapper;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserRoleMapper;
import com.tutict.finalassignmentbackend.mapper.driver.VehicleInformationMapper;
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
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.DependsOn;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;
import org.springframework.context.annotation.Profile;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.data.elasticsearch.repository.config.EnableElasticsearchRepositories;

import java.util.List;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;

@Configuration
@Profile("!test")
@DependsOn("accountDriverSchemaMigration")
@EnableElasticsearchRepositories(basePackages = "com.tutict.finalassignmentbackend.repository")
public class ElasticSearchConfig {

    private static final Logger LOG = Logger.getLogger(ElasticSearchConfig.class.getName());
    @Value("${app.elasticsearch.sync.enabled:true}")
    private boolean syncEnabled;
    private final VehicleInformationMapper vehicleInformationMapper;
    private final DriverInformationMapper driverInformationMapper;
    private final DriverVehicleMapper driverVehicleMapper;
    private final OffenseRecordMapper offenseRecordMapper;
    private final AppealRecordMapper appealRecordMapper;
    private final AppealReviewMapper appealReviewMapper;
    private final FineRecordMapper fineRecordMapper;
    private final DeductionRecordMapper deductionRecordMapper;
    private final PaymentRecordMapper paymentRecordMapper;
    private final OffenseTypeDictMapper offenseTypeDictMapper;
    private final SysUserMapper sysUserMapper;
    private final SysRoleMapper sysRoleMapper;
    private final SysUserRoleMapper sysUserRoleMapper;
    private final SysPermissionMapper sysPermissionMapper;
    private final SysDictMapper sysDictMapper;
    private final SysSettingsMapper sysSettingsMapper;
    private final SysBackupRestoreMapper sysBackupRestoreMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysRolePermissionMapper sysRolePermissionMapper;
    private final AuditLoginLogMapper auditLoginLogMapper;
    private final AuditOperationLogMapper auditOperationLogMapper;

    private final @Lazy VehicleInformationSearchRepository vehicleInformationSearchRepository;
    private final @Lazy DriverInformationSearchRepository driverInformationSearchRepository;
    private final @Lazy DriverVehicleSearchRepository driverVehicleSearchRepository;
    private final @Lazy OffenseInformationSearchRepository offenseInformationSearchRepository;
    private final @Lazy AppealRecordSearchRepository appealRecordSearchRepository;
    private final @Lazy AppealReviewSearchRepository appealReviewSearchRepository;
    private final @Lazy FineRecordSearchRepository fineRecordSearchRepository;
    private final @Lazy DeductionRecordSearchRepository deductionRecordSearchRepository;
    private final @Lazy PaymentRecordSearchRepository paymentRecordSearchRepository;
    private final @Lazy OffenseTypeDictSearchRepository offenseTypeDictSearchRepository;
    private final @Lazy SysUserSearchRepository sysUserSearchRepository;
    private final @Lazy SysRoleSearchRepository sysRoleSearchRepository;
    private final @Lazy SysUserRoleSearchRepository sysUserRoleSearchRepository;
    private final @Lazy SysPermissionSearchRepository sysPermissionSearchRepository;
    private final @Lazy SysDictSearchRepository sysDictSearchRepository;
    private final @Lazy SysSettingsSearchRepository sysSettingsSearchRepository;
    private final @Lazy SysBackupRestoreSearchRepository sysBackupRestoreSearchRepository;
    private final @Lazy SysRequestHistorySearchRepository sysRequestHistorySearchRepository;
    private final @Lazy SysRolePermissionSearchRepository sysRolePermissionSearchRepository;
    private final @Lazy AuditLoginLogSearchRepository auditLoginLogSearchRepository;
    private final @Lazy AuditOperationLogSearchRepository auditOperationLogSearchRepository;

    public ElasticSearchConfig(
            VehicleInformationMapper vehicleInformationMapper,
            DriverInformationMapper driverInformationMapper,
            DriverVehicleMapper driverVehicleMapper,
            OffenseRecordMapper offenseRecordMapper,
            AppealRecordMapper appealRecordMapper,
            AppealReviewMapper appealReviewMapper,
            FineRecordMapper fineRecordMapper,
            DeductionRecordMapper deductionRecordMapper,
            PaymentRecordMapper paymentRecordMapper,
            OffenseTypeDictMapper offenseTypeDictMapper,
            SysUserMapper sysUserMapper,
            SysRoleMapper sysRoleMapper,
            SysUserRoleMapper sysUserRoleMapper,
            SysPermissionMapper sysPermissionMapper,
            SysDictMapper sysDictMapper,
            SysSettingsMapper sysSettingsMapper,
            SysBackupRestoreMapper sysBackupRestoreMapper,
            SysRequestHistoryMapper sysRequestHistoryMapper,
            SysRolePermissionMapper sysRolePermissionMapper,
            AuditLoginLogMapper auditLoginLogMapper,
            AuditOperationLogMapper auditOperationLogMapper,
            @Lazy VehicleInformationSearchRepository vehicleInformationSearchRepository,
            @Lazy DriverInformationSearchRepository driverInformationSearchRepository,
            @Lazy DriverVehicleSearchRepository driverVehicleSearchRepository,
            @Lazy OffenseInformationSearchRepository offenseInformationSearchRepository,
            @Lazy AppealRecordSearchRepository appealRecordSearchRepository,
            @Lazy AppealReviewSearchRepository appealReviewSearchRepository,
            @Lazy FineRecordSearchRepository fineRecordSearchRepository,
            @Lazy DeductionRecordSearchRepository deductionRecordSearchRepository,
            @Lazy PaymentRecordSearchRepository paymentRecordSearchRepository,
            @Lazy OffenseTypeDictSearchRepository offenseTypeDictSearchRepository,
            @Lazy SysUserSearchRepository sysUserSearchRepository,
            @Lazy SysRoleSearchRepository sysRoleSearchRepository,
            @Lazy SysUserRoleSearchRepository sysUserRoleSearchRepository,
            @Lazy SysPermissionSearchRepository sysPermissionSearchRepository,
            @Lazy SysDictSearchRepository sysDictSearchRepository,
            @Lazy SysSettingsSearchRepository sysSettingsSearchRepository,
            @Lazy SysBackupRestoreSearchRepository sysBackupRestoreSearchRepository,
            @Lazy SysRequestHistorySearchRepository sysRequestHistorySearchRepository,
            @Lazy SysRolePermissionSearchRepository sysRolePermissionSearchRepository,
            @Lazy AuditLoginLogSearchRepository auditLoginLogSearchRepository,
            @Lazy AuditOperationLogSearchRepository auditOperationLogSearchRepository) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.driverInformationMapper = driverInformationMapper;
        this.driverVehicleMapper = driverVehicleMapper;
        this.offenseRecordMapper = offenseRecordMapper;
        this.appealRecordMapper = appealRecordMapper;
        this.appealReviewMapper = appealReviewMapper;
        this.fineRecordMapper = fineRecordMapper;
        this.deductionRecordMapper = deductionRecordMapper;
        this.paymentRecordMapper = paymentRecordMapper;
        this.offenseTypeDictMapper = offenseTypeDictMapper;
        this.sysUserMapper = sysUserMapper;
        this.sysRoleMapper = sysRoleMapper;
        this.sysUserRoleMapper = sysUserRoleMapper;
        this.sysPermissionMapper = sysPermissionMapper;
        this.sysDictMapper = sysDictMapper;
        this.sysSettingsMapper = sysSettingsMapper;
        this.sysBackupRestoreMapper = sysBackupRestoreMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysRolePermissionMapper = sysRolePermissionMapper;
        this.auditLoginLogMapper = auditLoginLogMapper;
        this.auditOperationLogMapper = auditOperationLogMapper;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
        this.driverVehicleSearchRepository = driverVehicleSearchRepository;
        this.offenseInformationSearchRepository = offenseInformationSearchRepository;
        this.appealRecordSearchRepository = appealRecordSearchRepository;
        this.appealReviewSearchRepository = appealReviewSearchRepository;
        this.fineRecordSearchRepository = fineRecordSearchRepository;
        this.deductionRecordSearchRepository = deductionRecordSearchRepository;
        this.paymentRecordSearchRepository = paymentRecordSearchRepository;
        this.offenseTypeDictSearchRepository = offenseTypeDictSearchRepository;
        this.sysUserSearchRepository = sysUserSearchRepository;
        this.sysRoleSearchRepository = sysRoleSearchRepository;
        this.sysUserRoleSearchRepository = sysUserRoleSearchRepository;
        this.sysPermissionSearchRepository = sysPermissionSearchRepository;
        this.sysDictSearchRepository = sysDictSearchRepository;
        this.sysSettingsSearchRepository = sysSettingsSearchRepository;
        this.sysBackupRestoreSearchRepository = sysBackupRestoreSearchRepository;
        this.sysRequestHistorySearchRepository = sysRequestHistorySearchRepository;
        this.sysRolePermissionSearchRepository = sysRolePermissionSearchRepository;
        this.auditLoginLogSearchRepository = auditLoginLogSearchRepository;
        this.auditOperationLogSearchRepository = auditOperationLogSearchRepository;
    }

    @PostConstruct
    public void syncDatabaseToElasticsearch() {
        if (!syncEnabled) {
            LOG.log(Level.INFO, "Database to Elasticsearch startup sync is disabled.");
            return;
        }
        LOG.log(Level.INFO, "开始执行数据库 -> Elasticsearch 全量同步任务");

        syncEntities("vehicle_information",
                vehicleInformationMapper.selectList(null),
                vehicleInformationSearchRepository,
                VehicleInformationDocument::fromEntity,
                VehicleInformation::getVehicleId);

        syncEntities("driver_information",
                driverInformationMapper.selectList(null),
                driverInformationSearchRepository,
                DriverInformationDocument::fromEntity,
                DriverInformation::getDriverId);

        syncEntities("driver_vehicle",
                driverVehicleMapper.selectList(null),
                driverVehicleSearchRepository,
                DriverVehicleDocument::fromEntity,
                DriverVehicle::getId);

        syncEntities("offense_record",
                offenseRecordMapper.selectList(null),
                offenseInformationSearchRepository,
                OffenseRecordDocument::fromEntity,
                OffenseRecord::getOffenseId);

        syncEntities("appeal_record",
                appealRecordMapper.selectList(null),
                appealRecordSearchRepository,
                AppealRecordDocument::fromEntity,
                AppealRecord::getAppealId);

        syncEntities("appeal_review",
                appealReviewMapper.selectList(null),
                appealReviewSearchRepository,
                AppealReviewDocument::fromEntity,
                AppealReview::getReviewId);

        syncEntities("fine_record",
                fineRecordMapper.selectList(null),
                fineRecordSearchRepository,
                FineRecordDocument::fromEntity,
                FineRecord::getFineId);

        syncEntities("deduction_record",
                deductionRecordMapper.selectList(null),
                deductionRecordSearchRepository,
                DeductionRecordDocument::fromEntity,
                DeductionRecord::getDeductionId);

        syncEntities("payment_record",
                paymentRecordMapper.selectList(null),
                paymentRecordSearchRepository,
                PaymentRecordDocument::fromEntity,
                PaymentRecord::getPaymentId);

        syncEntities("offense_type_dict",
                offenseTypeDictMapper.selectList(null),
                offenseTypeDictSearchRepository,
                OffenseTypeDictDocument::fromEntity,
                OffenseTypeDict::getTypeId);

        syncEntities("sys_user",
                sysUserMapper.selectList(null),
                sysUserSearchRepository,
                SysUserDocument::fromEntity,
                SysUser::getUserId);

        syncEntities("sys_role",
                sysRoleMapper.selectList(null),
                sysRoleSearchRepository,
                SysRoleDocument::fromEntity,
                SysRole::getRoleId);

        syncEntities("sys_user_role",
                sysUserRoleMapper.selectList(null),
                sysUserRoleSearchRepository,
                SysUserRoleDocument::fromEntity,
                SysUserRole::getId);

        syncEntities("sys_permission",
                sysPermissionMapper.selectList(null),
                sysPermissionSearchRepository,
                SysPermissionDocument::fromEntity,
                SysPermission::getPermissionId);

        syncEntities("sys_dict",
                sysDictMapper.selectList(null),
                sysDictSearchRepository,
                SysDictDocument::fromEntity,
                SysDict::getDictId);

        syncEntities("sys_settings",
                sysSettingsMapper.selectList(null),
                sysSettingsSearchRepository,
                SysSettingsDocument::fromEntity,
                SysSettings::getSettingId);

        syncEntities("sys_backup_restore",
                sysBackupRestoreMapper.selectList(null),
                sysBackupRestoreSearchRepository,
                SysBackupRestoreDocument::fromEntity,
                SysBackupRestore::getBackupId);

        syncEntities("sys_request_history",
                sysRequestHistoryMapper.selectList(null),
                sysRequestHistorySearchRepository,
                SysRequestHistoryDocument::fromEntity,
                SysRequestHistory::getId);

        syncEntities("sys_role_permission",
                sysRolePermissionMapper.selectList(null),
                sysRolePermissionSearchRepository,
                SysRolePermissionDocument::fromEntity,
                SysRolePermission::getId);

        syncEntities("audit_login_log",
                auditLoginLogMapper.selectList(null),
                auditLoginLogSearchRepository,
                AuditLoginLogDocument::fromEntity,
                AuditLoginLog::getLogId);

        syncEntities("audit_operation_log",
                auditOperationLogMapper.selectList(null),
                auditOperationLogSearchRepository,
                AuditOperationLogDocument::fromEntity,
                AuditOperationLog::getLogId);

        LOG.log(Level.INFO, "数据库 -> Elasticsearch 同步完成");
    }

    private <T, ID, D> void syncEntities(String entityType,
                                         List<T> entities,
                                         ElasticsearchRepository<D, ID> repository,
                                         Function<T, D> converter,
                                         Function<T, ID> idExtractor) {
        if (entities == null || entities.isEmpty()) {
            LOG.log(Level.INFO, "实体 {0} 在数据库中没有记录需要同步", entityType);
            return;
        }
        for (T entity : entities) {
            try {
                D document = converter.apply(entity);
                if (document == null) {
                    LOG.log(Level.WARNING, "实体 {0} 转换为文档失败，ID={1}", new Object[]{entityType, idExtractor.apply(entity)});
                    continue;
                }
                repository.save(document);
                LOG.log(Level.INFO, "已同步 {0} -> ES，ID={1}", new Object[]{entityType, idExtractor.apply(entity)});
            } catch (Exception e) {
                LOG.log(Level.SEVERE, "同步 {0} 失败，ID={1}, 错误: {2}",
                        new Object[]{entityType, idExtractor.apply(entity), e.getMessage()});
            }
        }
        LOG.log(Level.INFO, "完成 {0} 条 {1} 的同步", new Object[]{entities.size(), entityType});
    }
}
