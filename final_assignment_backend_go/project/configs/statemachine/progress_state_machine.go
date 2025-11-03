package statemachine

import (
	"fmt"
)

// ProgressStateMachine 表示一个简单的状态机
type ProgressStateMachine struct {
	state ProgressState
}

// NewProgressStateMachine 创建一个新状态机，初始状态为 PENDING
func NewProgressStateMachine(initial ProgressState) *ProgressStateMachine {
	return &ProgressStateMachine{state: initial}
}

// State 获取当前状态
func (m *ProgressStateMachine) State() ProgressState {
	return m.state
}

// ApplyEvent 根据事件进行状态转移
func (m *ProgressStateMachine) ApplyEvent(event ProgressEvent) error {
	next, ok := transitions[m.state][event]
	if !ok {
		return fmt.Errorf("非法状态转移: %s -> (%s)", m.state, event)
	}
	fmt.Printf("✅ %s --(%s)--> %s\n", m.state, event, next)
	m.state = next
	return nil
}

// transitions 定义状态转移表
var transitions = map[ProgressState]map[ProgressEvent]ProgressState{
	StatePending: {
		EventStartProcessing: StateProcessing,
	},
	StateProcessing: {
		EventComplete: StateCompleted,
	},
	StateCompleted: {
		EventArchive: StateArchived,
	},
	StateArchived: {
		EventReopen: StatePending,
	},
}

// ---------------------------
// 模拟 Spring 的 Persist 行为
// ---------------------------

// Write 将当前状态写入实体（类似 Java 的 write）
func (m *ProgressStateMachine) Write(item *ProgressItem) {
	item.Status = string(m.state)
}

// Read 从实体中恢复状态机（类似 Java 的 read）
func (m *ProgressStateMachine) Read(item *ProgressItem) error {
	if item.Status == "" {
		m.state = StatePending
		return nil
	}
	switch ProgressState(item.Status) {
	case StatePending, StateProcessing, StateCompleted, StateArchived:
		m.state = ProgressState(item.Status)
	default:
		m.state = StatePending
	}
	return nil
}

// ---------------------------
// 工具函数
// ---------------------------

// HandleEvent 从实体中读取状态 → 执行事件 → 保存状态
func HandleEvent(item *ProgressItem, event ProgressEvent) error {
	machine := NewProgressStateMachine(StatePending)
	_ = machine.Read(item)
	if err := machine.ApplyEvent(event); err != nil {
		return err
	}
	machine.Write(item)
	return nil
}
