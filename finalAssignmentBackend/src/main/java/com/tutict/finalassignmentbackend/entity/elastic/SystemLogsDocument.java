package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.SystemLogs;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "system_logs")
@Setting(settingPath = "elasticsearch/system-logs-analyzer.json")
public class SystemLogsDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer logId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String logType;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String logContent;

    // 用于补全的字段，存储日志内容原始值
    @CompletionField(maxInputLength = 100)
    private String logContentCompletion;

    @Field(type = FieldType.Date, format = DateFormat.date_time, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime operationTime;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String operationUser;

    // 用于补全的字段，存储操作用户原始值
    @CompletionField(maxInputLength = 100)
    private String operationUserCompletion;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String operationIpAddress;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String remarks;

    // 自定义 setter 确保 logContentCompletion 一致性
    public void setLogContent(String logContent) {
        this.logContent = logContent;
        this.logContentCompletion = logContent;
    }

    // 自定义 setter 确保 operationUserCompletion 一致性
    public void setOperationUser(String operationUser) {
        this.operationUser = operationUser;
        this.operationUserCompletion = operationUser;
    }

    // 从 SystemLogs 实体转换为文档
    public static SystemLogsDocument fromEntity(SystemLogs entity) {
        if (entity == null) {
            return null;
        }

        SystemLogsDocument doc = new SystemLogsDocument();
        doc.setLogId(entity.getLogId());
        doc.setLogType(entity.getLogType());
        doc.setLogContent(entity.getLogContent()); // 会自动同步 logContentCompletion
        doc.setOperationTime(entity.getOperationTime());
        doc.setOperationUser(entity.getOperationUser()); // 会自动同步 operationUserCompletion
        doc.setOperationIpAddress(entity.getOperationIpAddress());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    // 从文档转换为 SystemLogs 实体
    public SystemLogs toEntity() {
        SystemLogs entity = new SystemLogs();
        entity.setLogId(this.logId);
        entity.setLogType(this.logType);
        entity.setLogContent(this.logContent);
        entity.setOperationTime(this.operationTime);
        entity.setOperationUser(this.operationUser);
        entity.setOperationIpAddress(this.operationIpAddress);
        entity.setRemarks(this.remarks);
        return entity;
    }
}