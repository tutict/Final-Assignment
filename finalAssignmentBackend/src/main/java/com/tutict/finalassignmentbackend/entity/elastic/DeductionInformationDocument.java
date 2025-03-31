package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "deductions")
@Setting(settingPath = "elasticsearch/deduction-analyzer.json")
public class DeductionInformationDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer deductionId;

    @Field(type = FieldType.Integer)
    private Integer offenseId;

    @Field(type = FieldType.Integer)
    private Integer deductedPoints;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime deductionTime;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "ngram", type = FieldType.Text, analyzer = "license_plate_analyzer", searchAnalyzer = "license_plate_analyzer")
            }
    )
    private String handler;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String approver;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword)
            }
    )
    private String remarks;

    public static DeductionInformationDocument fromEntity(DeductionInformation entity) {
        if (entity == null) return null;
        DeductionInformationDocument doc = new DeductionInformationDocument();
        doc.setDeductionId(entity.getDeductionId());
        doc.setOffenseId(entity.getOffenseId());
        doc.setDeductedPoints(entity.getDeductedPoints());
        doc.setDeductionTime(entity.getDeductionTime());
        doc.setHandler(entity.getHandler());
        doc.setApprover(entity.getApprover());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    public DeductionInformation toEntity() {
        DeductionInformation entity = new DeductionInformation();
        entity.setDeductionId(this.deductionId);
        entity.setOffenseId(this.offenseId);
        entity.setDeductedPoints(this.deductedPoints);
        entity.setDeductionTime(this.deductionTime);
        entity.setHandler(this.handler);
        entity.setApprover(this.approver);
        entity.setRemarks(this.remarks);
        return entity;
    }
}