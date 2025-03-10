package com.tutict.finalassignmentbackend.entity.elastic;

import lombok.Data;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.elasticsearch.annotations.DateFormat;

import java.time.LocalDateTime;

@Data
@Document(indexName = "appeal_management")
public class AppealManagementDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer appealId;

    @Field(type = FieldType.Integer)
    private Integer offenseId;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String appellantName;

    @Field(type = FieldType.Keyword)
    private String idCardNumber;

    @Field(type = FieldType.Keyword)
    private String contactNumber;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String appealReason;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime appealTime;

    @Field(type = FieldType.Keyword)
    private String processStatus;

    @Field(type = FieldType.Text)
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
        entity.setAppealId(this.getAppealId());
        entity.setOffenseId(this.getOffenseId());
        entity.setAppellantName(this.getAppellantName());
        entity.setIdCardNumber(this.getIdCardNumber());
        entity.setContactNumber(this.getContactNumber());
        entity.setAppealReason(this.getAppealReason());
        entity.setAppealTime(this.getAppealTime());
        entity.setProcessStatus(this.getProcessStatus());
        entity.setProcessResult(this.getProcessResult());
        return entity;
    }
}