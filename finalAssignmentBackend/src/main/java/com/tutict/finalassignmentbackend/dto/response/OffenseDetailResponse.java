package com.tutict.finalassignmentbackend.dto.response;

import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.entity.FineRecord;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class OffenseDetailResponse {

    private Long offenseId;
    private String offenseType;
    private String offenseLocation;
    private LocalDateTime offenseTime;
    private String processStatus;
    private DriverInfo driver;
    private VehicleInfo vehicle;
    private List<FineInfo> fines;
    private List<AppealInfo> appeals;

    public static OffenseDetailResponse from(
            OffenseRecord offense,
            DriverInformation driver,
            VehicleInformation vehicle,
            List<FineRecord> fines,
            List<AppealRecord> appeals) {
        return OffenseDetailResponse.builder()
                .offenseId(offense.getOffenseId())
                .offenseType(firstNonBlank(offense.getOffenseCode(), offense.getOffenseDescription()))
                .offenseLocation(offense.getOffenseLocation())
                .offenseTime(offense.getOffenseTime())
                .processStatus(offense.getProcessStatus())
                .driver(DriverInfo.from(driver))
                .vehicle(VehicleInfo.from(vehicle))
                .fines(fines == null ? List.of() : fines.stream().map(FineInfo::from).toList())
                .appeals(appeals == null ? List.of() : appeals.stream().map(AppealInfo::from).toList())
                .build();
    }

    @Data
    @Builder
    public static class DriverInfo {
        private Long driverId;
        private String name;
        private String idCardNumber;
        private String driverLicenseNumber;
        private String contactNumber;

        public static DriverInfo from(DriverInformation driver) {
            if (driver == null) {
                return null;
            }
            return DriverInfo.builder()
                    .driverId(driver.getDriverId())
                    .name(driver.getName())
                    .idCardNumber(driver.getIdCardNumber())
                    .driverLicenseNumber(driver.getDriverLicenseNumber())
                    .contactNumber(driver.getContactNumber())
                    .build();
        }
    }

    @Data
    @Builder
    public static class VehicleInfo {
        private Long vehicleId;
        private String licensePlate;
        private String vehicleType;
        private String brand;
        private String model;

        public static VehicleInfo from(VehicleInformation vehicle) {
            if (vehicle == null) {
                return null;
            }
            return VehicleInfo.builder()
                    .vehicleId(vehicle.getVehicleId())
                    .licensePlate(vehicle.getLicensePlate())
                    .vehicleType(vehicle.getVehicleType())
                    .brand(vehicle.getBrand())
                    .model(vehicle.getModel())
                    .build();
        }
    }

    @Data
    @Builder
    public static class FineInfo {
        private Long fineId;
        private Double fineAmount;
        private String status;
        private String paymentDeadline;

        public static FineInfo from(FineRecord fine) {
            if (fine == null) {
                return null;
            }
            return FineInfo.builder()
                    .fineId(fine.getFineId())
                    .fineAmount(fine.getFineAmount() == null ? null : fine.getFineAmount().doubleValue())
                    .status(fine.getPaymentStatus())
                    .paymentDeadline(fine.getPaymentDeadline() == null ? null : fine.getPaymentDeadline().toString())
                    .build();
        }
    }

    @Data
    @Builder
    public static class AppealInfo {
        private Long appealId;
        private String appealType;
        private String appealReason;
        private String processStatus;

        public static AppealInfo from(AppealRecord appeal) {
            if (appeal == null) {
                return null;
            }
            return AppealInfo.builder()
                    .appealId(appeal.getAppealId())
                    .appealType(appeal.getAppealType())
                    .appealReason(appeal.getAppealReason())
                    .processStatus(appeal.getProcessStatus())
                    .build();
        }
    }

    private static String firstNonBlank(String first, String second) {
        return first != null && !first.isBlank() ? first : second;
    }
}
