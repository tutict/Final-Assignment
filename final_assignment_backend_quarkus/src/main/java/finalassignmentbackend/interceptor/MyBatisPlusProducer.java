package finalassignmentbackend.interceptor;

import finalassignmentbackend.mapper.AppealManagementMapper;
import finalassignmentbackend.mapper.BackupRestoreMapper;
import finalassignmentbackend.mapper.DeductionInformationMapper;
import finalassignmentbackend.mapper.DriverInformationMapper;
import finalassignmentbackend.mapper.FineInformationMapper;
import finalassignmentbackend.mapper.LoginLogMapper;
import finalassignmentbackend.mapper.OffenseInformationMapper;
import finalassignmentbackend.mapper.OperationLogMapper;
import finalassignmentbackend.mapper.PermissionManagementMapper;
import finalassignmentbackend.mapper.RoleManagementMapper;
import finalassignmentbackend.mapper.SystemLogsMapper;
import finalassignmentbackend.mapper.SystemSettingsMapper;
import finalassignmentbackend.mapper.UserManagementMapper;
import finalassignmentbackend.mapper.VehicleInformationMapper;
import finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;


@ApplicationScoped
public class MyBatisPlusProducer {

    @Inject
    SqlSessionFactory sqlSessionFactory;

    @Produces
    @Named("OffenseDetailsMapper")
    @ApplicationScoped
    public OffenseDetailsMapper produceOffenseDetailsMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(OffenseDetailsMapper.class);
        }
    }

    @Produces
    @Named("AppealManagementMapper")
    @ApplicationScoped
    public AppealManagementMapper produceAppealManagementMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(AppealManagementMapper.class);
        }
    }

    @Produces
    @Named("BackupRestoreMapper")
    @ApplicationScoped
    public BackupRestoreMapper produceBackupRestoreMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(BackupRestoreMapper.class);
        }
    }

    @Produces
    @Named("DeductionInformationMapper")
    @ApplicationScoped
    public DeductionInformationMapper produceDeductionInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(DeductionInformationMapper.class);
        }
    }

    @Produces
    @Named("DriverInformationMapper")
    @ApplicationScoped
    public DriverInformationMapper produceDriverInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(DriverInformationMapper.class);
        }
    }

    @Produces
    @Named("FineInformationMapper")
    @ApplicationScoped
    public FineInformationMapper produceFineInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(FineInformationMapper.class);
        }
    }

    @Produces
    @Named("LoginLogMapper")
    @ApplicationScoped
    public LoginLogMapper produceLoginLogMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(LoginLogMapper.class);
        }
    }

    @Produces
    @Named("OffenseInformationMapper")
    @ApplicationScoped
    public OffenseInformationMapper produceOffenseInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(OffenseInformationMapper.class);
        }
    }

    @Produces
    @Named("OperationLogMapper")
    @ApplicationScoped
    public OperationLogMapper produceOperationLogMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(OperationLogMapper.class);
        }
    }

    @Produces
    @Named("PermissionManagementMapper")
    @ApplicationScoped
    public PermissionManagementMapper producePermissionManagementMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(PermissionManagementMapper.class);
        }
    }

    @Produces
    @Named("RoleManagementMapper")
    @ApplicationScoped
    public RoleManagementMapper produceRoleManagementMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(RoleManagementMapper.class);
        }
    }

    @Produces
    @Named("SystemLogsMapper")
    @ApplicationScoped
    public SystemLogsMapper produceSystemLogsMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(SystemLogsMapper.class);
        }
    }

    @Produces
    @Named("SystemSettingsMapper")
    @ApplicationScoped
    public SystemSettingsMapper produceSystemSettingsMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(SystemSettingsMapper.class);
        }
    }

    @Produces
    @Named("UserManagementMapper")
    @ApplicationScoped
    public UserManagementMapper produceUserManagementMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(UserManagementMapper.class);
        }
    }

    @Produces
    @Named("VehicleInformationMapper")
    @ApplicationScoped
    public VehicleInformationMapper produceVehicleInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(VehicleInformationMapper.class);
        }
    }
}
