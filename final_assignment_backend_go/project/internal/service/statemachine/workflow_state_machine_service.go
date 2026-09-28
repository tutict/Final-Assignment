package statemachine

import (
	"errors"
	"final_assignment_backend_go/project/internal/reliability"
	"final_assignment_backend_go/project/internal/service/offense"
	paymentsvc "final_assignment_backend_go/project/internal/service/payment"
	"fmt"
	"strings"

	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// 违法记录处理状态（对齐 Spring OffenseProcessState 的 code 值）。
const (
	OffenseStateUnprocessed    = "Unprocessed"
	OffenseStateProcessing     = "Processing"
	OffenseStateProcessed      = "Processed"
	OffenseStateAppealing      = "Appealing"
	OffenseStateAppealApproved = "Appeal_Approved"
	OffenseStateAppealRejected = "Appeal_Rejected"
	OffenseStateCancelled      = "Cancelled"
)

// 支付状态（对齐 Spring PaymentState 的 code 值）。
const (
	PaymentStateUnpaid  = "Unpaid"
	PaymentStatePartial = "Partial"
	PaymentStatePaid    = "Paid"
	PaymentStateOverdue = "Overdue"
	PaymentStateWaived  = "Waived"
)

// 申诉处理状态（对齐 Spring AppealProcessState 的 code 值）。
const (
	AppealStateUnprocessed = "Unprocessed"
	AppealStateUnderReview = "Under_Review"
	AppealStateApproved    = "Approved"
	AppealStateRejected    = "Rejected"
	AppealStateWithdrawn   = "Withdrawn"
)

type stateTransition struct {
	from  string
	event string
	to    string
}

// 违法记录状态机（对齐 OffenseProcessStateMachineConfig）。
var offenseTransitions = []stateTransition{
	{OffenseStateUnprocessed, "START_PROCESSING", OffenseStateProcessing},
	{OffenseStateProcessing, "COMPLETE_PROCESSING", OffenseStateProcessed},
	{OffenseStateProcessed, "SUBMIT_APPEAL", OffenseStateAppealing},
	{OffenseStateAppealing, "APPROVE_APPEAL", OffenseStateAppealApproved},
	{OffenseStateAppealing, "REJECT_APPEAL", OffenseStateAppealRejected},
	{OffenseStateAppealing, "WITHDRAW_APPEAL", OffenseStateProcessed},
	{OffenseStateUnprocessed, "CANCEL", OffenseStateCancelled},
	{OffenseStateProcessing, "CANCEL", OffenseStateCancelled},
	{OffenseStateProcessed, "CANCEL", OffenseStateCancelled},
	{OffenseStateAppealing, "CANCEL", OffenseStateCancelled},
	{OffenseStateAppealApproved, "CANCEL", OffenseStateCancelled},
	{OffenseStateAppealRejected, "CANCEL", OffenseStateCancelled},
}

// 支付状态机（对齐 PaymentStateMachineConfig）。
var paymentTransitions = []stateTransition{
	{PaymentStateUnpaid, "PARTIAL_PAY", PaymentStatePartial},
	{PaymentStatePartial, "CONTINUE_PAYMENT", PaymentStatePaid},
	{PaymentStateUnpaid, "COMPLETE_PAYMENT", PaymentStatePaid},
	{PaymentStateUnpaid, "MARK_OVERDUE", PaymentStateOverdue},
	{PaymentStatePartial, "MARK_OVERDUE", PaymentStateOverdue},
	{PaymentStateOverdue, "COMPLETE_PAYMENT", PaymentStatePaid},
	{PaymentStateUnpaid, "WAIVE_FINE", PaymentStateWaived},
	{PaymentStatePartial, "WAIVE_FINE", PaymentStateWaived},
	{PaymentStateOverdue, "WAIVE_FINE", PaymentStateWaived},
	{PaymentStatePaid, "WAIVE_FINE", PaymentStateWaived},
}

// 申诉处理状态机（对齐 AppealProcessStateMachineConfig）。
var appealTransitions = []stateTransition{
	{AppealStateUnprocessed, "START_REVIEW", AppealStateUnderReview},
	{AppealStateUnderReview, "APPROVE", AppealStateApproved},
	{AppealStateUnderReview, "REJECT", AppealStateRejected},
	{AppealStateRejected, "REOPEN_REVIEW", AppealStateUnderReview},
	{AppealStateUnprocessed, "WITHDRAW", AppealStateWithdrawn},
	{AppealStateUnderReview, "WITHDRAW", AppealStateWithdrawn},
}

var (
	// ErrWorkflowTransitionRejected 表示状态机拒绝了该事件（HTTP 409 WORKFLOW_CONFLICT）。
	ErrWorkflowTransitionRejected = errors.New("workflow transition rejected")
	// ErrWorkflowRecordNotFound 表示工作流目标记录不存在（HTTP 404）。
	ErrWorkflowRecordNotFound = errors.New("workflow record not found")
)

// WorkflowService 提供基于状态机的业务流程控制，对齐 Spring 的
// com.tutict.finalassignmentbackend.service.statemachine.StateMachineService
// 与 WorkflowController 的组合行为。
type WorkflowService struct {
	db       *gorm.DB
	offenses *offense.OffenseInformationService
	payments *paymentsvc.PaymentRecordService
}

func NewWorkflowService(db *gorm.DB, offenses *offense.OffenseInformationService, payments *paymentsvc.PaymentRecordService) *WorkflowService {
	return &WorkflowService{db: db, offenses: offenses, payments: payments}
}

// transitionState 计算状态机的目标状态，事件被拒绝时返回当前状态。
func transitionState(transitions []stateTransition, current string, event string) (string, bool) {
	event = strings.ToUpper(strings.TrimSpace(event))
	for _, transition := range transitions {
		if transition.from == current && transition.event == event {
			return transition.to, true
		}
	}
	return current, false
}

// ResolveOffenseState 对齐 OffenseProcessState.fromCode，未知状态回退 Unprocessed。
func ResolveOffenseState(code string) string {
	code = strings.TrimSpace(code)
	if strings.EqualFold(code, "Pending") {
		return OffenseStateUnprocessed
	}
	for _, state := range []string{
		OffenseStateUnprocessed, OffenseStateProcessing, OffenseStateProcessed,
		OffenseStateAppealing, OffenseStateAppealApproved, OffenseStateAppealRejected,
		OffenseStateCancelled,
	} {
		if strings.EqualFold(code, state) {
			return state
		}
	}
	return OffenseStateUnprocessed
}

// ResolvePaymentState 对齐 PaymentState.fromCode，未知状态回退 Unpaid。
func ResolvePaymentState(code string) string {
	code = strings.TrimSpace(code)
	for _, state := range []string{PaymentStateUnpaid, PaymentStatePartial, PaymentStatePaid, PaymentStateOverdue, PaymentStateWaived} {
		if strings.EqualFold(code, state) {
			return state
		}
	}
	return PaymentStateUnpaid
}

// ResolveAppealState 对齐 AppealProcessState.fromCode，未知状态回退 Unprocessed。
func ResolveAppealState(code string) string {
	code = strings.TrimSpace(code)
	for _, state := range []string{AppealStateUnprocessed, AppealStateUnderReview, AppealStateApproved, AppealStateRejected, AppealStateWithdrawn} {
		if strings.EqualFold(code, state) {
			return state
		}
	}
	return AppealStateUnprocessed
}

// IsKnownOffenseEvent 校验事件是否属于违法处理状态机。
func IsKnownOffenseEvent(event string) bool {
	return knownEvent(offenseTransitions, event)
}

// IsKnownPaymentEvent 校验事件是否属于支付状态机。
func IsKnownPaymentEvent(event string) bool {
	return knownEvent(paymentTransitions, event)
}

// IsKnownAppealEvent 校验事件是否属于申诉处理状态机。
func IsKnownAppealEvent(event string) bool {
	return knownEvent(appealTransitions, event)
}

func knownEvent(transitions []stateTransition, event string) bool {
	event = strings.ToUpper(strings.TrimSpace(event))
	for _, transition := range transitions {
		if transition.event == event {
			return true
		}
	}
	return false
}

// TriggerOffenseEvent 触发违法记录状态事件并持久化新状态。
func (s *WorkflowService) TriggerOffenseEvent(offenseID int64, event string) (*domain.OffenseInformation, error) {
	offense, err := s.offenses.GetOffenseByID(int(offenseID))
	if err != nil {
		return nil, ErrWorkflowRecordNotFound
	}
	current := ResolveOffenseState(offense.ProcessStatus)
	next, ok := transitionState(offenseTransitions, current, event)
	if !ok {
		return nil, ErrWorkflowTransitionRejected
	}
	result := s.db.Model(&domain.OffenseInformation{}).
		Where("offense_id = ?", offenseID).
		Update("process_status", next)
	if result.Error != nil {
		return nil, result.Error
	}
	offense.ProcessStatus = next
	return offense, nil
}

// TriggerPaymentEvent 触发支付状态事件并按乐观锁持久化新状态。
func (s *WorkflowService) TriggerPaymentEvent(paymentID int64, event string, idempotencyKey string) (*domain.PaymentRecord, error) {
	db := reliability.Ledger(s.db)
	var payment domain.PaymentRecord
	if err := db.Where("payment_id = ?", paymentID).First(&payment).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrWorkflowRecordNotFound
		}
		return nil, err
	}
	fingerprint := reliability.Fingerprint(fmt.Sprintf("%d|%s", paymentID, event))
	if err := reliability.Reserve(db, idempotencyKey, "PAYMENT_STATUS", "POST", fmt.Sprintf("/api/workflow/payments/%d/events/%s", paymentID, event), fingerprint, &paymentID); err != nil {
		return nil, err
	}
	current := ResolvePaymentState(payment.PaymentStatus)
	next, ok := transitionState(paymentTransitions, current, event)
	if !ok {
		_ = reliability.MarkFailed(db, idempotencyKey, ErrWorkflowTransitionRejected.Error())
		return nil, ErrWorkflowTransitionRejected
	}
	if err := s.payments.UpdatePaymentStatusFields(paymentID, next); err != nil {
		_ = reliability.MarkFailed(db, idempotencyKey, err.Error())
		return nil, err
	}
	if err := reliability.MarkSuccess(db, idempotencyKey, paymentID); err != nil {
		return nil, err
	}
	payment.PaymentStatus = next
	return &payment, nil
}

