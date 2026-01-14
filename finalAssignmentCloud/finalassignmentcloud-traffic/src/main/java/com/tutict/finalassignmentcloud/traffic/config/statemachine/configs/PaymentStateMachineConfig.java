package com.tutict.finalassignmentcloud.traffic.config.statemachine.configs;

import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.PaymentEvent;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.PaymentState;
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
 * 支付状态机配置
 */
@Configuration
@EnableStateMachineFactory(name = "paymentStateMachineFactory")
public class PaymentStateMachineConfig extends StateMachineConfigurerAdapter<PaymentState, PaymentEvent> {

    private static final Logger LOG = Logger.getLogger(PaymentStateMachineConfig.class.getName());

    @Override
    public void configure(StateMachineConfigurationConfigurer<PaymentState, PaymentEvent> config)
            throws Exception {
        config
                .withConfiguration()
                .autoStartup(true)
                .listener(paymentStateMachineListener());
    }

    @Override
    public void configure(StateMachineStateConfigurer<PaymentState, PaymentEvent> states)
            throws Exception {
        states
                .withStates()
                .initial(PaymentState.UNPAID)
                .states(EnumSet.allOf(PaymentState.class));
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<PaymentState, PaymentEvent> transitions)
            throws Exception {
        transitions
                // 未支付-> 部分支付
                .withExternal()
                .source(PaymentState.UNPAID)
                .target(PaymentState.PARTIAL)
                .event(PaymentEvent.PARTIAL_PAY)
                .and()

                // 部分支付 -> 已支付
                .withExternal()
                .source(PaymentState.PARTIAL)
                .target(PaymentState.PAID)
                .event(PaymentEvent.CONTINUE_PAYMENT)
                .and()

                // 未支付-> 已支付（一次性支付完成）
                .withExternal()
                .source(PaymentState.UNPAID)
                .target(PaymentState.PAID)
                .event(PaymentEvent.COMPLETE_PAYMENT)
                .and()

                // 未支付-> 逾期
                .withExternal()
                .source(PaymentState.UNPAID)
                .target(PaymentState.OVERDUE)
                .event(PaymentEvent.MARK_OVERDUE)
                .and()

                // 部分支付 -> 逾期
                .withExternal()
                .source(PaymentState.PARTIAL)
                .target(PaymentState.OVERDUE)
                .event(PaymentEvent.MARK_OVERDUE)
                .and()

                // 逾期 -> 已支付
                .withExternal()
                .source(PaymentState.OVERDUE)
                .target(PaymentState.PAID)
                .event(PaymentEvent.COMPLETE_PAYMENT)
                .and()

                // 任何状态-> 减免
                .withExternal()
                .source(PaymentState.UNPAID)
                .target(PaymentState.WAIVED)
                .event(PaymentEvent.WAIVE_FINE)
                .and()
                .withExternal()
                .source(PaymentState.PARTIAL)
                .target(PaymentState.WAIVED)
                .event(PaymentEvent.WAIVE_FINE)
                .and()
                .withExternal()
                .source(PaymentState.OVERDUE)
                .target(PaymentState.WAIVED)
                .event(PaymentEvent.WAIVE_FINE)
                .and()
                .withExternal()
                .source(PaymentState.PAID)
                .target(PaymentState.WAIVED)
                .event(PaymentEvent.WAIVE_FINE);
    }

    @Bean
    public StateMachineListener<PaymentState, PaymentEvent> paymentStateMachineListener() {
        return new StateMachineListenerAdapter<>() {
            @Override
            public void stateChanged(State<PaymentState, PaymentEvent> from,
                                     State<PaymentState, PaymentEvent> to) {
                LOG.log(Level.INFO, "支付状态变更 {0} -> {1}",
                        new Object[]{from != null ? from.getId() : "null", to != null ? to.getId() : "null"});
            }

            @Override
            public void transition(Transition<PaymentState, PaymentEvent> transition) {
                if (transition.getSource() != null && transition.getTarget() != null && transition.getTrigger() != null) {
                    LOG.log(Level.INFO, "支付状态转换 {0} -> {1} via {2}",
                            new Object[]{transition.getSource().getId(),
                                    transition.getTarget().getId(),
                                    transition.getTrigger().getEvent()});
                }
            }
        };
    }
}

