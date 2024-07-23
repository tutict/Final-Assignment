package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.service.BackupRestoreService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class BackupRestoreKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(BackupRestoreKafkaListener.class);
    private final BackupRestoreService backupRestoreService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public BackupRestoreKafkaListener(BackupRestoreService backupRestoreService) {
        this.backupRestoreService = backupRestoreService;
    }

    @Incoming("backup_create")
    @Blocking
    public void onBackupCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                BackupRestore backupRestore = deserializeMessage(message);
                backupRestoreService.createBackup(backupRestore);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing backup create message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully create backup message: {}", message);
            } else {
                log.error("Error processing backup create message: {}", message, res.cause());
            }
        });
    }

    @Incoming("backup_update")
    @Blocking
    public void onBackupUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                BackupRestore backupRestore = deserializeMessage(message);
                backupRestoreService.updateBackup(backupRestore);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing backup update message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully update backup message: {}", message);
            } else {
                log.error("Error processing backup update message: {}", message, res.cause());
            }
        });
    }

    private BackupRestore deserializeMessage(String message) throws JsonProcessingException {
        return objectMapper.readValue(message, BackupRestore.class);
    }
}