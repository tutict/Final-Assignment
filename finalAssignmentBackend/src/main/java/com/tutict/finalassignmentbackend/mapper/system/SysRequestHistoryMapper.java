package com.tutict.finalassignmentbackend.mapper.system;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface SysRequestHistoryMapper extends BaseMapper<SysRequestHistory> {
    @Select("SELECT * FROM sys_request_history WHERE idempotency_key = #{idempotencyKey} LIMIT 1")
    SysRequestHistory selectByIdempotencyKey(@Param("idempotencyKey") String idempotencyKey);

    @Select("""
            SELECT h.*
            FROM sys_request_history h
            JOIN sys_user u ON u.user_id = h.user_id
            WHERE u.username = #{username}
            ORDER BY h.updated_at DESC
            LIMIT #{size} OFFSET #{offset}
            """)
    List<SysRequestHistory> selectByUsername(@Param("username") String username,
                                             @Param("offset") long offset,
                                             @Param("size") long size);
}
