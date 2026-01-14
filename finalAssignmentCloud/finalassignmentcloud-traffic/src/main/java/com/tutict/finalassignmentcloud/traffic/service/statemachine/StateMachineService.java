package com.tutict.finalassignmentcloud.traffic.service.statemachine;

import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.*;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.*;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.statemachine.StateMachine;
import org.springframework.statemachine.StateMachineContext;
import org.springframework.statemachine.config.StateMachineFactory;
import org.springframework.statemachine.support.DefaultStateMachineContext;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 状态机服务类
 * 提供统一的状态机管理和操作接口
 */
@Service
public class StateMachineService {

    private static final Logger LOG = Logger.getLogger(StateMachineService.class.getName());

    private final StateMachineFactory<OffenseProcessState, OffenseProcessEvent> offenseProcessStateMachineFactory;

    private final StateMachineFactory<PaymentState, PaymentEvent> paymentStateMachineFactory;

    private final StateMachineFactory<AppealProcessState, AppealProcessEvent> appealProcessStateMachineFactory;

    public StateMachineService(@Qualifier("offenseProcessStateMachineFactory") StateMachineFactory<OffenseProcessState, OffenseProcessEvent> offenseProcessStateMachineFactory, @Qualifier("paymentStateMachineFactory") StateMachineFactory<PaymentState, PaymentEvent> paymentStateMachineFactory, @Qualifier("appealProcessStateMachineFactory") StateMachineFactory<AppealProcessState, AppealProcessEvent> appealProcessStateMachineFactory) {
        this.offenseProcessStateMachineFactory = offenseProcessStateMachineFactory;
        this.paymentStateMachineFactory = paymentStateMachineFactory;
        this.appealProcessStateMachineFactory = appealProcessStateMachineFactory;
    }

