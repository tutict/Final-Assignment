package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.ProgressItem;
import com.tutict.finalassignmentbackend.mapper.ProgressItemMapper;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ProgressItemService {

    private static final java.util.logging.Logger log = java.util.logging.Logger.getLogger(ProgressItemService.class.getName());

    private final ProgressItemMapper progressRepository;

    public ProgressItemService(ProgressItemMapper progressRepository) {
        this.progressRepository = progressRepository;
    }

    @WsAction(service = "ProgressItemService", action = "createProgress")
    @CacheEvict(cacheNames = "progressCache", allEntries = true)
    public ProgressItem createProgress(ProgressItem progressItem) {
        progressItem.setStatus("Pending"); // 初始状态
        progressItem.setSubmitTime(LocalDateTime.now().toString()); // 设置当前时间
        progressRepository.insert(progressItem); // 使用 insert 方法
        return progressItem;
    }

    @WsAction(service = "ProgressItemService", action = "getAllProgress")
    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    public List<ProgressItem> getAllProgress() {
        return progressRepository.selectList(null); // 使用 selectList 查询所有记录
    }

    @WsAction(service = "ProgressItemService", action = "getProgressByUsername")
    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    public List<ProgressItem> getProgressByUsername(String username) {
        return progressRepository.findByUsername(username); // 自定义查询
    }

    @WsAction(service = "ProgressItemService", action = "updateProgressStatus")
    @CacheEvict(cacheNames = "progressCache", allEntries = true)
    public ProgressItem updateProgressStatus(int progressId, ProgressItem progressItem) {
        ProgressItem existingItem = progressRepository.selectById(progressId);
        if (existingItem != null) {
            existingItem.setStatus(progressItem.getStatus());
            existingItem.setDetails(progressItem.getDetails());
            progressRepository.updateById(existingItem); // 使用 updateById 方法
            return existingItem;
        }
        return null;
    }

    @WsAction(service = "ProgressItemService", action = "deleteProgress")
    @CacheEvict(cacheNames = "progressCache", allEntries = true)
    public void deleteProgress(int progressId) {
        progressRepository.deleteById(progressId); // 使用 deleteById 方法
    }

    @WsAction(service = "ProgressItemService", action = "getProgressByStatus")
    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    public List<ProgressItem> getProgressByStatus(String status) {
        return progressRepository.findByStatus(status);
    }

    @WsAction(service = "ProgressItemService", action = "getProgressByTimeRange")
    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    public List<ProgressItem> getProgressByTimeRange(LocalDateTime startTime, LocalDateTime endTime) {
        return progressRepository.findByTimeRange(startTime.toString(), endTime.toString());
    }
}