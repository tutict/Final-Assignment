package com.tutict.finalassignmentcloud.traffic.config.statemachine.configs;

import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.AppealProcessEvent;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.AppealProcessState;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.statemachine.config.EnableStateMachineFactory;
import org.springframework.statemachine.config.StateMachineConfigurerAdapter;
import org.springframework.statemachine.config.builders.StateMachineConfigurationConfigurer;
import org.springframework.statemachine.config.builders.StateMachineStateConfigurer;
import org.springframework.statemachine.config.builders.StateMachineTransitionConfigurer;
import org.springframework.statemachine.listener.StateMachineListener;
import org.springframework.statemachine.listener.StateMachineListenerAdapter;
import org.springframework.statemachine.state.State;
import org.springframework.statemachine.transition.Transition;

import java.util.EnumSet;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 申诉处理状态机配置
 */
@Configuration
@EnableStateMachineFactory(name = "appealProcessStateMachineFactory")
public class AppealProcessStateMachineConfig extends StateMachineConfigurerAdapter<AppealProcessState, AppealProcessEvent> {

    private static final Logger LOG = Logger.getLogger(AppealProcessStateMachineConfig.class.getName());

    @Override
    public void configure(StateMachineConfigurationConfigurer<AppealProcessState, AppealProcessEvent> config)
            throws Exception {
        config
                .withConfiguration()
                .autoStartup(true)
                .listener(appealProcessStateMachineListener());
    }

    @Override
    public void configure(StateMachineStateConfigurer<AppealProcessState, AppealProcessEvent> states)
            throws Exception {
        states
                .withStates()
                .initial(AppealProcessState.UNPROCESSED)
                .states(EnumSet.allOf(AppealProcessState.class));
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<AppealProcessState, AppealProcessEvent> transitions)
            throws Exception {
        transitions
                // 未处理 -> 审核中
                .withExternal()
                .source(AppealProcessState.UNPROCESSED)
                .target(AppealProcessState.UNDER_REVIEW)
                .event(AppealProcessEvent.START_REVIEW)
                .and()

                // 审核中 -> 已批准
                .withExternal()
                .source(AppealProcessState.UNDER_REVIEW)
                .target(AppealProcessState.APPROVED)
                .event(AppealProcessEvent.APPROVE)
                .and()

                // 审核中 -> 已驳回
                .withExternal()
                .source(AppealProcessState.UNDER_REVIEW)
                .target(AppealProcessState.REJECTED)
                .event(AppealProcessEvent.REJECT)
                .and()

                // 已驳回 -> 审核中（重新审核）
                .withExternal()
                .source(AppealProcessState.REJECTED)
                .target(AppealProcessState.UNDER_REVIEW)
                .event(AppealProcessEvent.REOPEN_REVIEW)
                .and()

                // 任何状态 -> 已撤回
                .withExternal()
                .source(AppealProcessState.UNPROCESSED)
                .target(AppealProcessState.WITHDRAWN)
                .event(AppealProcessEvent.WITHDRAW)
                .and()
                .withExternal()
                .source(AppealProcessState.UNDER_REVIEW)
                .target(AppealProcessState.WITHDRAWN)
                .event(AppealProcessEvent.WITHDRAW);
    }

    @Bean
    public StateMachineListener<AppealProcessState, AppealProcessEvent> appealProcessStateMachineListener() {
        return new StateMachineListenerAdapter<>() {
            @Override
            public void stateChanged(State<AppealProcessState, AppealProcessEvent> from,
                                     State<AppealProcessState, AppealProcessEvent> to) {
                LOG.log(Level.INFO, "申诉处理状态变更 {0} -> {1}",
                        new Object[]{from != null ? from.getId() : "null", to != null ? to.getId() : "null"});
            }

            @Override
            public void transition(Transition<AppealProcessState, AppealProcessEvent> transition) {
                if (transition.getSource() != null && transition.getTarget() != null && transition.getTrigger() != null) {
                    LOG.log(Level.INFO, "申诉处理状态转换 {0} -> {1} via {2}",
                            new Object[]{transition.getSource().getId(),
                                    transition.getTarget().getId(),
                                    transition.getTrigger().getEvent()});
                }
            }
        };
    }
}
