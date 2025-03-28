package com.tutict.finalassignmentbackend.entity.elastic;

import lombok.Data;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;

import java.time.LocalDateTime;

@Data
@Document(indexName = "offense")
@Setting(settingPath = "elasticsearch/offense-analyzer.json")
public class OffenseInformationDocument {

    @Id
    @Field(type = FieldType.Integer)
    private Integer offenseId;

    @Field(type = FieldType.Date, format = DateFormat.date_hour_minute_second, pattern = "uuuu-MM-dd'T'HH:mm:ss")
    private LocalDateTime offenseTime;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String offenseLocation;

    @Field(type = FieldType.Keyword)
    private String licensePlate;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String driverName;

    @Field(type = FieldType.Keyword)
    private String offenseType;

    @Field(type = FieldType.Keyword)
    private String offenseCode;

    @Field(type = FieldType.Double)
    private Double fineAmount; // Changed from BigDecimal to Double

    @Field(type = FieldType.Integer)
    private Integer deductedPoints;

    @Field(type = FieldType.Keyword)
    private String processStatus;

    @Field(type = FieldType.Text)
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
        doc.setFineAmount(entity.getFineAmount() != null ? entity.getFineAmount().doubleValue() : null); // Convert BigDecimal to Double
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
        entity.setOffenseId(this.getOffenseId());
        entity.setOffenseTime(this.getOffenseTime());
        entity.setOffenseLocation(this.getOffenseLocation());
        entity.setLicensePlate(this.getLicensePlate());
        entity.setDriverName(this.getDriverName());
        entity.setOffenseType(this.getOffenseType());
        entity.setOffenseCode(this.getOffenseCode());
        entity.setFineAmount(this.getFineAmount() != null ? new java.math.BigDecimal(this.getFineAmount().toString()) : null); // Convert Double back to BigDecimal
        entity.setDeductedPoints(this.getDeductedPoints());
        entity.setProcessStatus(this.getProcessStatus());
        entity.setProcessResult(this.getProcessResult());
        entity.setDriverId(this.getDriverId());
        entity.setVehicleId(this.getVehicleId());
        return entity;
    }
}