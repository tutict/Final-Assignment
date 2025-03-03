package com.tutict.finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.ProgressItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ProgressItemMapper extends BaseMapper<ProgressItem> {

    @Select("SELECT * FROM progress_items WHERE username = #{username}")
    List<ProgressItem> findByUsername(String username);

    @Select("SELECT * FROM progress_items WHERE status = #{status}")
    List<ProgressItem> findByStatus(String status);

    @Select("SELECT * FROM progress_items WHERE submit_time BETWEEN #{startTime} AND #{endTime}")
    List<ProgressItem> findByTimeRange(String startTime, String endTime);
}