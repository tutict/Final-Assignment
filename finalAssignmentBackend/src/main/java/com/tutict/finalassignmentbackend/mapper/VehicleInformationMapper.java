package com.tutict.finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface VehicleInformationMapper extends BaseMapper<VehicleInformation> {
    @Select("SELECT * FROM vehicle_information")
    List<VehicleInformation> findAll();
}