// TriggerAppealEvent 触发申诉状态事件并持久化新状态。
func (s *WorkflowService) TriggerAppealEvent(appealID int64, event string, idempotencyKey string) (*domain.AppealManagement, error) {
	db := reliability.Ledger(s.db)
	var appeal domain.AppealManagement
	if err := db.Where("appeal_id = ?", appealID).First(&appeal).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrWorkflowRecordNotFound
		}
		return nil, err
	}
	fingerprint := reliability.Fingerprint(fmt.Sprintf("%d|%s", appealID, event))
	if err := reliability.Reserve(db, idempotencyKey, "APPEAL_STATUS", "POST", fmt.Sprintf("/api/workflow/appeals/%d/events/%s", appealID, event), fingerprint, &appealID); err != nil {
		return nil, err
	}
	current := ResolveAppealState(appeal.ProcessStatus)
	next, ok := transitionState(appealTransitions, current, event)
	if !ok {
		_ = reliability.MarkFailed(db, idempotencyKey, ErrWorkflowTransitionRejected.Error())
		return nil, ErrWorkflowTransitionRejected
	}
	result := db.Model(&domain.AppealManagement{}).
		Where("appeal_id = ?", appealID).
		Update("process_status", next)
	if result.Error != nil {
		_ = reliability.MarkFailed(db, idempotencyKey, result.Error.Error())
		return nil, result.Error
	}
	if err := reliability.MarkSuccess(db, idempotencyKey, appealID); err != nil {
		return nil, err
	}
	appeal.ProcessStatus = next
	return &appeal, nil
}
