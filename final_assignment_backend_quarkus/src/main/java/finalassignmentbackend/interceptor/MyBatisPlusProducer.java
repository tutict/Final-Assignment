package finalassignmentbackend.interceptor;

import finalassignmentbackend.mapper.*;
import finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;

@ApplicationScoped
public class MyBatisPlusProducer {

    @Inject
    SqlSessionFactory sqlSessionFactory;

    @Produces
    @ApplicationScoped
    public OffenseDetailsMapper produceOffenseDetailsMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(OffenseDetailsMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public AppealManagementMapper produceAppealManagementMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(AppealManagementMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public BackupRestoreMapper produceBackupRestoreMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(BackupRestoreMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public DeductionInformationMapper produceDeductionInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(DeductionInformationMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public DriverInformationMapper produceDriverInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(DriverInformationMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public FineInformationMapper produceFineInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(FineInformationMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public LoginLogMapper produceLoginLogMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(LoginLogMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public OffenseInformationMapper produceOffenseInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(OffenseInformationMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public OperationLogMapper produceOperationLogMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(OperationLogMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public RoleManagementMapper produceRoleManagementMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(RoleManagementMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public SystemLogsMapper produceSystemLogsMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(SystemLogsMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public SystemSettingsMapper produceSystemSettingsMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(SystemSettingsMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public UserManagementMapper produceUserManagementMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(UserManagementMapper.class);
        }
    }

    @Produces
    @ApplicationScoped
    public VehicleInformationMapper produceVehicleInformationMapper() {
        try (SqlSession session = sqlSessionFactory.openSession()) {
            return session.getMapper(VehicleInformationMapper.class);
        }
    }
}
