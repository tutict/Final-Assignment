package domain

import "time"

// AppealReview maps traffic.appeal_review. It is the appeal decision row.
type AppealReview struct {
	ReviewID             int        `gorm:"column:review_id;primaryKey;autoIncrement" json:"reviewId"`
	AppealID             int        `gorm:"column:appeal_id" json:"appealId"`
	ReviewLevel          string     `gorm:"column:review_level" json:"reviewLevel"`
	ReviewTime           time.Time  `gorm:"column:review_time" json:"reviewTime"`
	Reviewer             string     `gorm:"column:reviewer" json:"reviewer"`
	ReviewerDept         string     `gorm:"column:reviewer_dept" json:"reviewerDept"`
	ReviewResult         string     `gorm:"column:review_result" json:"reviewResult"`
	ReviewOpinion        string     `gorm:"column:review_opinion" json:"reviewOpinion"`
	SuggestedAction      string     `gorm:"column:suggested_action" json:"suggestedAction"`
	SuggestedFineAmount  float64    `gorm:"column:suggested_fine_amount" json:"suggestedFineAmount"`
	SuggestedPoints      int        `gorm:"column:suggested_points" json:"suggestedPoints"`
	CreatedAt            *time.Time `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt            *time.Time `gorm:"column:updated_at" json:"updatedAt"`
	Remarks              string     `gorm:"column:remarks" json:"remarks"`
}

func (AppealReview) TableName() string { return "appeal_review" }
