package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.entity.LoginLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface LoginLogMapper extends BaseMapper<LoginLog> {
}
