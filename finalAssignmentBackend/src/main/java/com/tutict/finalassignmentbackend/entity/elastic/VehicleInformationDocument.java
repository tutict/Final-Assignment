package com.tutict.finalassignmentbackend.entity.elastic;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;

import java.time.LocalDate;

@Data
@Document(indexName = "vehicles")
public class VehicleInformationDocument {

    @Id
    private Integer vehicleId;

    @Field(type = FieldType.Text)
    private String licensePlate;

    @Field(type = FieldType.Text)
    private String vehicleType;

    @Field(type = FieldType.Text)
    private String ownerName;

    @Field(type = FieldType.Text)
    private String idCardNumber;

    @Field(type = FieldType.Text)
    private String contactNumber;

    @Field(type = FieldType.Text)
    private String engineNumber;

    @Field(type = FieldType.Text)
    private String frameNumber;

    @Field(type = FieldType.Text)
    private String vehicleColor;

    @Field(type = FieldType.Date, format = {}, pattern = "uuuu-MM-dd")
    private LocalDate firstRegistrationDate;

    @Field(type = FieldType.Text)
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