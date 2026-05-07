package com.tutict.finalassignmentbackend.rag.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("rag_chunk")
public class RagChunk implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private String id;
    @TableField("document_id")
    private String documentId;
    @TableField("chunk_no")
    private Integer chunkNo;
    @TableField("content")
    private String content;
    @TableField("content_hash")
    private String contentHash;
    @TableField("token_count")
    private Integer tokenCount;
    @TableField("char_count")
    private Integer charCount;
    @TableField("source_field")
    private String sourceField;
    @TableField("status")
    private String status;
    @TableField("embedding_model")
    private String embeddingModel;
    @TableField("embedding_hash")
    private String embeddingHash;
    @TableField("created_at")
    private LocalDateTime createdAt;
    @TableField("updated_at")
    private LocalDateTime updatedAt;
}
