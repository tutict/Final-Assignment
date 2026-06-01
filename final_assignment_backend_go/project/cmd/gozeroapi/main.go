package main

import (
	"flag"
	"fmt"
	"log"

	"final_assignment_backend_go/project/internal/gozero/config"
	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	gozeroroutes "final_assignment_backend_go/project/internal/gozero/routes"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "project/etc/gozero-api.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)

	ragRuntime, err := gozerorag.NewRuntime(c.Rag)
	if err != nil {
		log.Fatalf("failed to initialize RAG runtime: %v", err)
	}
	defer ragRuntime.Close()

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	gozeroroutes.Register(server, gozeroroutes.WithRAGRuntime(ragRuntime))

	fmt.Printf("Starting go-zero REST server at %s:%d...\n", c.Host, c.Port)
	server.Start()
}
