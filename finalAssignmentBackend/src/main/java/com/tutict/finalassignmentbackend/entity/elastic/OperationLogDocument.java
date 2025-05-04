package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.OperationLog;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "operation_logs")
@Setting(settingPath = "elasticsearch/operation-log-analyzer.json")
public class OperationLogDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer logId;

    @Field(type = FieldType.Integer)
    private Integer userId;

    @Field(type = FieldType.Date, format = DateFormat.date_time, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime operationTime;

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
    private String operationContent;

    // 用于补全的字段，存储原始值
    @CompletionField(maxInputLength = 100)
    private String operationContentCompletion;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String operationResult;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String remarks;

    // 自定义 setter 确保 operationContentCompletion 一致性
    public void setOperationContent(String operationContent) {
        this.operationContent = operationContent;
        this.operationContentCompletion = operationContent; // 同步 operationContentCompletion
    }

    // 从 OperationLog 实体转换为文档
    public static OperationLogDocument fromEntity(OperationLog entity) {
        if (entity == null) {
            return null;
        }

        OperationLogDocument doc = new OperationLogDocument();
        doc.setLogId(entity.getLogId());
        doc.setUserId(entity.getUserId());
        doc.setOperationTime(entity.getOperationTime());
        doc.setOperationIpAddress(entity.getOperationIpAddress());
        doc.setOperationContent(entity.getOperationContent()); // 会自动同步 operationContentCompletion
        doc.setOperationResult(entity.getOperationResult());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    // 从文档转换为 OperationLog 实体
    public OperationLog toEntity() {
        OperationLog entity = new OperationLog();
        entity.setLogId(this.logId);
        entity.setUserId(this.userId);
        entity.setOperationTime(this.operationTime);
        entity.setOperationIpAddress(this.operationIpAddress);
        entity.setOperationContent(this.operationContent);
        entity.setOperationResult(this.operationResult);
        entity.setRemarks(this.remarks);
        return entity;
    }
}