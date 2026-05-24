package com.tutict.finalassignmentbackend.mapper.payment;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PaymentRecordMapper extends BaseMapper<PaymentRecord> {
}
