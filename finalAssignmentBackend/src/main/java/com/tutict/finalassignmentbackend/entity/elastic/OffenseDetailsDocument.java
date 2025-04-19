package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.OffenseDetails;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "offense_details")
@Setting(settingPath = "elasticsearch/offense-details-analyzer.json")
public class OffenseDetailsDocument {

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

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String driverName;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer"),
                    @InnerField(suffix = "ngram", type = FieldType.Text, analyzer = "license_plate_analyzer", searchAnalyzer = "license_plate_analyzer")
            }
    )
    private String driverIdCardNumber;

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
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String vehicleType;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String ownerName;

    public static OffenseDetailsDocument fromEntity(OffenseDetails entity) {
        if (entity == null) {
            return null;
        }

        OffenseDetailsDocument doc = new OffenseDetailsDocument();
        doc.setOffenseId(entity.getOffenseId());
        doc.setOffenseTime(entity.getOffenseTime());
        doc.setOffenseLocation(entity.getOffenseLocation());
        doc.setOffenseType(entity.getOffenseType());
        doc.setOffenseCode(entity.getOffenseCode());
        doc.setDriverName(entity.getDriverName());
        doc.setDriverIdCardNumber(entity.getDriverIdCardNumber());
        doc.setLicensePlate(entity.getLicensePlate());
        doc.setVehicleType(entity.getVehicleType());
        doc.setOwnerName(entity.getOwnerName());
        return doc;
    }

    public OffenseDetails toEntity() {
        OffenseDetails entity = new OffenseDetails();
        entity.setOffenseId(this.offenseId);
        entity.setOffenseTime(this.offenseTime);
        entity.setOffenseLocation(this.offenseLocation);
        entity.setOffenseType(this.offenseType);
        entity.setOffenseCode(this.offenseCode);
        entity.setDriverName(this.driverName);
        entity.setDriverIdCardNumber(this.driverIdCardNumber);
        entity.setLicensePlate(this.licensePlate);
        entity.setVehicleType(this.vehicleType);
        entity.setOwnerName(this.ownerName);
        return entity;
    }
}