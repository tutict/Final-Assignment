package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDate;

@Data
@Document(indexName = "drivers")
@Setting(settingPath = "elasticsearch/driver-analyzer.json")
public class DriverInformationDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer driverId;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String name;

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
    private String driverLicenseNumber;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String gender;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate birthdate;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate firstLicenseDate;

    @MultiField(
            mainField = @Field(type = FieldType.Text, analyzer = "ik_max_word", searchAnalyzer = "ik_max_word"),
            otherFields = {
                    @InnerField(suffix = "keyword", type = FieldType.Keyword),
                    @InnerField(suffix = "icu", type = FieldType.Text, analyzer = "icu_analyzer", searchAnalyzer = "icu_analyzer")
            }
    )
    private String allowedVehicleType;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate issueDate;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate expiryDate;

    // 从 DriverInformation 实体转换为文档
    public static DriverInformationDocument fromEntity(DriverInformation entity) {
        if (entity == null) {
            return null;
        }

        DriverInformationDocument doc = new DriverInformationDocument();
        doc.setDriverId(entity.getDriverId());
        doc.setName(entity.getName());
        doc.setIdCardNumber(entity.getIdCardNumber());
        doc.setContactNumber(entity.getContactNumber());
        doc.setDriverLicenseNumber(entity.getDriverLicenseNumber());
        doc.setGender(entity.getGender());
        doc.setBirthdate(entity.getBirthdate());
        doc.setFirstLicenseDate(entity.getFirstLicenseDate());
        doc.setAllowedVehicleType(entity.getAllowedVehicleType());
        doc.setIssueDate(entity.getIssueDate());
        doc.setExpiryDate(entity.getExpiryDate());
        return doc;
    }

    // 从文档转换为 DriverInformation 实体
    public DriverInformation toEntity() {
        DriverInformation entity = new DriverInformation();
        entity.setDriverId(this.driverId);
        entity.setName(this.name);
        entity.setIdCardNumber(this.idCardNumber);
        entity.setContactNumber(this.contactNumber);
        entity.setDriverLicenseNumber(this.driverLicenseNumber);
        entity.setGender(this.gender);
        entity.setBirthdate(this.birthdate);
        entity.setFirstLicenseDate(this.firstLicenseDate);
        entity.setAllowedVehicleType(this.allowedVehicleType);
        entity.setIssueDate(this.issueDate);
        entity.setExpiryDate(this.expiryDate);
        return entity;
    }
}