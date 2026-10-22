package com.tutict.finalassignmentbackend.config.db;

import com.baomidou.mybatisplus.core.MybatisConfiguration;
import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserMapper;
import org.apache.ibatis.builder.MapperBuilderAssistant;
import org.apache.ibatis.reflection.SystemMetaObject;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;

class MetaFillHandlerTest {

    @BeforeAll
    static void registerTableInfo() {
        MapperBuilderAssistant assistant = new MapperBuilderAssistant(new MybatisConfiguration(), "meta-fill-test");
        assistant.setCurrentNamespace(MetaFillHandlerTest.class.getName());
        TableInfoHelper.initTableInfo(assistant, VehicleInformation.class);
    }

    @Test
    void insertFillsMissingTimestamps() {
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setLicensePlate("MONO-TEST-0001");

        new MetaFillHandler(mock(SysUserMapper.class)).insertFill(SystemMetaObject.forObject(vehicle));

        assertNotNull(vehicle.getCreatedAt());
        assertNotNull(vehicle.getUpdatedAt());
    }

    @Test
    void insertKeepsExplicitTimestamp() {
        LocalDateTime createdAt = LocalDateTime.of(2026, 1, 2, 3, 4, 5);
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setCreatedAt(createdAt);

        new MetaFillHandler(mock(SysUserMapper.class)).insertFill(SystemMetaObject.forObject(vehicle));

        assertEquals(createdAt, vehicle.getCreatedAt());
    }

    @Test
    void updateFillsUpdatedAt() {
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setVehicleId(7L);

        new MetaFillHandler(mock(SysUserMapper.class)).updateFill(SystemMetaObject.forObject(vehicle));

        assertNotNull(vehicle.getUpdatedAt());
    }
}
