package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.entity.RequestHistory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface RequestHistoryMapper extends BaseMapper<RequestHistory> {
    // 根据幂等键查询
    @Select("SELECT * FROM request_history WHERE idempotency_key = #{idempotencyKey}")
    RequestHistory selectByIdempotencyKey(@Param("idempotencyKey") String idempotencyKey);

}
