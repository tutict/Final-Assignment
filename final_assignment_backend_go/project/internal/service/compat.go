package service

import "errors"

var ErrNotFound = errors.New("not found")

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type RegisterRequest struct {
	Username      string `json:"username"`
	Password      string `json:"password"`
	ContactNumber string `json:"contact_number"`
	Email         string `json:"email"`
}
