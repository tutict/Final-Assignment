package com.tutict.finalassignmentbackend.config.mybatis;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserMapper;
import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.mapping.SqlCommandType;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Signature;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@Intercepts({
        @Signature(type = Executor.class, method = "update", args = {MappedStatement.class, Object.class})
})
public class RequestHistoryUserInterceptor implements Interceptor {

    private final ObjectProvider<SysUserMapper> sysUserMapper;

    public RequestHistoryUserInterceptor(ObjectProvider<SysUserMapper> sysUserMapper) {
        this.sysUserMapper = sysUserMapper;
    }

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        MappedStatement statement = (MappedStatement) invocation.getArgs()[0];
        if (statement.getSqlCommandType() == SqlCommandType.INSERT) {
            SysRequestHistory history = historyOf(invocation.getArgs()[1]);
            if (history != null && history.getUserId() == null) {
                Long userId = findUserId(usernameOf(history));
                if (userId != null) {
                    history.setUserId(userId);
                }
            }
        }
        return invocation.proceed();
    }

    private SysRequestHistory historyOf(Object parameter) {
        if (parameter instanceof SysRequestHistory history) {
            return history;
        }
        if (parameter instanceof Map<?, ?> values) {
            for (String key : new String[]{"et", "mpFillEt", "param1"}) {
                Object nested = values.get(key);
                if (nested instanceof SysRequestHistory history) {
                    return history;
                }
            }
        }
        return null;
    }

    private String usernameOf(SysRequestHistory history) {
        if (history.getUsername() != null && !history.getUsername().isBlank()) {
            return history.getUsername().trim();
        }
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        String username = authentication.getName();
        if (username == null || username.isBlank() || "anonymousUser".equals(username)) {
            return null;
        }
        return username;
    }

    private Long findUserId(String username) {
        if (username == null || username.isBlank()) {
            return null;
        }
        SysUserMapper mapper = sysUserMapper.getIfAvailable();
        if (mapper == null) {
            return null;
        }
        SysUser user = mapper.selectOne(new QueryWrapper<SysUser>()
                .eq("username", username)
                .last("LIMIT 1"));
        return user == null ? null : user.getUserId();
    }
}
