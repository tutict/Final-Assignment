package com.tutict.finalassignmentcloud.auth.config.websocket;

import com.tutict.finalassignmentcloud.config.websocket.WsAction;

import lombok.Getter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;


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

    private static final String SCANNED_PACKAGE = "com.tutict.finalassignmentcloud.auth.service";

    private volatile Map<String, HandlerMethod> registry;

    private final ApplicationContext applicationContext;

    public WsActionRegistry(ApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    /**
     * 扫描带 @WsAction 的方法，并存储到 Map:  (serviceName + "#" + actionName) -> (beanInstance, method)
     * 索引在首次查询时构建：在 @PostConstruct 阶段遍历容器会提前实例化全部单例，
     * 并在自身仍在创建时抛 BeanCurrentlyInCreationException。
     */
    private Map<String, HandlerMethod> scan() {
        log.info("---- WsActionRegistry scan start ----");
        Map<String, HandlerMethod> scanned = new HashMap<>();
        for (String beanName : applicationContext.getBeanDefinitionNames()) {
            Object bean = applicationContext.getBean(beanName);
            Class<?> beanClass = bean.getClass();
            Class<?> actualClass = getActualClass(beanClass);

            // 如果不想遍历全部, 你可以加判断:
            if (!actualClass.getPackageName().startsWith(SCANNED_PACKAGE)) continue;

            for (Method m : actualClass.getMethods()) {
                WsAction anno = m.getAnnotation(WsAction.class);
                if (anno != null) {
                    // 获取注解
                    String serviceName = anno.service();
                    String actionName = anno.action();
                    String key = serviceName + "#" + actionName;

                    HandlerMethod hm = new HandlerMethod(bean, m);
                    scanned.put(key, hm);
                    log.info("注册WsAction: key={}, method={}.{}", key, actualClass.getSimpleName(), m.getName());
                }
            }
        }
        log.info("---- WsActionRegistry scan end, total size={} ----", scanned.size());
        return scanned;
    }

    private Map<String, HandlerMethod> registry() {
        Map<String, HandlerMethod> current = registry;
        if (current == null) {
            synchronized (this) {
                current = registry;
                if (current == null) {
                    current = scan();
                    registry = current;
                }
            }
        }
        return current;
    }

    /**
     * 获取实际类（防止 Spring 生成的代理类）
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
        return registry().get(serviceName + "#" + actionName);
    }

    // 包装类，存储一份 bean 实例 + method
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



