package com.tutict.finalassignmentbackend.config.statemachine;

import com.tutict.finalassignmentbackend.entity.ProgressItem;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.statemachine.StateMachinePersist;
import org.springframework.statemachine.config.EnableStateMachineFactory;
import org.springframework.statemachine.config.StateMachineConfigurerAdapter;
import org.springframework.statemachine.config.builders.StateMachineConfigurationConfigurer;
import org.springframework.statemachine.config.builders.StateMachineStateConfigurer;
import org.springframework.statemachine.config.builders.StateMachineTransitionConfigurer;
import org.springframework.statemachine.persist.StateMachinePersister;
import org.springframework.statemachine.persist.DefaultStateMachinePersister;

import java.util.EnumSet;

@Configuration
@EnableStateMachineFactory
public class StateMachineConfig extends StateMachineConfigurerAdapter<ProgressState, ProgressEvent> {

    @Override
    public void configure(StateMachineConfigurationConfigurer<ProgressState, ProgressEvent> config) throws Exception {
        config
                .withConfiguration()
                .autoStartup(true);
    }

    @Override
    public void configure(StateMachineStateConfigurer<ProgressState, ProgressEvent> states) throws Exception {
        states
                .withStates()
                .initial(ProgressState.PENDING)
                .states(EnumSet.allOf(ProgressState.class));
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<ProgressState, ProgressEvent> transitions) throws Exception {
        transitions
                .withExternal()
                .source(ProgressState.PENDING).target(ProgressState.PROCESSING).event(ProgressEvent.START_PROCESSING)
                .and()
                .withExternal()
                .source(ProgressState.PROCESSING).target(ProgressState.COMPLETED).event(ProgressEvent.COMPLETE)
                .and()
                .withExternal()
                .source(ProgressState.COMPLETED).target(ProgressState.ARCHIVED).event(ProgressEvent.ARCHIVE)
                .and()
                .withExternal()
                .source(ProgressState.ARCHIVED).target(ProgressState.PENDING).event(ProgressEvent.REOPEN);
    }

    @Bean
    public StateMachinePersist<ProgressState, ProgressEvent, ProgressItem> stateMachinePersist() {
        return new ProgressStateMachinePersist();
    }

    @Bean
    public StateMachinePersister<ProgressState, ProgressEvent, ProgressItem> stateMachinePersister(
            @Qualifier("stateMachinePersist") StateMachinePersist<ProgressState, ProgressEvent, ProgressItem> persist) {
        return new DefaultStateMachinePersister<>(persist);
    }
}