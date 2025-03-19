package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.elasticsearch.annotations.MultiField;
import org.springframework.data.elasticsearch.annotations.InnerField;
import org.springframework.data.elasticsearch.annotations.Setting;

import java.time.LocalDate;

@Data
@Document(indexName = "vehicles")
@Setting(settingPath = "elasticsearch/vehicle-analyzer.json")
public class VehicleInformationDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer vehicleId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String licensePlate;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String vehicleType;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String ownerName;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String idCardNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String contactNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String engineNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String frameNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String vehicleColor;

    @Field(type = FieldType.Date, format = {}, pattern = "uuuu-MM-dd")
    private LocalDate firstRegistrationDate;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_smart", searchAnalyzer = "ik_smart"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String currentStatus;

    // 从 VehicleInformation 实体转换为文档
    public static VehicleInformationDocument fromEntity(VehicleInformation entity) {
        VehicleInformationDocument doc = new VehicleInformationDocument();
        doc.setVehicleId(entity.getVehicleId());
        doc.setLicensePlate(entity.getLicensePlate());
        doc.setVehicleType(entity.getVehicleType());
        doc.setOwnerName(entity.getOwnerName());
        doc.setIdCardNumber(entity.getIdCardNumber());
        doc.setContactNumber(entity.getContactNumber());
        doc.setEngineNumber(entity.getEngineNumber());
        doc.setFrameNumber(entity.getFrameNumber());
        doc.setVehicleColor(entity.getVehicleColor());
        doc.setFirstRegistrationDate(entity.getFirstRegistrationDate());
        doc.setCurrentStatus(entity.getCurrentStatus());
        return doc;
    }

    // 从文档转换回 VehicleInformation 实体
    public VehicleInformation toEntity() {
        VehicleInformation entity = new VehicleInformation();
        entity.setVehicleId(this.vehicleId);
        entity.setLicensePlate(this.licensePlate);
        entity.setVehicleType(this.vehicleType);
        entity.setOwnerName(this.ownerName);
        entity.setIdCardNumber(this.idCardNumber);
        entity.setContactNumber(this.contactNumber);
        entity.setEngineNumber(this.engineNumber);
        entity.setFrameNumber(this.frameNumber);
        entity.setVehicleColor(this.vehicleColor);
        entity.setFirstRegistrationDate(this.firstRegistrationDate);
        entity.setCurrentStatus(this.currentStatus);
        return entity;
    }
}