package vertx

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	config "final_assignment_backend_go/project/configs"
)

type Vertx struct {
	handler *config.NetWorkHandler
	stopCh  chan struct{}
}

func NewVertx(handler *config.NetWorkHandler) *Vertx {
	return &Vertx{
		handler: handler,
		stopCh:  make(chan struct{}),
	}
}

func (v *Vertx) Start() {
	log.Println("[Vertx] Starting instance...")
	go func() {
		v.handler.Start()
	}()
	log.Println("[Vertx] NetWorkHandler deployed successfully.")
}

func (v *Vertx) Shutdown() {
	log.Println("[Vertx] Shutting down Vertx instance...")
	_ = v.handler.Stop(context.Background())
	close(v.stopCh)
	log.Println("[Vertx] Vertx instance closed successfully.")
}

// Helper: 自动处理退出信号
func (v *Vertx) RunUntilInterrupt() {
	v.Start()
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	<-sigCh
	v.Shutdown()
}
