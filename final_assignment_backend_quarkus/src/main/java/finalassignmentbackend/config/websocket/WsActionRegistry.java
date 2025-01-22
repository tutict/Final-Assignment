package finalassignmentbackend.config.websocket;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Instance;
import jakarta.inject.Inject;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/**
 * WsActionRegistry:
 * 扫描带 @WsAction 的方法，并存储到 Map:  (serviceName + "#" + actionName) -> (beanInstance, method)
 */
@Slf4j
@ApplicationScoped
public class WsActionRegistry {

    private final Map<String, HandlerMethod> registry = new HashMap<>();

    @Inject
    Instance<Object> allBeans;

    @PostConstruct
    void init() {
        log.info("---- WsActionRegistry init start ----");

        // 遍历所有 CDI Bean
        for (Object bean : allBeans) {
            Class<?> beanClass = bean.getClass();
            Class<?> actualClass = getActualClass(beanClass);

            // 如果不想遍历全部, 你可以加判断:
            if (!actualClass.getPackageName().startsWith("finalassignmentbackend.service")) continue;

            for (Method m : actualClass.getMethods()) {
                WsAction anno = m.getAnnotation(WsAction.class);
                if (anno != null) {
                    // 取注解
                    String serviceName = anno.service();
                    String actionName = anno.action();
                    String key = serviceName + "#" + actionName;

                    HandlerMethod hm = new HandlerMethod(bean, m);
                    registry.put(key, hm);
                    log.info("注册WsAction: key={}, method={}.{}", key, actualClass.getSimpleName(), m.getName());
                }
            }
        }

        log.info("---- WsActionRegistry init end, total size={} ----", registry.size());
    }

    /**
     * 获取实际类(防止Quarkus生成的代理类)
     */
    private Class<?> getActualClass(Class<?> clazz) {
        // 如果是子类, 可能. 也可递归查superClass
        if (clazz.getName().contains("Subclass") && clazz.getSuperclass() != null) {
            return clazz.getSuperclass();
        }
        return clazz;
    }

    /**
     * 根据 (serviceName, actionName) 找到 Bean+Method
     */
    public HandlerMethod getHandler(String serviceName, String actionName) {
        return registry.get(serviceName + "#" + actionName);
    }

    // 包装类, 存储一个 bean 实例 + method
    @Getter
    public static class HandlerMethod {
        private final Object bean;
        private final Method method;

        public HandlerMethod(Object bean, Method method) {
            this.bean = bean;
            this.method = method;
        }

    }
}
