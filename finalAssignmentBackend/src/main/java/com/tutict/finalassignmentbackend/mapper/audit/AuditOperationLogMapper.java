package com.tutict.finalassignmentbackend.mapper.audit;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.audit.AuditOperationLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AuditOperationLogMapper extends BaseMapper<AuditOperationLog> {
}
