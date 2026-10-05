package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.entity.SysRequestHistory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface SysRequestHistoryMapper extends BaseMapper<SysRequestHistory> {
    @Select("SELECT id, idempotency_key AS idempotencyKey, request_method AS requestMethod, request_url AS requestUrl, request_params AS requestParams, business_type AS businessType, business_id AS businessId, business_status AS businessStatus, user_id AS userId, request_ip AS requestIp, created_at AS createdAt, updated_at AS updatedAt, deleted_at AS deletedAt FROM sys_request_history WHERE idempotency_key = #{idempotencyKey} AND deleted_at IS NULL LIMIT 1")
    SysRequestHistory selectByIdempotencyKey(@Param("idempotencyKey") String idempotencyKey);

    @Select("""
            SELECT h.id, h.idempotency_key AS idempotencyKey, h.request_method AS requestMethod,
                   h.request_url AS requestUrl, h.request_params AS requestParams,
                   h.business_type AS businessType, h.business_id AS businessId,
                   h.business_status AS businessStatus, h.user_id AS userId, h.request_ip AS requestIp,
                   h.created_at AS createdAt, h.updated_at AS updatedAt, h.deleted_at AS deletedAt
            FROM sys_request_history h
            JOIN sys_user u ON u.user_id = h.user_id
            WHERE u.username = #{username} AND h.deleted_at IS NULL
            ORDER BY h.updated_at DESC
            LIMIT 50
            """)
    java.util.List<SysRequestHistory> selectByUsername(@Param("username") String username);
}



