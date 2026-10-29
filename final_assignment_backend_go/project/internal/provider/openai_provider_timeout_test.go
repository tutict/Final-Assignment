package provider

import (
	"net/http"
	"testing"
	"time"
)

func TestProviderTimeoutBudgets(t *testing.T) {
	defaults := NewOpenAIProvider("", "http://127.0.0.1:9", "m", 0)
	transport, ok := defaults.client.Transport.(*http.Transport)
	if !ok {
		t.Fatal("transport type")
	}
	if transport.ResponseHeaderTimeout != defaultProviderTimeout {
		t.Fatalf("default header timeout = %s", transport.ResponseHeaderTimeout)
	}

	custom := NewOpenAIProvider("", "http://127.0.0.1:9", "m", 5*time.Second)
	customTransport, ok := custom.client.Transport.(*http.Transport)
	if !ok {
		t.Fatal("transport type")
	}
	if customTransport.ResponseHeaderTimeout != 5*time.Second {
		t.Fatalf("header timeout = %s", customTransport.ResponseHeaderTimeout)
	}
	if customTransport.DialContext == nil {
		t.Fatal("dial timeout not configured")
	}
	if custom.client.Timeout != 10*time.Second {
		t.Fatalf("exchange timeout = %s", custom.client.Timeout)
	}
}
