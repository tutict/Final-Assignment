package com.tutict.finalassignmentbackend.config.websocket;

import lombok.Getter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/**
 * Scans @WsAction methods and stores them as (serviceName + "#" + actionName) -> handler.
 */
@Component
public class WsActionRegistry {

    private static final Logger log = LoggerFactory.getLogger(WsActionRegistry.class);
    private static final String BASE_PACKAGE = "com.tutict.finalassignmentbackend.service";

    private final Map<String, HandlerMethod> registry = new HashMap<>();

    private final ApplicationContext applicationContext;

    public WsActionRegistry(ApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    @PostConstruct
    public void init() {
        log.info("---- WsActionRegistry init start ----");

        String[] beanNames = applicationContext.getBeanDefinitionNames();
        for (String beanName : beanNames) {
            Class<?> beanClass = applicationContext.getType(beanName);
            if (beanClass == null) {
                continue;
            }
            Class<?> actualClass = getActualClass(beanClass);

            if (!actualClass.getPackageName().startsWith(BASE_PACKAGE)) continue;

            Object bean;
            try {
                bean = applicationContext.getBean(beanName);
            } catch (BeansException ex) {
                log.debug("Skip WsAction scan for bean {} because it cannot be initialized yet", beanName, ex);
                continue;
            }

            for (Method m : actualClass.getMethods()) {
                WsAction anno = m.getAnnotation(WsAction.class);
                if (anno != null) {
                    String serviceName = anno.service();
                    String actionName = anno.action();
                    String key = serviceName + "#" + actionName;

                    HandlerMethod hm = new HandlerMethod(bean, m, anno);
                    registry.put(key, hm);
                    log.info("Registered WsAction: key={}, method={}.{}", key, actualClass.getSimpleName(), m.getName());
                }
            }
        }

        if (registry.isEmpty()) {
            throw new IllegalStateException(
                    "WsActionRegistry is EMPTY! Check BASE_PACKAGE: " + BASE_PACKAGE);
        }
        log.info("WsActionRegistry: {} actions registered", registry.size());
        registry.keySet().forEach(k -> log.debug("  Registered action: {}", k));
        log.info("---- WsActionRegistry init end, total size={} ----", registry.size());
    }

    private Class<?> getActualClass(Class<?> clazz) {
        if (clazz.getName().contains("CGLIB")) {
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