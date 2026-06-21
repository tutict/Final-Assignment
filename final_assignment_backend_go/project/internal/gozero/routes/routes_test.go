package routes

import (
	"testing"

	"github.com/zeromicro/go-zero/rest"
)

func TestRegisterDoesNotPanic(t *testing.T) {
	server := rest.MustNewServer(rest.RestConf{
		Host: "127.0.0.1",
		Port: 18081,
	})
	defer server.Stop()

	Register(server)
}
