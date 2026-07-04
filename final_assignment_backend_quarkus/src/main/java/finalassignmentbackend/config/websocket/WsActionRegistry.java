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
 * Scans @WsAction methods and stores them as (serviceName + "#" + actionName) -> handler.
 */
@Slf4j
@ApplicationScoped
public class WsActionRegistry {

    private static final String BASE_PACKAGE = "finalassignmentbackend.service";

    private final Map<String, HandlerMethod> registry = new HashMap<>();

    @Inject
    Instance<Object> allBeans;

    @PostConstruct
    void init() {
        log.info("---- WsActionRegistry init start ----");

        for (Object bean : allBeans) {
            Class<?> beanClass = bean.getClass();
            Class<?> actualClass = getActualClass(beanClass);
            if (!actualClass.getPackageName().startsWith(BASE_PACKAGE)) {
                continue;
            }

            for (Method method : actualClass.getMethods()) {
                WsAction action = method.getAnnotation(WsAction.class);
                if (action == null) {
                    continue;
                }
                String key = action.service() + "#" + action.action();
                registry.put(key, new HandlerMethod(bean, method, action));
                log.info("Registered WsAction: key={}, method={}.{}", key, actualClass.getSimpleName(), method.getName());
            }
        }

        if (registry.isEmpty()) {
            throw new IllegalStateException("WsActionRegistry is EMPTY! Check BASE_PACKAGE: " + BASE_PACKAGE);
        }
        log.info("---- WsActionRegistry init end, total size={} ----", registry.size());
    }

    private Class<?> getActualClass(Class<?> clazz) {
        if (clazz.getName().contains("Subclass") && clazz.getSuperclass() != null) {
            return clazz.getSuperclass();
        }
        return clazz;
    }

    public HandlerMethod getHandler(String serviceName, String actionName) {
        return registry.get(serviceName + "#" + actionName);
    }

    @Getter
    public static class HandlerMethod {
        private final Object bean;
        private final Method method;
        private final WsAction wsAction;

        public HandlerMethod(Object bean, Method method, WsAction wsAction) {
            this.bean = bean;
            this.method = method;
            this.wsAction = wsAction;
        }
    }
}