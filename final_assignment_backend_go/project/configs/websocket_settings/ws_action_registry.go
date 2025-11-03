package websocket_settings

import (
	"fmt"
	"log"
	"reflect"
	"strings"
	"sync"
)

// HandlerMethod 保存服务实例与其方法引用
type HandlerMethod struct {
	Bean   interface{}
	Method reflect.Method
}

// WsActionRegistry 存储所有 service#action -> HandlerMethod 的映射
type WsActionRegistry struct {
	mu       sync.RWMutex
	registry map[string]HandlerMethod
}

// GlobalWsRegistry 全局单例（类似 Spring 的 Bean）
var GlobalWsRegistry = NewWsActionRegistry()

// NewWsActionRegistry 创建新的注册表
func NewWsActionRegistry() *WsActionRegistry {
	return &WsActionRegistry{
		registry: make(map[string]HandlerMethod),
	}
}

// RegisterService 自动扫描并注册 service 中的方法
func (r *WsActionRegistry) RegisterService(serviceName string, service interface{}) {
	r.mu.Lock()
	defer r.mu.Unlock()

	serviceType := reflect.TypeOf(service)
	serviceValue := reflect.ValueOf(service)

	// 如果传的是指针，则获取其底层类型
	if serviceType.Kind() == reflect.Ptr {
		serviceType = serviceType.Elem()
	}

	// 扫描方法
	for i := 0; i < serviceType.NumMethod(); i++ {
		method := serviceType.Method(i)
		// 我们用方法的 tag 或命名约定进行匹配
		// 比如方法名为 "Action_XXX"，则 Action 后面的部分为 action 名称
		if strings.HasPrefix(method.Name, "Action_") {
			action := strings.TrimPrefix(method.Name, "Action_")
			key := fmt.Sprintf("%s#%s", serviceName, action)

			r.registry[key] = HandlerMethod{
				Bean:   serviceValue.Interface(),
				Method: method,
			}
			log.Printf("[WsRegistry] Registered %s -> %s.%s", key, serviceType.Name(), method.Name)
		}
	}
}

// GetHandler 获取 service + action 对应的 HandlerMethod
func (r *WsActionRegistry) GetHandler(serviceName, actionName string) (HandlerMethod, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	hm, ok := r.registry[fmt.Sprintf("%s#%s", serviceName, actionName)]
	return hm, ok
}

// CallHandler 调用注册的方法（自动传入参数）
func (r *WsActionRegistry) CallHandler(serviceName, actionName string, args ...interface{}) ([]reflect.Value, error) {
	hm, ok := r.GetHandler(serviceName, actionName)
	if !ok {
		return nil, fmt.Errorf("handler not found: %s#%s", serviceName, actionName)
	}

	method := hm.Method
	in := make([]reflect.Value, len(args)+1)
	in[0] = reflect.ValueOf(hm.Bean)
	for i, arg := range args {
		in[i+1] = reflect.ValueOf(arg)
	}

	return method.Func.Call(in), nil
}
