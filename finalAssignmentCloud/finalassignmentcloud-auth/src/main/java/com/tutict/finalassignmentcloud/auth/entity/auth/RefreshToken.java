package com.tutict.finalassignmentcloud.auth.entity.auth;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * refresh token 持久化实体。token 列保存 ML-KEM 信封密文（~2KB），
 * lookup_digest 用于 O(1) 查找。
 */
@Data
@TableName("refresh_tokens")
public class RefreshToken {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("token")
    private String token;

    @TableField("lookup_digest")
    private String lookupDigest;

    @TableField("user_id")
    private Long userId;

    @TableField("expires_at")
    private LocalDateTime expiresAt;

    @TableField("revoked")
    private boolean revoked;

    @TableField("created_at")
    private LocalDateTime createdAt;
}