package com.tutict.finalassignmentbackend.config.statemachine.configs;

import com.tutict.finalassignmentbackend.config.statemachine.events.OffenseProcessEvent;
import com.tutict.finalassignmentbackend.config.statemachine.states.OffenseProcessState;
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
 * 违法记录处理状态机配置
 */
@Configuration
@EnableStateMachineFactory(name = "offenseProcessStateMachineFactory")
public class OffenseProcessStateMachineConfig extends StateMachineConfigurerAdapter<OffenseProcessState, OffenseProcessEvent> {

    private static final Logger LOG = Logger.getLogger(OffenseProcessStateMachineConfig.class.getName());

    @Override
    public void configure(StateMachineConfigurationConfigurer<OffenseProcessState, OffenseProcessEvent> config)
            throws Exception {
        config
                .withConfiguration()
                .autoStartup(true)
                .listener(offenseProcessStateMachineListener());
    }

    @Override
    public void configure(StateMachineStateConfigurer<OffenseProcessState, OffenseProcessEvent> states)
            throws Exception {
        states
                .withStates()
                .initial(OffenseProcessState.UNPROCESSED)
                .states(EnumSet.allOf(OffenseProcessState.class));
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<OffenseProcessState, OffenseProcessEvent> transitions)
            throws Exception {
        transitions
                // 未处理 -> 处理中
                .withExternal()
                .source(OffenseProcessState.UNPROCESSED)
                .target(OffenseProcessState.PROCESSING)
                .event(OffenseProcessEvent.START_PROCESSING)
                .and()

                // 处理中 -> 已处理
                .withExternal()
                .source(OffenseProcessState.PROCESSING)
                .target(OffenseProcessState.PROCESSED)
                .event(OffenseProcessEvent.COMPLETE_PROCESSING)
                .and()

                // 已处理 -> 申诉中
                .withExternal()
                .source(OffenseProcessState.PROCESSED)
                .target(OffenseProcessState.APPEALING)
                .event(OffenseProcessEvent.SUBMIT_APPEAL)
                .and()

                // 申诉中 -> 申诉通过
                .withExternal()
                .source(OffenseProcessState.APPEALING)
                .target(OffenseProcessState.APPEAL_APPROVED)
                .event(OffenseProcessEvent.APPROVE_APPEAL)
                .and()

                // 申诉中 -> 申诉驳回
                .withExternal()
                .source(OffenseProcessState.APPEALING)
                .target(OffenseProcessState.APPEAL_REJECTED)
                .event(OffenseProcessEvent.REJECT_APPEAL)
                .and()

                // 申诉中 -> 已处理（撤回申诉）
                .withExternal()
                .source(OffenseProcessState.APPEALING)
                .target(OffenseProcessState.PROCESSED)
                .event(OffenseProcessEvent.WITHDRAW_APPEAL)
                .and()

                // 任何状态 -> 已取消
                .withExternal()
                .source(OffenseProcessState.UNPROCESSED)
                .target(OffenseProcessState.CANCELLED)
                .event(OffenseProcessEvent.CANCEL)
                .and()
                .withExternal()
                .source(OffenseProcessState.PROCESSING)
                .target(OffenseProcessState.CANCELLED)
                .event(OffenseProcessEvent.CANCEL)
                .and()
                .withExternal()
                .source(OffenseProcessState.PROCESSED)
                .target(OffenseProcessState.CANCELLED)
                .event(OffenseProcessEvent.CANCEL);
    }

    @Bean
    public StateMachineListener<OffenseProcessState, OffenseProcessEvent> offenseProcessStateMachineListener() {
        return new StateMachineListenerAdapter<OffenseProcessState, OffenseProcessEvent>() {
            @Override
            public void stateChanged(State<OffenseProcessState, OffenseProcessEvent> from,
                                     State<OffenseProcessState, OffenseProcessEvent> to) {
                LOG.log(Level.INFO, "违法记录状态变更: {} -> {}",
                        from != null ? from.getId() : "null");
            }

            @Override
            public void transition(Transition<OffenseProcessState, OffenseProcessEvent> transition) {
                LOG.log(Level.INFO, "违法记录状态转换: {} -> {} 通过事件 {}",
                        transition.getSource().getId()
                );
            }
        };
    }
}