    /**
     * 处理违法记录状态转换
     *
     * @param offenseId 违法记录ID
     * @param currentState 当前状态
     * @param event 触发事件
     * @return 转换后的状态
     */
    public OffenseProcessState processOffenseState(Long offenseId, OffenseProcessState currentState, OffenseProcessEvent event) {
        try {
            StateMachine<OffenseProcessState, OffenseProcessEvent> stateMachine = offenseProcessStateMachineFactory.getStateMachine();

            // 将状态机重置到指定状态，确保状态迁移以数据库状态为准
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block()
            );

            // 发送事件，触发状态流转
            boolean result = stateMachine.sendEvent(event);

            if (result) {
                OffenseProcessState newState = stateMachine.getState().getId();
                LOG.log(Level.INFO, "违法记录 {0} 状态转换成功 {1} -> {2} (事件: {3})",
                        new Object[]{offenseId, currentState, newState, event});
                return newState;
            } else {
                LOG.log(Level.WARNING, "违法记录 {0} 状态转换失败 {1} (事件: {2})",
                        new Object[]{offenseId, currentState, event});
                return currentState;
            }
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "违法记录状态转换异常 " + e.getMessage(), e);
            return currentState;
        }
    }

    /**
     * 处理支付状态转换
     *
     * @param fineId 罚款记录ID
     * @param currentState 当前状态
     * @param event 触发事件
     * @return 转换后的状态
     */
    public PaymentState processPaymentState(Long fineId, PaymentState currentState, PaymentEvent event) {
        try {
            StateMachine<PaymentState, PaymentEvent> stateMachine = paymentStateMachineFactory.getStateMachine();

            // 支付场景同样需要将状态机回放到数据库中记录的状态
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block()
            );

            // 发送事件
            boolean result = stateMachine.sendEvent(event);

            if (result) {
                PaymentState newState = stateMachine.getState().getId();
                LOG.log(Level.INFO, "罚款记录 {0} 支付状态转换成功 {1} -> {2} (事件: {3})",
                        new Object[]{fineId, currentState, newState, event});
                return newState;
            } else {
                LOG.log(Level.WARNING, "罚款记录 {0} 支付状态转换失败 {1} (事件: {2})",
                        new Object[]{fineId, currentState, event});
                return currentState;
            }
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "支付状态转换异常 " + e.getMessage(), e);
            return currentState;
        }
    }

    /**
     * 处理申诉状态转换
     *
     * @param appealId 申诉记录ID
     * @param currentState 当前状态
     * @param event 触发事件
     * @return 转换后的状态
     */
    public AppealProcessState processAppealState(Long appealId, AppealProcessState currentState, AppealProcessEvent event) {
        try {
            StateMachine<AppealProcessState, AppealProcessEvent> stateMachine = appealProcessStateMachineFactory.getStateMachine();

            // 申诉状态较多，统一使用 StateMachine 来校验合法性
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block()
            );

            // 发送事件
            boolean result = stateMachine.sendEvent(event);

            if (result) {
                AppealProcessState newState = stateMachine.getState().getId();
                LOG.log(Level.INFO, "申诉记录 {0} 状态转换成功 {1} -> {2} (事件: {3})",
                        new Object[]{appealId, currentState, newState, event});
                return newState;
            } else {
                LOG.log(Level.WARNING, "申诉记录 {0} 状态转换失败 {1} (事件: {2})",
                        new Object[]{appealId, currentState, event});
                return currentState;
            }
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "申诉状态转换异常 " + e.getMessage(), e);
            return currentState;
        }
    }

    /**
     * 验证违法记录状态转换是否有效
     *
     * @param currentState 当前状态
     * @param event 要触发的事件
     * @return 是否可以转换
     */
    public boolean canTransitionOffenseState(OffenseProcessState currentState, OffenseProcessEvent event) {
        try {
            StateMachine<OffenseProcessState, OffenseProcessEvent> stateMachine = offenseProcessStateMachineFactory.getStateMachine();
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block()
            );

            return stateMachine.getTransitions().stream()
                    .anyMatch(transition ->
                            transition.getSource().getId().equals(currentState) &&
                            transition.getTrigger() != null &&
                            transition.getTrigger().getEvent().equals(event));
        } catch (Exception e) {
            LOG.log(Level.WARNING, "检查违法记录状态转换有效性失败 " + e.getMessage(), e);
            return false;
        }
    }

    /**
     * 验证支付状态转换是否有效
     *
     * @param currentState 当前状态
     * @param event 要触发的事件
     * @return 是否可以转换
     */
    public boolean canTransitionPaymentState(PaymentState currentState, PaymentEvent event) {
        try {
            StateMachine<PaymentState, PaymentEvent> stateMachine = paymentStateMachineFactory.getStateMachine();
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block()
            );

            return stateMachine.getTransitions().stream()
                    .anyMatch(transition ->
                            transition.getSource().getId().equals(currentState) &&
                            transition.getTrigger() != null &&
                            transition.getTrigger().getEvent().equals(event));
        } catch (Exception e) {
            LOG.log(Level.WARNING, "检查支付状态转换有效性失败 " + e.getMessage(), e);
            return false;
        }
    }

    /**
     * 验证申诉状态转换是否有效
     *
     * @param currentState 当前状态
     * @param event 要触发的事件
     * @return 是否可以转换
     */
    public boolean canTransitionAppealState(AppealProcessState currentState, AppealProcessEvent event) {
        try {
            StateMachine<AppealProcessState, AppealProcessEvent> stateMachine = appealProcessStateMachineFactory.getStateMachine();
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block()
            );

            return stateMachine.getTransitions().stream()
                    .anyMatch(transition ->
                            transition.getSource().getId().equals(currentState) &&
                            transition.getTrigger() != null &&
                            transition.getTrigger().getEvent().equals(event));
        } catch (Exception e) {
            LOG.log(Level.WARNING, "检查申诉状态转换有效性失败 " + e.getMessage(), e);
            return false;
        }
    }

    private <S, E> StateMachineContext<S, E> buildContext(S state) {
        // DefaultStateMachineContext 只关心当前状态，无事件扩展变量时传入 null 即可
        return new DefaultStateMachineContext<>(state, null, null, null);
    }
}
