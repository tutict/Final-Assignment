package com.tutict.finalassignmentbackend.mapper.audit;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.audit.AuditLoginLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AuditLoginLogMapper extends BaseMapper<AuditLoginLog> {
}
