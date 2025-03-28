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
                    @InnerField(suffix = "keyword", type = FieldType.Keyword) // 用于精确匹配
            }
    )
    private String name;

    @Field(type = FieldType.Keyword)
    private String idCardNumber;

    @Field(type = FieldType.Keyword)
    private String contactNumber;

    @Field(type = FieldType.Keyword)
    private String driverLicenseNumber;

    @Field(type = FieldType.Keyword)
    private String gender;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate birthdate;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate firstLicenseDate;

    @Field(type = FieldType.Keyword)
    private String allowedVehicleType;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate issueDate;

    @Field(type = FieldType.Date, format = DateFormat.date, pattern = "uuuu-MM-dd")
    private LocalDate expiryDate;

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

    public DriverInformation toEntity() {
        DriverInformation entity = new DriverInformation();
        entity.setDriverId(this.getDriverId());
        entity.setName(this.getName());
        entity.setIdCardNumber(this.getIdCardNumber());
        entity.setContactNumber(this.getContactNumber());
        entity.setDriverLicenseNumber(this.getDriverLicenseNumber());
        entity.setGender(this.getGender());
        entity.setBirthdate(this.getBirthdate());
        entity.setFirstLicenseDate(this.getFirstLicenseDate());
        entity.setAllowedVehicleType(this.getAllowedVehicleType());
        entity.setIssueDate(this.getIssueDate());
        entity.setExpiryDate(this.getExpiryDate());
        return entity;
    }
}