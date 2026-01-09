package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SysBackupRestore;
import finalassignmentbackend.service.SysBackupRestoreService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka listener for backup/restore messages (new schema)
@ApplicationScoped
public class BackupRestoreKafkaListener {

    private static final Logger log = Logger.getLogger(BackupRestoreKafkaListener.class.getName());

    @Inject
    SysBackupRestoreService sysBackupRestoreService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("backup_restore_create")
    @Transactional
    @RunOnVirtualThread
    public void onBackupCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka create message: {0}", message);
        processMessage(message, "create", sysBackupRestoreService::createSysBackupRestore);
    }

    @Incoming("backup_restore_update")
    @Transactional
    @RunOnVirtualThread
    public void onBackupUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka update message: {0}", message);
        processMessage(message, "update", sysBackupRestoreService::updateSysBackupRestore);
    }

    private void processMessage(String message, String action, MessageProcessor<SysBackupRestore> processor) {
        try {
            SysBackupRestore record = deserializeMessage(message);
            if ("create".equals(action)) {
                record.setBackupId(null);
            }
            processor.process(record);
            log.info(String.format("Backup/restore %s processed: %s", action, record));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Failed to process backup/restore %s message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process backup/restore %s message", action), e);
        }
    }

    private SysBackupRestore deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysBackupRestore.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}
