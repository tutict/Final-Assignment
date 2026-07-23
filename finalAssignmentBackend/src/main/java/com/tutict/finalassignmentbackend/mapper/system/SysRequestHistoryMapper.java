package com.tutict.finalassignmentbackend.mapper.system;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.List;

@Mapper
public interface SysRequestHistoryMapper extends BaseMapper<SysRequestHistory> {
    @Insert("""
            INSERT IGNORE INTO sys_request_history (
                idempotency_key, request_method, request_url, business_type,
                business_status, user_id, created_at, updated_at
            ) VALUES (
                #{history.idempotencyKey}, #{history.requestMethod}, #{history.requestUrl},
                #{history.businessType}, #{history.businessStatus}, #{history.userId},
                #{history.createdAt}, #{history.updatedAt}
            )
            """)
    int insertAppealCreationHistoryIfAbsent(@Param("history") SysRequestHistory history);

    @Update("""
            UPDATE sys_request_history
            SET request_method = 'POST',
                request_url = '/api/appeals',
                request_params = NULL,
                business_type = 'AppealRecord',
                business_id = NULL,
                business_status = 'PROCESSING',
                user_id = #{userId},
                updated_at = CURRENT_TIMESTAMP
            WHERE idempotency_key = #{idempotencyKey}
              AND business_status = 'FAILED'
            """)
    int reopenFailedAppealCreation(@Param("idempotencyKey") String idempotencyKey,
                                   @Param("userId") Long userId);

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
