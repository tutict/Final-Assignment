package com.tutict.finalassignmentcloud.entity.elastic;

import com.tutict.finalassignmentcloud.entity.VehicleInformation;
import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;
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
@Document(indexName = "vehicle_information")
@Setting(settingPath = "elasticsearch/vehicle_information-settings.json")
public class VehicleInformationDocument implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @Id
    @Field(type = FieldType.Long)
    private Long vehicleId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String licensePlate;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String plateColor;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String vehicleType;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String brand;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String model;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String vehicleColor;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String engineNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String frameNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String ownerName;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String ownerIdCard;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String ownerContact;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String ownerAddress;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate firstRegistrationDate;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate registrationDate;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String issuingAuthority;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String status;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate inspectionExpiryDate;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate insuranceExpiryDate;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String createdBy;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "pinyin", type = FieldType.Text, analyzer = "pinyin_analyzer", searchAnalyzer = "pinyin_analyzer")
            }
    )
    private String updatedBy;

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

    public static VehicleInformationDocument fromEntity(VehicleInformation entity) {
        if (entity == null) {
            return null;
        }
        VehicleInformationDocument doc = new VehicleInformationDocument();
        doc.setVehicleId(entity.getVehicleId());
        doc.setLicensePlate(entity.getLicensePlate());
        doc.setPlateColor(entity.getPlateColor());
        doc.setVehicleType(entity.getVehicleType());
        doc.setBrand(entity.getBrand());
        doc.setModel(entity.getModel());
        doc.setVehicleColor(entity.getVehicleColor());
        doc.setEngineNumber(entity.getEngineNumber());
        doc.setFrameNumber(entity.getFrameNumber());
        doc.setOwnerName(entity.getOwnerName());
        doc.setOwnerIdCard(entity.getOwnerIdCard());
        doc.setOwnerContact(entity.getOwnerContact());
        doc.setOwnerAddress(entity.getOwnerAddress());
        doc.setFirstRegistrationDate(entity.getFirstRegistrationDate());
        doc.setRegistrationDate(entity.getRegistrationDate());
        doc.setIssuingAuthority(entity.getIssuingAuthority());
        doc.setStatus(entity.getStatus());
        doc.setInspectionExpiryDate(entity.getInspectionExpiryDate());
        doc.setInsuranceExpiryDate(entity.getInsuranceExpiryDate());
        doc.setCreatedAt(entity.getCreatedAt());
        doc.setUpdatedAt(entity.getUpdatedAt());
        doc.setCreatedBy(entity.getCreatedBy());
        doc.setUpdatedBy(entity.getUpdatedBy());
        doc.setDeletedAt(entity.getDeletedAt());
        doc.setRemarks(entity.getRemarks());
        return doc;
    }

    public VehicleInformation toEntity() {
        VehicleInformation entity = new VehicleInformation();
        entity.setVehicleId(this.vehicleId);
        entity.setLicensePlate(this.licensePlate);
        entity.setPlateColor(this.plateColor);
        entity.setVehicleType(this.vehicleType);
        entity.setBrand(this.brand);
        entity.setModel(this.model);
        entity.setVehicleColor(this.vehicleColor);
        entity.setEngineNumber(this.engineNumber);
        entity.setFrameNumber(this.frameNumber);
        entity.setOwnerName(this.ownerName);
        entity.setOwnerIdCard(this.ownerIdCard);
        entity.setOwnerContact(this.ownerContact);
        entity.setOwnerAddress(this.ownerAddress);
        entity.setFirstRegistrationDate(this.firstRegistrationDate);
        entity.setRegistrationDate(this.registrationDate);
        entity.setIssuingAuthority(this.issuingAuthority);
        entity.setStatus(this.status);
        entity.setInspectionExpiryDate(this.inspectionExpiryDate);
        entity.setInsuranceExpiryDate(this.insuranceExpiryDate);
        entity.setCreatedAt(this.createdAt);
        entity.setUpdatedAt(this.updatedAt);
        entity.setCreatedBy(this.createdBy);
        entity.setUpdatedBy(this.updatedBy);
        entity.setDeletedAt(this.deletedAt);
        entity.setRemarks(this.remarks);
        return entity;
    }
}

