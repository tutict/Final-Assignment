package com.tutict.finalassignmentbackend.entity.auth;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("refresh_tokens")
public class RefreshToken {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("token")
    private String token;

    @TableField("user_id")
    private Long userId;

    @TableField("expires_at")
    private LocalDateTime expiresAt;

    @TableField("revoked")
    private boolean revoked;

    @TableField("created_at")
    private LocalDateTime createdAt;
}
