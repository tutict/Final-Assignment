package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.entity.UserManagement;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserManagementMapper extends BaseMapper<UserManagement> {
}
