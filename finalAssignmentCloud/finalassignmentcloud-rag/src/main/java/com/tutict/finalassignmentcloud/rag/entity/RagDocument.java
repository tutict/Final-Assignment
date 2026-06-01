package com.tutict.finalassignmentcloud.rag.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("rag_document")
public class RagDocument implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId("id")
    private String id;
    @TableField("source_type")
    private String sourceType;
    @TableField("source_table")
    private String sourceTable;
    @TableField("source_id")
    private String sourceId;
    @TableField("source_version")
    private String sourceVersion;
    @TableField("title")
    private String title;
    @TableField("content_hash")
    private String contentHash;
    @TableField("status")
    private String status;
    @TableField("acl_scope")
    private String aclScope;
    @TableField("route")
    private String route;
    @TableField("metadata_json")
    private String metadataJson;
    @TableField("created_at")
    private LocalDateTime createdAt;
    @TableField("updated_at")
    private LocalDateTime updatedAt;
    @TableField("indexed_at")
    private LocalDateTime indexedAt;
}

