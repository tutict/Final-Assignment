package com.tutict.finalassignmentcloud.config.db;

import com.baomidou.mybatisplus.core.MybatisConfiguration;
import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;
import com.tutict.finalassignmentcloud.entity.VehicleInformation;
import org.apache.ibatis.builder.MapperBuilderAssistant;
import org.apache.ibatis.reflection.SystemMetaObject;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class TimestampFillHandlerTest {

    @BeforeAll
    static void registerTableInfo() {
        MapperBuilderAssistant assistant = new MapperBuilderAssistant(new MybatisConfiguration(), "timestamp-fill-test");
        assistant.setCurrentNamespace(TimestampFillHandlerTest.class.getName());
        TableInfoHelper.initTableInfo(assistant, VehicleInformation.class);
    }

    @Test
    void insertFillsMissingTimestamps() {
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setLicensePlate("CLOUD-TEST-0001");

        new TimestampFillHandler().insertFill(SystemMetaObject.forObject(vehicle));

        assertNotNull(vehicle.getCreatedAt());
        assertNotNull(vehicle.getUpdatedAt());
    }

    @Test
    void insertKeepsExplicitTimestamp() {
        LocalDateTime createdAt = LocalDateTime.of(2026, 1, 2, 3, 4, 5);
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setCreatedAt(createdAt);

        new TimestampFillHandler().insertFill(SystemMetaObject.forObject(vehicle));

        assertEquals(createdAt, vehicle.getCreatedAt());
    }

    @Test
    void updateFillsUpdatedAt() {
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setVehicleId(7L);

        new TimestampFillHandler().updateFill(SystemMetaObject.forObject(vehicle));

        assertNotNull(vehicle.getUpdatedAt());
    }
}
