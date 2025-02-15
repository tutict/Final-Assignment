package com.tutict.finalassignmentbackend.config.websocket;

import lombok.Getter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/**
 * WsActionRegistry:
 * 扫描带 @WsAction 的方法，并存储到 Map:  (serviceName + "#" + actionName) -> (beanInstance, method)
 */
@Component
public class WsActionRegistry {

    private static final Logger log = LoggerFactory.getLogger(WsActionRegistry.class);

    private final Map<String, HandlerMethod> registry = new HashMap<>();

    private final ApplicationContext applicationContext;

    public WsActionRegistry(ApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    @PostConstruct
    void init() {
        log.info("---- WsActionRegistry init start ----");

        // 获取Spring容器中所有的Bean
        String[] beanNames = applicationContext.getBeanDefinitionNames();
        for (String beanName : beanNames) {
            Object bean = applicationContext.getBean(beanName);
            Class<?> beanClass = bean.getClass();
            Class<?> actualClass = getActualClass(beanClass);

            // 如果不想遍历全部, 你可以加判断:
            if (!actualClass.getPackageName().startsWith("finalassignmentbackend.service")) continue;

            for (Method m : actualClass.getMethods()) {
                WsAction anno = m.getAnnotation(WsAction.class);
                if (anno != null) {
                    // 获取注解
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
     * 获取实际类(防止Spring生成的代理类)
     */
    private Class<?> getActualClass(Class<?> clazz) {
        // 如果是代理类，获取实际类
        if (clazz.getName().contains("CGLIB")) {
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
