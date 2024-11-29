package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.service.BackupRestoreService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class BackupRestoreKafkaListener {

    private static final Logger log = Logger.getLogger(String.valueOf(BackupRestoreKafkaListener.class));

    @Inject
    BackupRestoreService backupRestoreService;

    @Inject
    ObjectMapper objectMapper;

    @Incoming("backup_create")
    @Blocking
    public void onBackupCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                BackupRestore backupRestore = deserializeMessage(message);
                backupRestoreService.createBackup(backupRestore);
                promise.complete();
            } catch (Exception e) {
                log.log(Level.SEVERE, String.format("Error processing backup create message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing backup create message: %s", message), res.cause());
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
                log.log(Level.SEVERE, String.format("Error processing backup update message: %s", message), e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.log(Level.SEVERE, String.format("Error processing backup update message: %s", message), res.cause());
            }
        });
    }

    private BackupRestore deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, BackupRestore.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
