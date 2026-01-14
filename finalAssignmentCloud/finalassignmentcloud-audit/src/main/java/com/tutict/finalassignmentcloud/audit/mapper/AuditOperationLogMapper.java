package com.tutict.finalassignmentcloud.audit.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentcloud.entity.AuditOperationLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AuditOperationLogMapper extends BaseMapper<AuditOperationLog> {
}

