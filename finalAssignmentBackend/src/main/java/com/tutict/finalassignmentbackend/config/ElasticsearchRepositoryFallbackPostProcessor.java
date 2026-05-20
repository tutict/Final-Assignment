package com.tutict.finalassignmentbackend.config;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.core.Ordered;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.UncategorizedElasticsearchException;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.SearchHitsImpl;
import org.springframework.data.elasticsearch.core.TotalHitsRelation;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Component;
import org.springframework.util.ClassUtils;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.time.Duration;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
@Profile("dev")
@ConditionalOnProperty(name = "app.elasticsearch.fallback.enabled", havingValue = "true", matchIfMissing = true)
public class ElasticsearchRepositoryFallbackPostProcessor implements BeanPostProcessor, Ordered {

    private static final Logger LOG = Logger.getLogger(ElasticsearchRepositoryFallbackPostProcessor.class.getName());
    private final Set<String> loggedFallbacks = ConcurrentHashMap.newKeySet();

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        if (!(bean instanceof ElasticsearchRepository<?, ?>)) {
            return bean;
        }

        Class<?>[] interfaces = ClassUtils.getAllInterfacesForClass(bean.getClass(), bean.getClass().getClassLoader());
        if (interfaces.length == 0) {
            return bean;
        }

        InvocationHandler handler = (proxy, method, args) -> invokeWithFallback(beanName, bean, method, args);
        return Proxy.newProxyInstance(bean.getClass().getClassLoader(), interfaces, handler);
    }

    private Object invokeWithFallback(String beanName, Object target, Method method, Object[] args) throws Throwable {
        try {
            return method.invoke(target, args);
        } catch (InvocationTargetException ex) {
            Throwable targetException = ex.getTargetException();
            if (isElasticsearchFailure(targetException)) {
                logFallback(beanName, method, targetException);
                return fallbackValue(method, args);
            }
            throw targetException;
        }
    }

    private boolean isElasticsearchFailure(Throwable throwable) {
        Throwable current = throwable;
        while (current != null) {
            if (current instanceof UncategorizedElasticsearchException) {
                return true;
            }
            String className = current.getClass().getName();
            if (className.equals("org.springframework.dao.DataAccessResourceFailureException")
                    || className.equals("org.springframework.web.client.ResourceAccessException")
                    || className.startsWith("co.elastic.clients.")
                    || className.startsWith("org.elasticsearch.")
                    || className.startsWith("org.springframework.data.elasticsearch.")) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }

    private void logFallback(String beanName, Method method, Throwable throwable) {
        String key = beanName + "#" + method.getName();
        if (loggedFallbacks.add(key)) {
            LOG.log(Level.WARNING,
                    "Elasticsearch repository call failed; falling back to database path where available: {0}.{1}: {2}",
                    new Object[]{beanName, method.getName(), throwable.getMessage()});
        }
    }

    private Object fallbackValue(Method method, Object[] args) {
        Class<?> returnType = method.getReturnType();
        String methodName = method.getName();

        if (Void.TYPE.equals(returnType)) {
            return null;
        }
        if (methodName.startsWith("save") && args != null && args.length > 0 && args[0] != null) {
            if (returnType.isInstance(args[0])) {
                return args[0];
            }
            if (Iterable.class.isAssignableFrom(returnType) && args[0] instanceof Iterable<?>) {
                return args[0];
            }
        }
        if (Optional.class.isAssignableFrom(returnType)) {
            return Optional.empty();
        }
        if (SearchHits.class.isAssignableFrom(returnType)) {
            return emptySearchHits();
        }
        if (Page.class.isAssignableFrom(returnType)) {
            return emptyPage(args);
        }
        if (Collection.class.isAssignableFrom(returnType) || Iterable.class.isAssignableFrom(returnType)) {
            return Collections.emptyList();
        }
        if (Map.class.isAssignableFrom(returnType)) {
            return Collections.emptyMap();
        }
        if (Boolean.TYPE.equals(returnType)) {
            return false;
        }
        if (Long.TYPE.equals(returnType)) {
            return 0L;
        }
        if (Integer.TYPE.equals(returnType) || Short.TYPE.equals(returnType) || Byte.TYPE.equals(returnType)) {
            return 0;
        }
        if (Double.TYPE.equals(returnType)) {
            return 0D;
        }
        if (Float.TYPE.equals(returnType)) {
            return 0F;
        }
        return null;
    }

    private SearchHits<?> emptySearchHits() {
        return new SearchHitsImpl<>(
                0,
                TotalHitsRelation.EQUAL_TO,
                0F,
                Duration.ZERO,
                null,
                null,
                Collections.emptyList(),
                null,
                null,
                null
        );
    }

    private Page<?> emptyPage(Object[] args) {
        if (args != null) {
            for (Object arg : args) {
                if (arg instanceof Pageable pageable) {
                    return Page.empty(pageable);
                }
            }
        }
        return Page.empty();
    }
}
