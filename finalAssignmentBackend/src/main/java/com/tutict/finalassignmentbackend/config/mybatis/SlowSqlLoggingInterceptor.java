package com.tutict.finalassignmentbackend.config.mybatis;

import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Plugin;
import org.apache.ibatis.plugin.Signature;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
@Intercepts({
        @Signature(type = Executor.class, method = "query", args = {
                MappedStatement.class,
                Object.class,
                org.apache.ibatis.session.RowBounds.class,
                org.apache.ibatis.session.ResultHandler.class
        }),
        @Signature(type = Executor.class, method = "query", args = {
                MappedStatement.class,
                Object.class,
                org.apache.ibatis.session.RowBounds.class,
                org.apache.ibatis.session.ResultHandler.class,
                org.apache.ibatis.cache.CacheKey.class,
                org.apache.ibatis.mapping.BoundSql.class
        }),
        @Signature(type = Executor.class, method = "update", args = {
                MappedStatement.class,
                Object.class
        })
})
public class SlowSqlLoggingInterceptor implements Interceptor {

    private static final Logger LOG = Logger.getLogger(SlowSqlLoggingInterceptor.class.getName());

    private final long slowQueryThresholdMs;

    public SlowSqlLoggingInterceptor(@Value("${app.mybatis.slow-query-threshold-ms:300}") long slowQueryThresholdMs) {
        this.slowQueryThresholdMs = Math.max(slowQueryThresholdMs, 1L);
    }

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        long startedAt = System.nanoTime();
        try {
            return invocation.proceed();
        } finally {
            long elapsedMs = (System.nanoTime() - startedAt) / 1_000_000L;
            if (elapsedMs >= slowQueryThresholdMs) {
                Object[] args = invocation.getArgs();
                String statementId = args.length > 0 && args[0] instanceof MappedStatement mappedStatement
                        ? mappedStatement.getId()
                        : "unknown";
                LOG.log(Level.WARNING, "Slow MyBatis statement detected: {0} took {1} ms",
                        new Object[]{statementId, elapsedMs});
            }
        }
    }

    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }

    @Override
    public void setProperties(Properties properties) {
        // No runtime properties are needed.
    }
}
