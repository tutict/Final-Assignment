package provider

import (
	"net/http"
	"testing"
	"time"
)

func TestModelResponseHeadersFailWithinOneSecond(t *testing.T) {
	client := NewOpenAIProvider("", "http://127.0.0.1:9", "m").client
	transport, ok := client.Transport.(*http.Transport)
	if !ok {
		t.Fatal("transport type")
	}
	if transport.ResponseHeaderTimeout != 700*time.Millisecond {
		t.Fatalf("header timeout = %s", transport.ResponseHeaderTimeout)
	}
}
