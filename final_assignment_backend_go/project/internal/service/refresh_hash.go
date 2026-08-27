package service

import (
	"crypto/sha256"
	"hash"
)

// newSHA256 returns a new SHA-256 hasher. Kept as a var for test substitution.
var newSHA256 = func() hash.Hash {
	return sha256.New()
}
