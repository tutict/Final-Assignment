package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.exception.BusinessException;
import finalassignmentbackend.mapper.OffenseRecordMapper;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.offense.governance.AfterCommitBoundary;
import finalassignmentbackend.offense.governance.FullUpdateCompatibilityMode;
import finalassignmentbackend.offense.governance.FullUpdateMergePolicy;
import finalassignmentbackend.offense.governance.MutationSideEffectPolicy;
import finalassignmentbackend.offense.governance.OffenseGovernanceDecision;
import finalassignmentbackend.offense.governance.OffenseGovernanceLogFactory;
import finalassignmentbackend.offense.governance.OffenseSideEffectCoordinator;
import finalassignmentbackend.offense.governance.OffenseStaleUpdatePolicy;
import finalassignmentbackend.offense.governance.OffenseUpdateFreshnessEvaluator;
import finalassignmentbackend.offense.governance.OffenseUpdateMergeCoordinator;
import finalassignmentbackend.offense.governance.SemanticEventType;
import finalassignmentbackend.offense.governance.SemanticIntentClassifier;
import finalassignmentbackend.offense.governance.StaleFullUpdateRejectedException;
import finalassignmentbackend.offense.governance.rollout.GovernanceRolloutPolicy;
import finalassignmentbackend.offense.governance.rollout.GovernanceSourceType;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@ApplicationScoped
@RegisterForReflection
public class OffenseRecordService {

    private static final Logger log = Logger.getLogger(OffenseRecordService.class.getName());

    @Inject
    OffenseRecordMapper offenseRecordMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Inject
    OffenseKafkaProducer offenseKafkaProducer;

