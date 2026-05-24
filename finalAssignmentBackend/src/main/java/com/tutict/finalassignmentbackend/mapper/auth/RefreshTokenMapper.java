package com.tutict.finalassignmentbackend.mapper.auth;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.auth.RefreshToken;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface RefreshTokenMapper extends BaseMapper<RefreshToken> {
}
