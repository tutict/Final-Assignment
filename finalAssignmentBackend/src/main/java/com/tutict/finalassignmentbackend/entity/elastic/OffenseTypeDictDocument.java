package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.OffenseTypeDict;
import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
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
@Document(indexName = "offense_type_dict")
@Setting(settingPath = "elasticsearch/offense_type_dict-settings.json")
public class OffenseTypeDictDocument implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @Id
    @Field(type = FieldType.Integer)
    private Integer typeId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String offenseCode;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String offenseName;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String category;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String description;

    @Field(type = FieldType.Double)
    private BigDecimal standardFineAmount;

    @Field(type = FieldType.Double)
    private BigDecimal minFineAmount;

    @Field(type = FieldType.Double)
    private BigDecimal maxFineAmount;

    @Field(type = FieldType.Integer)
    private Integer deductedPoints;

    @Field(type = FieldType.Integer)
    private Integer detentionDays;

    @Field(type = FieldType.Integer)
    private Integer licenseSuspensionDays;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String severityLevel;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String legalBasis;

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

    public static OffenseTypeDictDocument fromEntity(OffenseTypeDict entity) {
        if (entity == null) {
            return null;
        }
        OffenseTypeDictDocument doc = new OffenseTypeDictDocument();
        doc.setTypeId(entity.getTypeId());
        doc.setOffenseCode(entity.getOffenseCode());
        doc.setOffenseName(entity.getOffenseName());
        doc.setCategory(entity.getCategory());
        doc.setDescription(entity.getDescription());
        doc.setStandardFineAmount(entity.getStandardFineAmount());
        doc.setMinFineAmount(entity.getMinFineAmount());
        doc.setMaxFineAmount(entity.getMaxFineAmount());
        doc.setDeductedPoints(entity.getDeductedPoints());
        doc.setDetentionDays(entity.getDetentionDays());
        doc.setLicenseSuspensionDays(entity.getLicenseSuspensionDays());
        doc.setSeverityLevel(entity.getSeverityLevel());
        doc.setLegalBasis(entity.getLegalBasis());
        doc.setStatus(entity.getStatus());
        doc.setCreatedAt(entity.getCreatedAt());
        doc.setUpdatedAt(entity.getUpdatedAt());
        doc.setDeletedAt(entity.getDeletedAt());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    public OffenseTypeDict toEntity() {
        OffenseTypeDict entity = new OffenseTypeDict();
        entity.setTypeId(this.typeId);
        entity.setOffenseCode(this.offenseCode);
        entity.setOffenseName(this.offenseName);
        entity.setCategory(this.category);
        entity.setDescription(this.description);
        entity.setStandardFineAmount(this.standardFineAmount);
        entity.setMinFineAmount(this.minFineAmount);
        entity.setMaxFineAmount(this.maxFineAmount);
        entity.setDeductedPoints(this.deductedPoints);
        entity.setDetentionDays(this.detentionDays);
        entity.setLicenseSuspensionDays(this.licenseSuspensionDays);
        entity.setSeverityLevel(this.severityLevel);
        entity.setLegalBasis(this.legalBasis);
        entity.setStatus(this.status);
        entity.setCreatedAt(this.createdAt);
        entity.setUpdatedAt(this.updatedAt);
        entity.setDeletedAt(this.deletedAt);
        entity.setRemarks(this.remarks);
        return entity;
    }
}
