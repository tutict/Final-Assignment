package com.tutict.finalassignmentbackend.config.db;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserMapper;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Map;

@Component
public class MetaFillHandler implements MetaObjectHandler {

    private final SysUserMapper sysUserMapper;

    public MetaFillHandler(SysUserMapper sysUserMapper) {
        this.sysUserMapper = sysUserMapper;
    }

    @Override
    public void insertFill(MetaObject metaObject) {
        LocalDateTime now = LocalDateTime.now();
        strictInsertFill(metaObject, "createdAt", LocalDateTime.class, now);
        strictInsertFill(metaObject, "updatedAt", LocalDateTime.class, now);
        fillRequestHistoryUser(metaObject);
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        strictUpdateFill(metaObject, "updatedAt", LocalDateTime.class, LocalDateTime.now());
    }

    /**
     * MyBatis-Plus emits columns annotated with {@code fill = FieldFill.INSERT} into every
     * INSERT statement, so an unfilled timestamp is persisted as NULL and the database
     * {@code DEFAULT CURRENT_TIMESTAMP} never applies.
     */
    private void fillRequestHistoryUser(MetaObject metaObject) {
        SysRequestHistory history = historyOf(metaObject);
        if (history == null || history.getUserId() != null) {
            return;
        }
        String username = history.getUsername();
        if (username == null || username.isBlank()) {
            username = currentUsername();
        }
        Long userId = findUserId(username);
        if (userId != null) {
            history.setUserId(userId);
        }
    }

    private SysRequestHistory historyOf(MetaObject metaObject) {
        Object original = metaObject.getOriginalObject();
        if (original instanceof SysRequestHistory history) {
            return history;
        }
        if (original instanceof Map<?, ?> values) {
            for (String key : new String[]{"et", "mpFillEt"}) {
                Object nested = values.get(key);
                if (nested instanceof SysRequestHistory history) {
                    return history;
                }
            }
        }
        return null;
    }

    private String currentUsername() {
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
        SysUser user = sysUserMapper.selectOne(new QueryWrapper<SysUser>()
                .eq("username", username.trim())
                .last("LIMIT 1"));
        return user == null ? null : user.getUserId();
    }
}
