package com.tutict.finalassignmentbackend.entity.elastic;

import lombok.Data;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "appeals")
@Setting(settingPath = "elasticsearch/appeal-analyzer.json")
public class AppealManagementDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer appealId;

    @Field(type = FieldType.Integer)
    private Integer offenseId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String appellantName;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String idCardNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String contactNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String appealReason;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime appealTime;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String processStatus;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String processResult;

    // Convert from entity to document
    public static AppealManagementDocument fromEntity(AppealManagement entity) {
        if (entity == null) {
            return null;
        }

        AppealManagementDocument doc = new AppealManagementDocument();
        doc.setAppealId(entity.getAppealId());
        doc.setOffenseId(entity.getOffenseId());
        doc.setAppellantName(entity.getAppellantName());
        doc.setIdCardNumber(entity.getIdCardNumber());
        doc.setContactNumber(entity.getContactNumber());
        doc.setAppealReason(entity.getAppealReason());
        doc.setAppealTime(entity.getAppealTime());
        doc.setProcessStatus(entity.getProcessStatus());
        doc.setProcessResult(entity.getProcessResult());
        return doc;
    }

    // Convert from document to entity
    public AppealManagement toEntity() {
        AppealManagement entity = new AppealManagement();
        entity.setAppealId(this.appealId);
        entity.setOffenseId(this.offenseId);
        entity.setAppellantName(this.appellantName);
        entity.setIdCardNumber(this.idCardNumber);
        entity.setContactNumber(this.contactNumber);
        entity.setAppealReason(this.appealReason);
        entity.setAppealTime(this.appealTime);
        entity.setProcessStatus(this.processStatus);
        entity.setProcessResult(this.processResult);
        return entity;
    }
}