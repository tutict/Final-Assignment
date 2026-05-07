package com.tutict.finalassignmentbackend.rag.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("rag_embedding_task")
public class RagEmbeddingTask implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private String id;
    @TableField("chunk_id")
    private String chunkId;
    @TableField("task_key")
    private String taskKey;
    @TableField("provider")
    private String provider;
    @TableField("model")
    private String model;
    @TableField("status")
    private String status;
    @TableField("attempt_count")
    private Integer attemptCount;
    @TableField("next_retry_at")
    private LocalDateTime nextRetryAt;
    @TableField("last_error")
    private String lastError;
    @TableField("created_at")
    private LocalDateTime createdAt;
    @TableField("updated_at")
    private LocalDateTime updatedAt;
}
