package vertx

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"final_assignment_front_go/project/configs"
)

type Vertx struct {
	handler *NetWorkHandler
	stopCh  chan struct{}
}

func NewVertx(handler *NetWorkHandler) *Vertx {
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
	v.handler.Stop()
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
