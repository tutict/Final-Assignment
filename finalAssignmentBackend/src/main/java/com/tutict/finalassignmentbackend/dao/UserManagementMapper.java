package com.tutict.finalassignmentbackend.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserManagementMapper extends BaseMapper<UserManagement> {
}
