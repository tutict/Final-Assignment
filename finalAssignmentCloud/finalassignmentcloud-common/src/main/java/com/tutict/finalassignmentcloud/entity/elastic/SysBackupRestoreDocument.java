package com.tutict.finalassignmentcloud.entity.elastic;

import com.tutict.finalassignmentcloud.entity.SysBackupRestore;
import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.DateFormat;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.elasticsearch.annotations.InnerField;
import org.springframework.data.elasticsearch.annotations.MultiField;
import org.springframework.data.elasticsearch.annotations.Setting;

@Data
@Document(indexName = "sys_backup_restore")
@Setting(settingPath = "elasticsearch/sys_backup_restore-settings.json")
public class SysBackupRestoreDocument implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @Id
    @Field(type = FieldType.Long)
    private Long backupId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String backupType;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String backupFileName;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String backupFilePath;

    @Field(type = FieldType.Long)
    private Long backupFileSize;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime backupTime;

    @Field(type = FieldType.Integer)
    private Integer backupDuration;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String backupHandler;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime restoreTime;

    @Field(type = FieldType.Integer)
    private Integer restoreDuration;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String restoreStatus;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String restoreHandler;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String errorMessage;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String status;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime deletedAt;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String remarks;

    public static SysBackupRestoreDocument fromEntity(SysBackupRestore entity) {
        if (entity == null) {
            return null;
        }
        SysBackupRestoreDocument doc = new SysBackupRestoreDocument();
        doc.setBackupId(entity.getBackupId());
        doc.setBackupType(entity.getBackupType());
        doc.setBackupFileName(entity.getBackupFileName());
        doc.setBackupFilePath(entity.getBackupFilePath());
        doc.setBackupFileSize(entity.getBackupFileSize());
        doc.setBackupTime(entity.getBackupTime());
        doc.setBackupDuration(entity.getBackupDuration());
        doc.setBackupHandler(entity.getBackupHandler());
        doc.setRestoreTime(entity.getRestoreTime());
        doc.setRestoreDuration(entity.getRestoreDuration());
        doc.setRestoreStatus(entity.getRestoreStatus());
        doc.setRestoreHandler(entity.getRestoreHandler());
        doc.setErrorMessage(entity.getErrorMessage());
        doc.setStatus(entity.getStatus());
        doc.setCreatedAt(entity.getCreatedAt());
        doc.setUpdatedAt(entity.getUpdatedAt());
        doc.setDeletedAt(entity.getDeletedAt());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    public SysBackupRestore toEntity() {
        SysBackupRestore entity = new SysBackupRestore();
        entity.setBackupId(this.backupId);
        entity.setBackupType(this.backupType);
        entity.setBackupFileName(this.backupFileName);
        entity.setBackupFilePath(this.backupFilePath);
        entity.setBackupFileSize(this.backupFileSize);
        entity.setBackupTime(this.backupTime);
        entity.setBackupDuration(this.backupDuration);
        entity.setBackupHandler(this.backupHandler);
        entity.setRestoreTime(this.restoreTime);
        entity.setRestoreDuration(this.restoreDuration);
        entity.setRestoreStatus(this.restoreStatus);
        entity.setRestoreHandler(this.restoreHandler);
        entity.setErrorMessage(this.errorMessage);
        entity.setStatus(this.status);
        entity.setCreatedAt(this.createdAt);
        entity.setUpdatedAt(this.updatedAt);
        entity.setDeletedAt(this.deletedAt);
        entity.setRemarks(this.remarks);
        return entity;
    }
}

