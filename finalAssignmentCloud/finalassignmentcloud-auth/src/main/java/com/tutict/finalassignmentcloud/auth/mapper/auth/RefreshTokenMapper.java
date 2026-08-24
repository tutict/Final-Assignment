package com.tutict.finalassignmentcloud.auth.mapper.auth;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentcloud.auth.entity.auth.RefreshToken;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface RefreshTokenMapper extends BaseMapper<RefreshToken> {
}