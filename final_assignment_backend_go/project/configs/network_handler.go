package config

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"

	"final_assignment_front_go/project/configs/websocket_settings"
)

// NetWorkHandler 实现网络层功能（HTTP 反向代理 + WebSocket RPC）
type NetWorkHandler struct {
	Port          int
	BackendHost   string // host without scheme, e.g. "localhost"
	BackendPort   int
	TokenProvider *TokenProvider
	WsRegistry    *WsActionRegistry
	ObjectMapper  *json.Encoder // not strictly necessary, kept for parity
	server        *http.Server
	upgrader      websocket.Upgrader
	startOnce     sync.Once
	stopOnce      sync.Once
}

// NewNetWorkHandler 构造函数
func NewNetWorkHandler(port int, backendHost string, backendPort int, tp *TokenProvider, ws *WsActionRegistry) *NetWorkHandler {
	return &NetWorkHandler{
		Port:          port,
		BackendHost:   backendHost,
		BackendPort:   backendPort,
		TokenProvider: tp,
		WsRegistry:    ws,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024 * 4,
			WriteBufferSize: 1024 * 4,
			CheckOrigin: func(r *http.Request) bool {
				// 允许所有 origin（可根据需求收紧）
				return true
			},
		},
	}
}

// Start 启动 Gin 服务（非阻塞）
func (n *NetWorkHandler) Start() error {
	var startErr error
	n.startOnce.Do(func() {
		gin.SetMode(gin.ReleaseMode)
		router := gin.New()
		router.Use(gin.Logger(), gin.Recovery(), n.corsMiddleware())

		// HTTP proxy route
		router.Any("/api/*any", func(c *gin.Context) {
			n.forwardHTTP(c)
		})

		// WebSocket route (GET)
		router.GET("/eventbus/*any", func(c *gin.Context) {
			n.handleWebSocket(c)
		})

		// 404 for other paths (similar to Java's regex route)
		router.NoRoute(func(c *gin.Context) {
			path := c.Request.URL.Path
			if strings.HasPrefix(path, "/api/") || strings.HasPrefix(path, "/eventbus/") {
				c.Status(http.StatusNotFound)
			} else {
				c.String(http.StatusNotFound, "未找到资源")
			}
		})

		addr := ":" + strconv.Itoa(n.Port)
		n.server = &http.Server{
			Addr:    addr,
			Handler: router,
		}

		// run server in goroutine
		go func() {
			log.Printf("[NetWorkHandler] starting server at %s", addr)
			if err := n.server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
				log.Printf("[NetWorkHandler] server error: %v", err)
				startErr = err
			}
		}()

		// small wait to ensure server started (non-blocking)
		time.Sleep(50 * time.Millisecond)
	})
	return startErr
}

// Stop 优雅关闭
func (n *NetWorkHandler) Stop(ctx context.Context) error {
	var err error
	n.stopOnce.Do(func() {
		if n.server == nil {
			return
		}
		log.Println("[NetWorkHandler] shutting down server...")
		err = n.server.Shutdown(ctx)
	})
	return err
}

// -------------------- CORS --------------------

func (n *NetWorkHandler) corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Headers", "Authorization, X-Requested-With, Sec-WebSocket-Key, Sec-WebSocket-Version, Sec-WebSocket-Protocol, Content-Type, Accept")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

// -------------------- HTTP Forwarding (Reverse Proxy) --------------------

func (n *NetWorkHandler) backendURL() *url.URL {
	u := &url.URL{
		Scheme: "http",
		Host:   net.JoinHostPort(n.BackendHost, strconv.Itoa(n.BackendPort)),
	}
	return u
}

func (n *NetWorkHandler) forwardHTTP(c *gin.Context) {
	requestID := fmt.Sprintf("%d", time.Now().UnixNano())
	// prevent circular forward
	if c.GetHeader("X-Forwarded-By") != "" {
		log.Printf("[%s] detected circular forwarding, aborting", requestID)
		c.String(http.StatusInternalServerError, "Circular forwarding detected")
		return
	}

	proxy := httputil.NewSingleHostReverseProxy(n.backendURL())
	// customize director to preserve original path and query
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req) // sets scheme/host/path/query
		// ensure original request path (Gin sets RequestURI)
		req.URL.Path = c.Request.URL.Path
		req.URL.RawQuery = c.Request.URL.RawQuery
		// copy headers from incoming request
		for k := range c.Request.Header {
			req.Header.Set(k, c.Request.Header.Get(k))
		}
		req.Header.Set("X-Forwarded-By", "NetWorkHandler")
	}

	proxy.ModifyResponse = func(resp *http.Response) error {
		// allow direct passthrough of headers and body, but log some info
		log.Printf("[%s] proxied response status: %d", requestID, resp.StatusCode)
		return nil
	}

	proxy.ErrorHandler = func(rw http.ResponseWriter, req *http.Request, err error) {
		log.Printf("[%s] proxy error: %v", requestID, err)
		rw.WriteHeader(http.StatusBadGateway)
		_, _ = rw.Write([]byte(`{"error":"forwarding failed"}`))
	}

	// Forward
	proxy.ServeHTTP(c.Writer, c.Request)
}

