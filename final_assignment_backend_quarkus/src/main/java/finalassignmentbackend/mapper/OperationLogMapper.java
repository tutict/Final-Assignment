package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.entity.OperationLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface OperationLogMapper extends BaseMapper<OperationLog> {
}
