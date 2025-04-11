package com.tutict.finalassignmentbackend.entity.elastic;

import lombok.Data;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Document(indexName = "offense_information")
@Setting(settingPath = "elasticsearch/offense-analyzer.json")
public class OffenseInformationDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer offenseId;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime offenseTime;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String offenseLocation;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer"),
                    @InnerField(suffix = "ngram", type = FieldType.Text, analyzer = "license_plate_analyzer", searchAnalyzer = "license_plate_analyzer")
            }
    )
    private String licensePlate;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer"),
                    @InnerField(suffix = "ngram", type = FieldType.Text, analyzer = "license_plate_analyzer", searchAnalyzer = "license_plate_analyzer")
            }
    )
    private String driverName;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String offenseType;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String offenseCode;

    @Field(type = FieldType.Double)
    private Double fineAmount;

    @Field(type = FieldType.Integer)
    private Integer deductedPoints;

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

    @Field(type = FieldType.Integer)
    private Integer driverId;

    @Field(type = FieldType.Integer)
    private Integer vehicleId;

    // Convert from entity to document
    public static OffenseInformationDocument fromEntity(OffenseInformation entity) {
        if (entity == null) {
            return null;
        }

        OffenseInformationDocument doc = new OffenseInformationDocument();
        doc.setOffenseId(entity.getOffenseId());
        doc.setOffenseTime(entity.getOffenseTime());
        doc.setOffenseLocation(entity.getOffenseLocation());
        doc.setLicensePlate(entity.getLicensePlate());
        doc.setDriverName(entity.getDriverName());
        doc.setOffenseType(entity.getOffenseType());
        doc.setOffenseCode(entity.getOffenseCode());
        doc.setFineAmount(entity.getFineAmount() != null ? entity.getFineAmount().doubleValue() : null);
        doc.setDeductedPoints(entity.getDeductedPoints());
        doc.setProcessStatus(entity.getProcessStatus());
        doc.setProcessResult(entity.getProcessResult());
        doc.setDriverId(entity.getDriverId());
        doc.setVehicleId(entity.getVehicleId());
        return doc;
    }

    // Convert from document to entity
    public OffenseInformation toEntity() {
        OffenseInformation entity = new OffenseInformation();
        entity.setOffenseId(this.offenseId);
        entity.setOffenseTime(this.offenseTime);
        entity.setOffenseLocation(this.offenseLocation);
        entity.setLicensePlate(this.licensePlate);
        entity.setDriverName(this.driverName);
        entity.setOffenseType(this.offenseType);
        entity.setOffenseCode(this.offenseCode);
        entity.setFineAmount(this.fineAmount != null ? new BigDecimal(this.fineAmount.toString()) : null);
        entity.setDeductedPoints(this.deductedPoints);
        entity.setProcessStatus(this.processStatus);
        entity.setProcessResult(this.processResult);
        entity.setDriverId(this.driverId);
        entity.setVehicleId(this.vehicleId);
        return entity;
    }
}