package agent

import (
	"sync"
	"time"
)

type Draft struct {
	DraftID     string         `json:"draftId"`
	UserID      string         `json:"userId"`
	SessionKey  string         `json:"sessionKey"`
	ToolName    string         `json:"toolName"`
	ServiceName string         `json:"serviceName"`
	Risk        string         `json:"risk"`
	Summary     string         `json:"summary"`
	Preview     map[string]any `json:"preview"`
	Payload     map[string]any `json:"payload"`
	CreatedAt   time.Time      `json:"createdAt"`
	ExpiresAt   time.Time      `json:"expiresAt"`
}

type DraftStore struct {
	mu            sync.Mutex
	drafts        map[string]Draft
	sessionDrafts map[string]string
	sessionOwners map[string]string
}

func NewDraftStore() *DraftStore {
	return &DraftStore{
		drafts:        map[string]Draft{},
		sessionDrafts: map[string]string{},
		sessionOwners: map[string]string{},
	}
}

func (s *DraftStore) Save(draft Draft) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.drafts[draft.DraftID] = draft
	if draft.SessionKey != "" {
		s.sessionOwners[draft.SessionKey] = draft.UserID
		s.sessionDrafts[draft.UserID+":"+draft.SessionKey] = draft.DraftID
		s.sessionDrafts[draft.SessionKey] = draft.DraftID
	}
}

func (s *DraftStore) Find(draftID string) (Draft, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	draft, ok := s.drafts[draftID]
	if !ok {
		return Draft{}, false
	}
	if !draft.ExpiresAt.IsZero() && draft.ExpiresAt.Before(time.Now()) {
		delete(s.drafts, draftID)
		return Draft{}, false
	}
	return draft, true
}

func (s *DraftStore) Delete(draftID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.drafts, draftID)
}

func (s *DraftStore) BindSession(userID, sessionKey string) bool {
	if sessionKey == "" {
		return true
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if userID == "" {
		userID = "anonymous"
	}
	existing, ok := s.sessionOwners[sessionKey]
	if ok && existing != userID {
		return false
	}
	s.sessionOwners[sessionKey] = userID
	return true
}

func (s *DraftStore) LastDraftID(userID, sessionKey string) (string, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if sessionKey == "" {
		return "", false
	}
	if userID != "" {
		if id, ok := s.sessionDrafts[userID+":"+sessionKey]; ok && id != "" {
			return id, true
		}
	}
	id, ok := s.sessionDrafts[sessionKey]
	return id, ok && id != ""
}
