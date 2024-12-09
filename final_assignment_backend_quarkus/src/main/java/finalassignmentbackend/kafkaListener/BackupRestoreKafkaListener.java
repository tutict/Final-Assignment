package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.service.BackupRestoreService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class BackupRestoreKafkaListener {

    private static final Logger log = Logger.getLogger(BackupRestoreKafkaListener.class.getName());

    @Inject
    BackupRestoreService backupRestoreService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("backup_create")
    @Transactional
    @RunOnVirtualThread
    public void onBackupCreateReceived(String message) {
        processMessage(message, "create", backupRestoreService::createBackup);
    }

    @Incoming("backup_update")
    @Transactional
    @RunOnVirtualThread
    public void onBackupUpdateReceived(String message) {
        processMessage(message, "update", backupRestoreService::updateBackup);
    }

    private void processMessage(String message, String action, MessageProcessor<BackupRestore> processor) {
        try {
            BackupRestore backupRestore = deserializeMessage(message);
            processor.process(backupRestore);
            log.info(String.format("Backup %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s backup message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s backup message", action), e);
        }
    }

    private BackupRestore deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, BackupRestore.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}