    // 治理组件（对齐 Spring service/offense/OffenseRecordService）。均为无状态纯逻辑，直接实例化。
    private final SemanticIntentClassifier semanticIntentClassifier = new SemanticIntentClassifier();
    private final OffenseSideEffectCoordinator sideEffectCoordinator =
            new OffenseSideEffectCoordinator(new AfterCommitBoundary());
    private final OffenseUpdateMergeCoordinator updateMergeCoordinator = new OffenseUpdateMergeCoordinator();
    private final OffenseUpdateFreshnessEvaluator updateFreshnessEvaluator = new OffenseUpdateFreshnessEvaluator();
    private final FullUpdateMergePolicy fullUpdateMergePolicy = new FullUpdateMergePolicy();
    private final GovernanceRolloutPolicy governanceRolloutPolicy = new GovernanceRolloutPolicy();

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    @WsAction(service = "OffenseRecordService", action = "checkAndInsertIdempotency", roles = {"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "APPEAL_REVIEWER"})
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseRecord record, String action) {
        Objects.requireNonNull(record, "Offense record must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate offense request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);

        // 非 create 动作：service 层发布 Kafka 命令（对齐 Spring 的 publishKafkaLegacy）
        if (!"create".equalsIgnoreCase(action)) {
            MutationSideEffectPolicy policy = semanticIntentClassifier.classifyIdempotencyPublish(action);
            sideEffectCoordinator.publishKafkaLegacy(policy, () -> offenseKafkaProducer.sendUpdate(idempotencyKey, record));
        }

        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(record.getOffenseId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public OffenseRecord createOffenseRecord(OffenseRecord record) {
        MutationSideEffectPolicy policy = semanticIntentClassifier.classifyCreate();
        validateRecord(record);
        offenseRecordMapper.insert(record);
        syncToIndexAfterCommit(policy, record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public OffenseRecord updateOffenseRecord(OffenseRecord record) {
        MutationSideEffectPolicy policy = semanticIntentClassifier.classifyUpdate();
        shadowCompareControllerFullUpdate(record);
        validateRecordId(record);
        int rows = offenseRecordMapper.updateById(record);
        if (rows == 0) {
            throw new IllegalStateException("Offense record not found: " + record.getOffenseId());
        }
        syncToIndexAfterCommit(policy, record);
        return record;
    }

    /**
     * Kafka 驱动的全量更新：陈旧检测 → 护栏合并（保护空/不可变/工作流字段）→ 落库。
     * 对齐 Spring 的 updateKafkaFullUpdate，是 P0 治理合并的核心入口。
     */
    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public OffenseRecord updateKafkaFullUpdate(OffenseRecord incoming) {
        MutationSideEffectPolicy policy = semanticIntentClassifier.classifyUpdate();
        Objects.requireNonNull(incoming, "OffenseRecord must not be null");
        requirePositive(incoming.getOffenseId(), "Offense ID");
        OffenseRecord current = offenseRecordMapper.selectById(incoming.getOffenseId());
        if (current == null) {
            validateRecord(incoming);
            int rows = offenseRecordMapper.updateById(incoming);
            if (rows == 0) {
                throw new IllegalStateException("No OffenseRecord updated for id=" + incoming.getOffenseId());
            }
            syncToIndexAfterCommit(policy, incoming);
            return incoming;
        }

        OffenseStaleUpdatePolicy.Decision freshness =
                updateFreshnessEvaluator.evaluate(current, incoming, SemanticEventType.FULL_UPDATE);
        if (freshness == OffenseStaleUpdatePolicy.Decision.SHADOW_ONLY) {
            if (governanceRolloutPolicy.shouldRejectStale(GovernanceSourceType.KAFKA, SemanticEventType.FULL_UPDATE)) {
                OffenseGovernanceDecision decision = OffenseGovernanceLogFactory.staleKafkaRejected(
                        incoming.getOffenseId(),
                        current.getUpdatedAt(),
                        incoming.getUpdatedAt()
                );
                throw new StaleFullUpdateRejectedException(decision);
            }
            logGovernance(Level.INFO, OffenseGovernanceLogFactory.shadowStale(
                    OffenseGovernanceDecision.Source.KAFKA,
                    incoming.getOffenseId(),
                    current.getUpdatedAt(),
                    incoming.getUpdatedAt()
            ));
        }

        FullUpdateMergePolicy.MergeResult merge =
                fullUpdateMergePolicy.merge(current, incoming, FullUpdateCompatibilityMode.GUARDED_COMPATIBILITY);
        logFullUpdateMergeGovernance(OffenseGovernanceDecision.Source.KAFKA, incoming.getOffenseId(), merge);
        OffenseRecord guarded = merge.mergedRecord();
        validateRecord(guarded);
        int rows = offenseRecordMapper.updateById(guarded);
        if (rows == 0) {
            throw new IllegalStateException("No OffenseRecord updated for id=" + guarded.getOffenseId());
        }
        syncToIndexAfterCommit(policy, guarded);
        return guarded;
    }

    @Transactional(rollbackOn = Exception.class)
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public OffenseRecord updateProcessStatus(Long offenseId, OffenseProcessState newState) {
        MutationSideEffectPolicy policy = semanticIntentClassifier.classifyWorkflow();
        requirePositive(offenseId, "Offense ID");
        OffenseRecord existing = offenseRecordMapper.selectById(offenseId);
        if (existing == null) {
            throw new IllegalStateException("OffenseRecord not found for id=" + offenseId);
        }
        // 仅允许状态机计算出的状态覆盖数据库的 process_status 字段
        OffenseRecord incoming = new OffenseRecord();
        incoming.setOffenseId(offenseId);
        incoming.setProcessStatus(newState != null ? newState.getCode() : existing.getProcessStatus());
        incoming.setUpdatedAt(LocalDateTime.now());
        OffenseStaleUpdatePolicy.Decision freshness =
                updateFreshnessEvaluator.evaluate(existing, incoming, SemanticEventType.WORKFLOW);
        if (freshness == OffenseStaleUpdatePolicy.Decision.REJECT_STALE) {
            OffenseGovernanceDecision decision = OffenseGovernanceLogFactory.workflowStaleRejected(
                    offenseId,
                    existing.getProcessStatus(),
                    incoming.getProcessStatus(),
                    existing.getProcessTime(),
                    incoming.getProcessTime()
            );
            if (governanceRolloutPolicy.shouldRejectStale(GovernanceSourceType.WORKFLOW, SemanticEventType.WORKFLOW)) {
                logGovernance(Level.WARNING, decision);
                throw new IllegalStateException("Stale Offense workflow update rejected for id=" + offenseId);
            }
            logGovernance(Level.INFO, decision);
        }
        OffenseRecord merged = updateMergeCoordinator.merge(existing, incoming, SemanticEventType.WORKFLOW);
        UpdateWrapper<OffenseRecord> updateWrapper = new UpdateWrapper<OffenseRecord>()
                .eq("offense_id", offenseId)
                .set("process_status", merged.getProcessStatus())
                .set("updated_at", merged.getUpdatedAt());
        applyOffenseStatusPrecondition(updateWrapper, existing.getProcessStatus());
        int rows = offenseRecordMapper.update(null, updateWrapper);
        if (rows == 0) {
            throw new BusinessException("CONFLICT", "该记录已被处理，无法重复操作");
        }
        syncToIndexAfterCommit(policy, merged);
        return merged;
    }

    /**
     * 提交后发布 create 命令到 Kafka（对齐 Spring 的 publishCreateKafkaAfterCommit）。
     */
    @Transactional
    public void publishCreateKafkaAfterCommit(String idempotencyKey, OffenseRecord offenseRecord) {
        Objects.requireNonNull(offenseRecord, "OffenseRecord must not be null");
        MutationSideEffectPolicy policy = semanticIntentClassifier.classifyIdempotencyPublish("create");
        sideEffectCoordinator.publishKafkaAfterCommit(policy,
                () -> offenseKafkaProducer.sendCreate(idempotencyKey, offenseRecord));
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public void deleteOffenseRecord(Long offenseId) {
        requirePositive(offenseId, "Offense ID");
        int rows = offenseRecordMapper.deleteById(offenseId);
        if (rows == 0) {
            throw new IllegalStateException("Offense record not found: " + offenseId);
        }
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public OffenseRecord findById(Long offenseId) {
        requirePositive(offenseId, "Offense ID");
        return offenseRecordMapper.selectById(offenseId);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> findAll() {
        return offenseRecordMapper.selectList(null);
    }

    public Page<OffenseRecord> findPage(int page, int size) {
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.orderByDesc("offense_time");
        Page<OffenseRecord> mpPage = new Page<>(page, size);
        offenseRecordMapper.selectPage(mpPage, wrapper);
        return mpPage;
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> findByDriverId(Long driverId, int page, int size) {
        if (driverId == null || driverId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> findByVehicleId(Long vehicleId, int page, int size) {
        if (vehicleId == null || vehicleId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("vehicle_id", vehicleId)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseCode(String offenseCode, int page, int size) {
        if (isBlank(offenseCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_code", offenseCode)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByProcessStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("process_status", status)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.between("offense_time", start, end)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseNumber(String offenseNumber, int page, int size) {
        if (isBlank(offenseNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_number", offenseNumber)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseLocation(String offenseLocation, int page, int size) {
        if (isBlank(offenseLocation)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_location", offenseLocation)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseProvince(String offenseProvince, int page, int size) {
        if (isBlank(offenseProvince)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_province", offenseProvince)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseCity(String offenseCity, int page, int size) {
        if (isBlank(offenseCity)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_city", offenseCity)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByNotificationStatus(String notificationStatus, int page, int size) {
        if (isBlank(notificationStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("notification_status", notificationStatus)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByEnforcementAgency(String enforcementAgency, int page, int size) {
        if (isBlank(enforcementAgency)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("enforcement_agency", enforcementAgency)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByFineAmountRange(double minAmount, double maxAmount, int page, int size) {
        validatePagination(page, size);
        if (minAmount > maxAmount) {
            return List.of();
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.between("fine_amount", minAmount, maxAmount)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long offenseId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(offenseId);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    /**
     * 仅用于治理回归测试的 Kafka 更新合并影子比较。生产代码不应调用此方法。
     *
     * @deprecated 仅供测试使用
     */
    @Deprecated(since = "test-only")
    public void shadowCompareKafkaUpdateMerge(OffenseRecord incoming) {
        if (incoming == null || incoming.getOffenseId() == null) {
            return;
        }
        try {
            OffenseRecord current = offenseRecordMapper.selectById(incoming.getOffenseId());
            if (current == null) {
                return;
            }
            OffenseStaleUpdatePolicy.Decision freshness =
                    updateFreshnessEvaluator.evaluate(current, incoming, SemanticEventType.FULL_UPDATE);
            if (freshness == OffenseStaleUpdatePolicy.Decision.SHADOW_ONLY) {
                logGovernance(Level.INFO, OffenseGovernanceLogFactory.shadowStale(
                        OffenseGovernanceDecision.Source.KAFKA,
                        incoming.getOffenseId(),
                        current.getUpdatedAt(),
                        incoming.getUpdatedAt()
                ));
            }
            FullUpdateMergePolicy.MergeResult shadowMerge =
                    fullUpdateMergePolicy.merge(current, incoming, FullUpdateCompatibilityMode.LEGACY_SHADOW);
            logFullUpdateMergeGovernance(OffenseGovernanceDecision.Source.KAFKA, incoming.getOffenseId(), shadowMerge);
            if (!Objects.equals(shadowMerge.mergedRecord(), incoming)) {
                logGovernance(Level.INFO, OffenseGovernanceLogFactory.legacyCompatibilityMode(
                        OffenseGovernanceDecision.Source.KAFKA,
                        incoming.getOffenseId(),
                        FullUpdateCompatibilityMode.LEGACY_SHADOW,
                        shadowMerge.mergedRecord() == null ? null : shadowMerge.mergedRecord().getUpdatedAt(),
                        mergedGovernanceFields(shadowMerge)
                ));
            }
        } catch (Exception ex) {
            log.log(Level.WARNING, "Offense Kafka update shadow merge comparison failed", ex);
        }
    }

    private void shadowCompareControllerFullUpdate(OffenseRecord incoming) {
        if (incoming == null || incoming.getOffenseId() == null) {
            return;
        }
        try {
            OffenseRecord current = offenseRecordMapper.selectById(incoming.getOffenseId());
            if (current == null) {
                return;
            }
            OffenseStaleUpdatePolicy.Decision freshness =
                    updateFreshnessEvaluator.evaluate(current, incoming, SemanticEventType.FULL_UPDATE);
            if (freshness == OffenseStaleUpdatePolicy.Decision.SHADOW_ONLY
                    && governanceRolloutPolicy.shouldShadowLog(GovernanceSourceType.CONTROLLER, SemanticEventType.FULL_UPDATE)) {
                logGovernance(Level.INFO, OffenseGovernanceLogFactory.shadowStale(
                        OffenseGovernanceDecision.Source.CONTROLLER,
                        incoming.getOffenseId(),
                        current.getUpdatedAt(),
                        incoming.getUpdatedAt()
                ));
            }
            FullUpdateMergePolicy.MergeResult shadowMerge =
                    fullUpdateMergePolicy.merge(current, incoming, FullUpdateCompatibilityMode.LEGACY_SHADOW);
            logFullUpdateMergeGovernance(OffenseGovernanceDecision.Source.CONTROLLER, incoming.getOffenseId(), shadowMerge);
        } catch (Exception ex) {
            log.log(Level.WARNING, "Offense controller update shadow comparison failed", ex);
        }
    }

    private void applyOffenseStatusPrecondition(UpdateWrapper<OffenseRecord> updateWrapper,
                                                String currentProcessStatus) {
        if (currentProcessStatus == null) {
            updateWrapper.isNull("process_status");
        } else {
            updateWrapper.eq("process_status", currentProcessStatus);
        }
    }

    /**
     * Quarkus 无 Elasticsearch：在事务提交后仅记录一条 ES 同步跳过日志，保留治理副作用边界语义。
     */
    private void syncToIndexAfterCommit(MutationSideEffectPolicy policy, OffenseRecord offenseRecord) {
        if (offenseRecord == null) {
            return;
        }
        sideEffectCoordinator.indexAfterCommit(policy, () ->
                log.log(Level.FINE, "ES index skipped (no Elasticsearch in Quarkus) for offenseId={0}",
                        offenseRecord.getOffenseId()));
    }

    private void logFullUpdateMergeGovernance(OffenseGovernanceDecision.Source source,
                                              Long offenseId,
                                              FullUpdateMergePolicy.MergeResult merge) {
        if (merge == null) {
            return;
        }
        GovernanceSourceType sourceType = sourceType(source);
        LocalDateTime updatedAt = merge.mergedRecord() == null ? null : merge.mergedRecord().getUpdatedAt();
        if (source == OffenseGovernanceDecision.Source.CONTROLLER
                && merge.compatibilityMode() == FullUpdateCompatibilityMode.LEGACY_SHADOW) {
            logGovernance(Level.INFO, OffenseGovernanceLogFactory.legacyCompatibilityMode(
                    offenseId,
                    merge.compatibilityMode(),
                    updatedAt,
                    mergedGovernanceFields(merge)
            ));
        }
        if (!merge.nullPreservedFields().isEmpty()
                && governanceRolloutPolicy.shouldPreserveNulls(sourceType, SemanticEventType.FULL_UPDATE)) {
            logGovernance(Level.INFO, OffenseGovernanceLogFactory.nullFieldPreserved(
                    source,
                    offenseId,
                    merge.compatibilityMode(),
                    updatedAt,
                    merge.nullPreservedFields()
            ));
        }
        if (!merge.immutablePreservedFields().isEmpty()
                && governanceRolloutPolicy.shouldPreserveImmutableFields(sourceType, SemanticEventType.FULL_UPDATE)) {
            logGovernance(Level.INFO, OffenseGovernanceLogFactory.immutableFieldPreserved(
                    source,
                    offenseId,
                    merge.compatibilityMode(),
                    updatedAt,
                    merge.immutablePreservedFields()
            ));
        }
        if (!merge.workflowSuppressedFields().isEmpty()
                && governanceRolloutPolicy.shouldSuppressWorkflowOverwrite(sourceType, SemanticEventType.FULL_UPDATE)) {
            logGovernance(Level.INFO, OffenseGovernanceLogFactory.workflowFieldSuppressed(
                    source,
                    offenseId,
                    merge.compatibilityMode(),
                    updatedAt,
                    merge.workflowSuppressedFields()
            ));
        }
    }

    private List<String> mergedGovernanceFields(FullUpdateMergePolicy.MergeResult merge) {
        List<String> fields = new ArrayList<>();
        fields.addAll(merge.nullPreservedFields());
        fields.addAll(merge.immutablePreservedFields());
        fields.addAll(merge.workflowSuppressedFields());
        return fields.stream().distinct().collect(Collectors.toList());
    }

    private void logGovernance(Level level, OffenseGovernanceDecision decision) {
        log.log(level, OffenseGovernanceLogFactory.format(decision));
    }

    private GovernanceSourceType sourceType(OffenseGovernanceDecision.Source source) {
        if (source == null) {
            return null;
        }
        return switch (source) {
            case CONTROLLER -> GovernanceSourceType.CONTROLLER;
            case KAFKA -> GovernanceSourceType.KAFKA;
            case WORKFLOW -> GovernanceSourceType.WORKFLOW;
            case QUERY_REPAIR -> GovernanceSourceType.QUERY_REPAIR;
        };
    }

    private List<OffenseRecord> fetchFromDatabase(QueryWrapper<OffenseRecord> wrapper, int page, int size) {
        Page<OffenseRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        offenseRecordMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void requirePositive(Number number, String fieldName) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException(fieldName + " must be greater than zero");
        }
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
        }
    }

    private void validateRecord(OffenseRecord record) {
        if (record == null) {
            throw new IllegalArgumentException("Offense record must not be null");
        }
        if (record.getOffenseTime() == null) {
            record.setOffenseTime(LocalDateTime.now());
        }
        if (record.getProcessStatus() == null || record.getProcessStatus().isBlank()) {
            record.setProcessStatus("Pending");
        }
    }

    private void validateRecordId(OffenseRecord record) {
        validateRecord(record);
        if (record.getOffenseId() == null || record.getOffenseId() <= 0) {
            throw new IllegalArgumentException("Invalid offense ID: " + (record == null ? null : record.getOffenseId()));
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
