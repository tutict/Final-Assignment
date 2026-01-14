package com.tutict.finalassignmentcloud.system.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface SysRequestHistoryMapper extends BaseMapper<SysRequestHistory> {
    @Select("SELECT * FROM sys_request_history WHERE idempotency_key = #{idempotencyKey} LIMIT 1")
    SysRequestHistory selectByIdempotencyKey(@Param("idempotencyKey") String idempotencyKey);
}