// -------------------- WebSocket --------------------

type wsMessageIn struct {
	Token          string            `json:"token"`
	Service        string            `json:"service"`
	Action         string            `json:"action"`
	IdempotencyKey string            `json:"idempotencyKey"`
	Args           []json.RawMessage `json:"args"`
	// allow arbitrary additional fields if needed
}

func (n *NetWorkHandler) handleWebSocket(c *gin.Context) {
	// upgrade
	conn, err := n.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("[WS] upgrade failed: %v", err)
		return
	}
	defer func() {
		_ = conn.Close()
	}()

	path := c.Request.URL.Path
	log.Printf("[WS] connection established, path=%s", path)

	// read loop
	for {
		msgType, msg, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseGoingAway) {
				log.Printf("[WS] normal close: %v", err)
			} else {
				log.Printf("[WS] read error: %v", err)
			}
			break
		}
		if msgType != websocket.TextMessage {
			log.Printf("[WS] unsupported frame type: %d", msgType)
			continue
		}

		// handle message in goroutine so a slow handler cannot block other reads
		go n.handleWsMessage(conn, msg)
	}
	log.Printf("[WS] connection closed, path=%s", path)
}

func (n *NetWorkHandler) handleWsMessage(conn *websocket.Conn, raw []byte) {
	requestID := fmt.Sprintf("%d", time.Now().UnixNano())
	log.Printf("[%s] ws message received: %s", requestID, string(raw))

	var in wsMessageIn
	if err := json.Unmarshal(raw, &in); err != nil {
		log.Printf("[%s] json parse error: %v", requestID, err)
		_ = conn.WriteJSON(map[string]string{"error": "Invalid JSON"})
		return
	}

	// token check
	if in.Token == "" || !n.TokenProvider.ValidateToken(in.Token) {
		log.Printf("[%s] invalid token, closing ws", requestID)
		_ = conn.WriteJSON(map[string]string{"error": "Invalid token"})
		_ = conn.WriteControl(websocket.CloseMessage, websocket.FormatCloseMessage(1008, "Invalid token"), time.Now().Add(time.Second))
		_ = conn.Close()
		return
	}

	service := in.Service
	action := in.Action
	if service == "" || action == "" {
		_ = conn.WriteJSON(map[string]string{"error": "Missing service or action"})
		return
	}

	handler := n.WsRegistry.GetHandler(service, action)
	if handler == nil {
		_ = conn.WriteJSON(map[string]string{"error": fmt.Sprintf("No such WsAction for %s#%s", service, action)})
		return
	}

	method := handler.Method
	bean := handler.Bean
	methodType := method.Type()
	paramCount := methodType.NumIn()
	if len(in.Args) != paramCount {
		_ = conn.WriteJSON(map[string]string{"error": fmt.Sprintf("Param mismatch, method expects %d but got %d", paramCount, len(in.Args))})
		return
	}

	// convert args
	invokeArgs := make([]reflect.Value, paramCount)
	for i := 0; i < paramCount; i++ {
		targetType := methodType.In(i)
		argRaw := in.Args[i]
		val, convErr := convertJSONToReflectValue(argRaw, targetType)
		if convErr != nil {
			log.Printf("[%s] arg conversion failed: %v", requestID, convErr)
			_ = conn.WriteJSON(map[string]string{"error": fmt.Sprintf("Arg %d conversion error: %v", i, convErr)})
			return
		}
		invokeArgs[i] = val
	}

	// call
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[%s] panic during handler invocation: %v", requestID, r)
			_ = conn.WriteJSON(map[string]string{"error": "internal server error"})
		}
	}()

	results := method.Call(invokeArgs)

	// handle return values:
	// common patterns:
	// - single return value -> return it as result
	// - (value, error) -> if error != nil then return error, else return value
	// - only error -> return error if non-nil else status OK
	var resp interface{}
	if len(results) == 0 {
		resp = map[string]string{"status": "OK"}
	} else if len(results) == 1 {
		// single return
		rv := results[0].Interface()
		// if it's error
		if errObj, ok := rv.(error); ok && errObj != nil {
			resp = map[string]string{"error": errObj.Error()}
		} else {
			resp = map[string]interface{}{"result": rv}
		}
	} else if len(results) == 2 {
		// assume (value, error) or (error, value) - we assume common (value, error)
		val := results[0].Interface()
		errVal, _ := results[1].Interface().(error)
		if errVal != nil {
			resp = map[string]string{"error": errVal.Error()}
		} else {
			resp = map[string]interface{}{"result": val}
		}
	} else {
		// multiple return values: convert to slice
		arr := make([]interface{}, len(results))
		for i, r := range results {
			arr[i] = r.Interface()
		}
		resp = map[string]interface{}{"result": arr}
	}

	// write response
	if err := conn.WriteJSON(resp); err != nil {
		log.Printf("[%s] failed to write ws response: %v", requestID, err)
	}
}

