package com.tutict.finalassignmentbackend.service.offense;

import com.tutict.finalassignmentbackend.dto.response.OffenseDetailResponse;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.exception.EntityNotFoundException;
import com.tutict.finalassignmentbackend.service.appeal.AppealRecordService;
import com.tutict.finalassignmentbackend.service.driver.DriverInformationService;
import com.tutict.finalassignmentbackend.service.driver.VehicleInformationService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OffenseDetailService {

    private final OffenseRecordService offenseRecordService;
    private final DriverInformationService driverInformationService;
    private final VehicleInformationService vehicleInformationService;
    private final FineRecordService fineRecordService;
    private final AppealRecordService appealRecordService;

    public OffenseDetailService(OffenseRecordService offenseRecordService,
                                DriverInformationService driverInformationService,
                                VehicleInformationService vehicleInformationService,
                                FineRecordService fineRecordService,
                                AppealRecordService appealRecordService) {
        this.offenseRecordService = offenseRecordService;
        this.driverInformationService = driverInformationService;
        this.vehicleInformationService = vehicleInformationService;
        this.fineRecordService = fineRecordService;
        this.appealRecordService = appealRecordService;
    }

    @Transactional(readOnly = true)
    public OffenseDetailResponse getOffenseDetail(Long offenseId) {
        OffenseRecord offense = offenseRecordService.findById(offenseId);
        if (offense == null) {
            throw new EntityNotFoundException("Offense not found: " + offenseId);
        }
        return OffenseDetailResponse.from(
                offense,
                offense.getDriverId() == null ? null : driverInformationService.getDriverById(offense.getDriverId()),
                offense.getVehicleId() == null ? null : vehicleInformationService.getVehicleInformationById(offense.getVehicleId()),
                fineRecordService.findByOffenseId(offenseId, 1, 100),
                appealRecordService.findByOffenseId(offenseId, 1, 100));
    }
}
