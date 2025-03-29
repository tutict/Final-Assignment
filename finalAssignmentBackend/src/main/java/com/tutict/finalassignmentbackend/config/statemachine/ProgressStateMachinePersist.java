package com.tutict.finalassignmentbackend.config.statemachine;

import com.tutict.finalassignmentbackend.entity.ProgressItem;
import org.springframework.statemachine.StateMachineContext;
import org.springframework.statemachine.StateMachinePersist;
import org.springframework.statemachine.support.DefaultExtendedState;
import org.springframework.statemachine.support.DefaultStateMachineContext;
import org.springframework.stereotype.Component;

import java.util.HashMap;

@Component
public class ProgressStateMachinePersist implements StateMachinePersist<ProgressState, ProgressEvent, ProgressItem> {

    @Override
    public void write(StateMachineContext<ProgressState, ProgressEvent> context, ProgressItem contextObj) {
        // 将状态机的状态保存到 ProgressItem
        contextObj.setStatus(context.getState().name());
    }

    @Override
    public StateMachineContext<ProgressState, ProgressEvent> read(ProgressItem contextObj) {
        // 从 ProgressItem 恢复状态机的状态
        try {
            if (contextObj.getStatus() == null) {
                // 如果状态为空，返回默认状态
                return new DefaultStateMachineContext<>(
                        ProgressState.PENDING, // state
                        null,                  // event
                        new HashMap<>(),       // eventHeaders
                        new DefaultExtendedState() // extendedState
                );
            }
            return new DefaultStateMachineContext<>(
                    ProgressState.valueOf(contextObj.getStatus()), // state
                    null,                                          // event
                    new HashMap<>(),                               // eventHeaders
                    new DefaultExtendedState()                     // extendedState
            );
        } catch (IllegalArgumentException e) {
            // 如果状态无效，返回默认状态
            return new DefaultStateMachineContext<>(
                    ProgressState.PENDING, // state
                    null,                  // event
                    new HashMap<>(),       // eventHeaders
                    new DefaultExtendedState() // extendedState
            );
        }
    }
}