// convertJSONToReflectValue 将 json.RawMessage 转换为目标 reflect.Value（非地址able）
func convertJSONToReflectValue(raw json.RawMessage, targetType reflect.Type) (reflect.Value, error) {
	// If the target is an interface{}, pass-through to map[string]interface{} or []interface{}
	if targetType.Kind() == reflect.Interface {
		var v interface{}
		if err := json.Unmarshal(raw, &v); err != nil {
			return reflect.Value{}, err
		}
		return reflect.ValueOf(v), nil
	}

	// For pointer types: allocate new element
	isPtr := false
	if targetType.Kind() == reflect.Ptr {
		isPtr = true
		targetType = targetType.Elem()
	}

	// Create a new value of the target type
	newVal := reflect.New(targetType) // *T
	// Attempt direct unmarshalling into this value
	if err := json.Unmarshal(raw, newVal.Interface()); err == nil {
		if isPtr {
			return newVal, nil // already a pointer *T
		}
		return newVal.Elem(), nil // T
	}

	// If direct unmarshal failed, try some primitive conversions manually
	text := strings.TrimSpace(string(raw))
	switch targetType.Kind() {
	case reflect.String:
		// remove quotes if any
		var s string
		if err := json.Unmarshal(raw, &s); err == nil {
			if isPtr {
				return reflect.ValueOf(&s), nil
			}
			return reflect.ValueOf(s), nil
		}
		// fallback raw
		if isPtr {
			return reflect.ValueOf(&text), nil
		}
		return reflect.ValueOf(text), nil
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		var n int64
		if err := json.Unmarshal(raw, &n); err == nil {
			v := reflect.New(targetType).Elem()
			v.SetInt(n)
			if isPtr {
				ptr := reflect.New(targetType)
				ptr.Elem().SetInt(n)
				return ptr, nil
			}
			return v, nil
		}
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		var n uint64
		if err := json.Unmarshal(raw, &n); err == nil {
			v := reflect.New(targetType).Elem()
			v.SetUint(n)
			if isPtr {
				ptr := reflect.New(targetType)
				ptr.Elem().SetUint(n)
				return ptr, nil
			}
			return v, nil
		}
	case reflect.Float32, reflect.Float64:
		var f float64
		if err := json.Unmarshal(raw, &f); err == nil {
			v := reflect.New(targetType).Elem()
			v.SetFloat(f)
			if isPtr {
				ptr := reflect.New(targetType)
				ptr.Elem().SetFloat(f)
				return ptr, nil
			}
			return v, nil
		}
	case reflect.Bool:
		var b bool
		if err := json.Unmarshal(raw, &b); err == nil {
			if isPtr {
				ptr := reflect.New(targetType)
				ptr.Elem().SetBool(b)
				return ptr, nil
			}
			return reflect.ValueOf(b), nil
		}
	case reflect.Slice, reflect.Map, reflect.Struct:
		// Already tried direct unmarshal above; if failed, return error
		return reflect.Value{}, fmt.Errorf("failed to unmarshal into %s", targetType.String())
	}

	return reflect.Value{}, fmt.Errorf("unsupported target type: %s (raw: %s)", targetType.String(), string(raw))
}
