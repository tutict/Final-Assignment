package com.tutict.finalassignmentcloud.mapper.offense;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentcloud.entity.offense.OffenseRecord;
import org.apache.ibatis.annotations.Mapper;

/**
 * MyBatis-Plus mapper for OffenseRecord
 * Provides basic CRUD operations for offense records
 */
@Mapper
public interface OffenseRecordMapper extends BaseMapper<OffenseRecord> {
    // MyBatis-Plus provides basic CRUD operations
    // Add custom queries here if needed
}
