package com.tutict.finalassignmentcloud.traffic.config.statemachine.configs;

import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.DeductionEvent;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.DeductionState;
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
 * 扣分状态机配置
 * 对应 deduction_record.status
 */
@Configuration
@EnableStateMachineFactory(name = "deductionStateMachineFactory")
public class DeductionStateMachineConfig extends StateMachineConfigurerAdapter<DeductionState, DeductionEvent> {

    private static final Logger LOG = Logger.getLogger(DeductionStateMachineConfig.class.getName());

    @Override
    public void configure(StateMachineConfigurationConfigurer<DeductionState, DeductionEvent> config)
            throws Exception {
        config.withConfiguration()
                .autoStartup(true)
                .listener(deductionStateMachineListener());
    }

    @Override
    public void configure(StateMachineStateConfigurer<DeductionState, DeductionEvent> states)
            throws Exception {
        states.withStates()
                .initial(DeductionState.EFFECTIVE)
                .states(EnumSet.allOf(DeductionState.class));
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<DeductionState, DeductionEvent> transitions)
            throws Exception {
        transitions
                // 生效 -> 取消
                .withExternal()
                .source(DeductionState.EFFECTIVE)
                .target(DeductionState.CANCELLED)
                .event(DeductionEvent.CANCEL)
                .and()

                // 生效 -> 已恢复
                .withExternal()
                .source(DeductionState.EFFECTIVE)
                .target(DeductionState.RESTORED)
                .event(DeductionEvent.RESTORE)
                .and()

                // 取消 -> 生效（重新生效）
                .withExternal()
                .source(DeductionState.CANCELLED)
                .target(DeductionState.EFFECTIVE)
                .event(DeductionEvent.REACTIVATE)
                .and()

                // 已恢复 -> 生效（重新生效）
                .withExternal()
                .source(DeductionState.RESTORED)
                .target(DeductionState.EFFECTIVE)
                .event(DeductionEvent.REACTIVATE);
    }

    @Bean
    public StateMachineListener<DeductionState, DeductionEvent> deductionStateMachineListener() {
        return new StateMachineListenerAdapter<>() {
            @Override
            public void stateChanged(State<DeductionState, DeductionEvent> from,
                                     State<DeductionState, DeductionEvent> to) {
                LOG.log(Level.INFO, "扣分记录状态变更 {0} -> {1}",
                        new Object[]{from != null ? from.getId() : "null", to != null ? to.getId() : "null"});
            }

            @Override
            public void transition(Transition<DeductionState, DeductionEvent> transition) {
                if (transition.getSource() != null && transition.getTarget() != null && transition.getTrigger() != null) {
                    LOG.log(Level.INFO, "扣分记录状态迁移 {0} -> {1} via {2}",
                            new Object[]{transition.getSource().getId(), transition.getTarget().getId(),
                                    transition.getTrigger().getEvent()});
                }
            }
        };
    }
}
