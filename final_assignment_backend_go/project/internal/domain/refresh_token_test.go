package domain

import (
	"sync"
	"testing"

	"gorm.io/gorm/schema"
)

func TestRefreshTokenLookupDigestUsesBoundedMysqlIndexColumn(t *testing.T) {
	parsed, err := schema.Parse(&RefreshToken{}, &sync.Map{}, schema.NamingStrategy{})
	if err != nil {
		t.Fatalf("parse refresh token schema: %v", err)
	}

	field := parsed.LookUpField("LookupDigest")
	if field == nil {
		t.Fatal("LookupDigest field not found")
	}
	if field.Size != 64 {
		t.Fatalf("LookupDigest size = %d, want 64", field.Size)
	}
}
