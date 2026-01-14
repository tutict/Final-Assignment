package com.tutict.finalassignmentcloud.traffic.config.statemachine.configs;

import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.AppealAcceptanceEvent;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.AppealAcceptanceState;
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
 * 申诉受理状态机配置
 * 映射数据表 appeal_record.acceptance_status 枚举
 */
@Configuration
@EnableStateMachineFactory(name = "appealAcceptanceStateMachineFactory")
public class AppealAcceptanceStateMachineConfig extends StateMachineConfigurerAdapter<AppealAcceptanceState, AppealAcceptanceEvent> {

    private static final Logger LOG = Logger.getLogger(AppealAcceptanceStateMachineConfig.class.getName());

    @Override
    public void configure(StateMachineConfigurationConfigurer<AppealAcceptanceState, AppealAcceptanceEvent> config)
            throws Exception {
        config.withConfiguration()
                .autoStartup(true)
                .listener(appealAcceptanceStateMachineListener());
    }

    @Override
    public void configure(StateMachineStateConfigurer<AppealAcceptanceState, AppealAcceptanceEvent> states)
            throws Exception {
        states.withStates()
                .initial(AppealAcceptanceState.PENDING)
                .states(EnumSet.allOf(AppealAcceptanceState.class));
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<AppealAcceptanceState, AppealAcceptanceEvent> transitions)
            throws Exception {
        transitions
                // 待受理-> 已受理                .withExternal()
                .source(AppealAcceptanceState.PENDING)
                .target(AppealAcceptanceState.ACCEPTED)
                .event(AppealAcceptanceEvent.ACCEPT)
                .and()

                // 待受理-> 不予受理
                .withExternal()
                .source(AppealAcceptanceState.PENDING)
                .target(AppealAcceptanceState.REJECTED)
                .event(AppealAcceptanceEvent.REJECT)
                .and()

                // 待受理-> 需补充材料
                .withExternal()
                .source(AppealAcceptanceState.PENDING)
                .target(AppealAcceptanceState.NEED_SUPPLEMENT)
                .event(AppealAcceptanceEvent.REQUEST_SUPPLEMENT)
                .and()

                // 需补充材料 -> 待受理（补充完成后重新排队）
                .withExternal()
                .source(AppealAcceptanceState.NEED_SUPPLEMENT)
                .target(AppealAcceptanceState.PENDING)
                .event(AppealAcceptanceEvent.SUPPLEMENT_COMPLETE)
                .and()

                // 不予受理 -> 待受理（重新提交）
                .withExternal()
                .source(AppealAcceptanceState.REJECTED)
                .target(AppealAcceptanceState.PENDING)
                .event(AppealAcceptanceEvent.RESUBMIT);
    }

    @Bean
    public StateMachineListener<AppealAcceptanceState, AppealAcceptanceEvent> appealAcceptanceStateMachineListener() {
        return new StateMachineListenerAdapter<AppealAcceptanceState, AppealAcceptanceEvent>() {
            @Override
            public void stateChanged(State<AppealAcceptanceState, AppealAcceptanceEvent> from,
                                     State<AppealAcceptanceState, AppealAcceptanceEvent> to) {
                LOG.log(Level.INFO, "申诉受理状态变更 {0} -> {1}",
                        new Object[]{from != null ? from.getId() : "null", to != null ? to.getId() : "null"});
            }

            @Override
            public void transition(Transition<AppealAcceptanceState, AppealAcceptanceEvent> transition) {
                if (transition.getSource() != null && transition.getTarget() != null && transition.getTrigger() != null) {
                    LOG.log(Level.INFO, "申诉受理状态迁移 {0} -> {1} via {2}",
                            new Object[]{transition.getSource().getId(), transition.getTarget().getId(),
                                    transition.getTrigger().getEvent()});
                }
            }
        };
    }
}
