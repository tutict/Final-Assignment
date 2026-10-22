package com.tutict.finalassignmentcloud.traffic.service;

import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.entity.DeductionRecord;
import com.tutict.finalassignmentcloud.entity.FineRecord;
import com.tutict.finalassignmentcloud.entity.OffenseRecord;
import com.tutict.finalassignmentcloud.entity.VehicleInformation;
import com.tutict.finalassignmentcloud.traffic.client.UserClient;
import com.tutict.finalassignmentcloud.traffic.mapper.AppealRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.DeductionRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.DriverInformationMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.FineRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.OffenseRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.VehicleInformationMapper;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class BusinessRecordViewServiceTest {

    private final DriverInformationMapper driverMapper = mock(DriverInformationMapper.class);
    private final VehicleInformationMapper vehicleMapper = mock(VehicleInformationMapper.class);
    private final OffenseRecordMapper offenseMapper = mock(OffenseRecordMapper.class);
    private final FineRecordMapper fineMapper = mock(FineRecordMapper.class);
    private final DeductionRecordMapper deductionMapper = mock(DeductionRecordMapper.class);
    private final AppealRecordMapper appealMapper = mock(AppealRecordMapper.class);
    private final UserClient userClient = mock(UserClient.class);

    private final BusinessRecordViewService service = new BusinessRecordViewService(
            driverMapper, vehicleMapper, offenseMapper, fineMapper, deductionMapper, appealMapper, userClient);

    @Test
    void vehicleWithoutDriverSurvivesEnrichment() {
        stubCounts();
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setVehicleId(21L);
        vehicle.setDriverId(null);
        vehicle.setLicensePlate("CLOUDKFK9004");

        assertDoesNotThrow(() -> service.enrichVehicles(List.of(vehicle)));

        assertNull(vehicle.getDriverName());
        assertEquals(0L, vehicle.getOffenseCount());
        assertEquals(0L, vehicle.getUnpaidFineCount());
        assertEquals(0L, vehicle.getAppealCount());
    }

    @Test
    void offenseWithoutDriverOrVehicleSurvivesEnrichment() {
        stubCounts();
        OffenseRecord offense = new OffenseRecord();
        offense.setOffenseId(31L);
        offense.setDriverId(null);
        offense.setVehicleId(null);

        assertDoesNotThrow(() -> service.enrichOffenses(List.of(offense)));

        assertNull(offense.getDriverName());
        assertNull(offense.getLicensePlate());
    }

    @Test
    void fineWithoutOffenseSurvivesEnrichment() {
        stubCounts();
        FineRecord fine = new FineRecord();
        fine.setFineId(41L);
        fine.setOffenseId(null);
        fine.setDriverId(null);

        assertDoesNotThrow(() -> service.enrichFines(List.of(fine)));

        assertNull(fine.getDriverName());
        assertNull(fine.getLicensePlate());
    }

    @Test
    void deductionAndAppealWithoutOffenseSurviveEnrichment() {
        stubCounts();
        DeductionRecord deduction = new DeductionRecord();
        deduction.setDeductionId(51L);
        deduction.setOffenseId(null);
        AppealRecord appeal = new AppealRecord();
        appeal.setAppealId(61L);
        appeal.setOffenseId(null);

        assertDoesNotThrow(() -> service.enrichDeductions(List.of(deduction)));
        assertDoesNotThrow(() -> service.enrichAppeals(List.of(appeal)));

        assertNull(deduction.getDriverName());
        assertNull(appeal.getDriverName());
    }

    private void stubCounts() {
        when(offenseMapper.selectCount(any())).thenReturn(0L);
        when(fineMapper.selectCount(any())).thenReturn(0L);
        when(appealMapper.selectCount(any())).thenReturn(0L);
        when(offenseMapper.selectList(any())).thenReturn(List.of());
        when(driverMapper.selectBatchIds(any())).thenReturn(List.of());
        when(vehicleMapper.selectBatchIds(any())).thenReturn(List.of());
        when(offenseMapper.selectBatchIds(any())).thenReturn(List.of());
    }
}
