package com.tutict.finalassignmentbackend.entity.elastic;

import lombok.Data;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.elasticsearch.annotations.DateFormat;

import java.time.LocalDate;

@Data
@Document(indexName = "driver_information")
public class DriverInformationDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer driverId;

    @Field(type = FieldType.Text, analyzer = "standard")
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

    // Convert from document to entity
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