package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.ProgressItem;
import com.tutict.finalassignmentbackend.mapper.ProgressItemMapper;
import com.tutict.finalassignmentbackend.config.statemachine.ProgressEvent;
import com.tutict.finalassignmentbackend.config.statemachine.ProgressState;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.statemachine.StateMachine;
import org.springframework.statemachine.config.StateMachineFactory;
import org.springframework.statemachine.persist.StateMachinePersister;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ProgressItemService {

    private final ProgressItemMapper progressRepository;
    private final StateMachineFactory<ProgressState, ProgressEvent> stateMachineFactory;
    private final StateMachinePersister<ProgressState, ProgressEvent, ProgressItem> stateMachinePersister;

    @Autowired
    public ProgressItemService(
            ProgressItemMapper progressRepository,
            StateMachineFactory<ProgressState, ProgressEvent> stateMachineFactory,
            StateMachinePersister<ProgressState, ProgressEvent, ProgressItem> stateMachinePersister) {
        this.progressRepository = progressRepository;
        this.stateMachineFactory = stateMachineFactory;
        this.stateMachinePersister = stateMachinePersister;
    }

    @WsAction(service = "ProgressItemService", action = "createProgress")
    @CacheEvict(cacheNames = "progressCache", allEntries = true)
    public ProgressItem createProgress(ProgressItem progressItem) {
        progressItem.setStatus(ProgressState.PENDING.name());
        progressItem.setSubmitTime(LocalDateTime.now());
        progressRepository.insert(progressItem);
        return progressItem;
    }

    @WsAction(service = "ProgressItemService", action = "getAllProgress")
    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    public List<ProgressItem> getAllProgress() {
        return progressRepository.selectList(null);
    }

    @WsAction(service = "ProgressItemService", action = "getProgressByUsername")
    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    public List<ProgressItem> getProgressByUsername(String username) {
        return progressRepository.findByUsername(username);
    }

    @WsAction(service = "ProgressItemService", action = "updateProgressStatus")
    @CacheEvict(cacheNames = "progressCache", allEntries = true)
    public ProgressItem updateProgressStatus(int progressId, String newStatus) throws Exception {
        ProgressItem existingItem = progressRepository.selectById(progressId);
        if (existingItem == null) {
            return null;
        }

        // 创建状态机实例
        StateMachine<ProgressState, ProgressEvent> stateMachine = stateMachineFactory.getStateMachine();

        // 恢复状态
        stateMachinePersister.restore(stateMachine, existingItem);

        // 根据目标状态触发相应事件
        ProgressEvent event = mapStatusToEvent(newStatus);
        Message<ProgressEvent> eventMessage = MessageBuilder.withPayload(event).build();
        stateMachine.sendEvent(Mono.just(eventMessage)).subscribe();

        // 持久化状态
        stateMachinePersister.persist(stateMachine, existingItem);

        // 更新数据库
        progressRepository.updateById(existingItem);

        return existingItem;
    }

    @WsAction(service = "ProgressItemService", action = "deleteProgress")
    @CacheEvict(cacheNames = "progressCache", allEntries = true)
    public void deleteProgress(int progressId) {
        progressRepository.deleteById(progressId);
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

    private ProgressEvent mapStatusToEvent(String newStatus) {
        return switch (newStatus.toUpperCase()) {
            case "PENDING" -> ProgressEvent.REOPEN;
            case "PROCESSING" -> ProgressEvent.START_PROCESSING;
            case "COMPLETED" -> ProgressEvent.COMPLETE;
            case "ARCHIVED" -> ProgressEvent.ARCHIVE;
            default -> throw new IllegalArgumentException("Invalid status: " + newStatus);
        };
    }
}