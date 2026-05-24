package com.tutict.finalassignmentbackend.appeal.query;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.appeal.query.dto.AppealPageRequest;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.mapper.appeal.AppealRecordMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AppealDbFallbackReader {

    private final AppealRecordMapper appealRecordMapper;

    public AppealDbFallbackReader(AppealRecordMapper appealRecordMapper) {
        this.appealRecordMapper = appealRecordMapper;
    }

    public AppealRecord findById(Long appealId) {
        return appealRecordMapper.selectById(appealId);
    }

    public List<AppealRecord> findByOffenseId(Long offenseId, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> findByDriverId(Long driverId, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appeal_number", appealNumber)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.like("appeal_number", appealNumber)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appellant_name", appellantName)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.like("appellant_name", appellantName)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appellant_id_card", appellantIdCard)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("acceptance_status", acceptanceStatus)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByProcessStatus(String processStatus, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("process_status", processStatus)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAppealTimeRange(
            LocalDateTime start,
            LocalDateTime end,
            AppealPageRequest pageRequest
    ) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.between("appeal_time", start, end)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("acceptance_handler", acceptanceHandler)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    public List<AppealRecord> findByCreatedBy(String createdBy, AppealPageRequest pageRequest) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("created_by", createdBy)
                .orderByDesc("appeal_time");
        return selectPage(wrapper, pageRequest);
    }

    private List<AppealRecord> selectPage(QueryWrapper<AppealRecord> wrapper, AppealPageRequest pageRequest) {
        Page<AppealRecord> mpPage = new Page<>(pageRequest.page(), pageRequest.size());
        appealRecordMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }
}
